# pansmooth_core.py — code for pan-smooth.vpy (anime-shader, 2026-11-21)
# Pan-only motion interpolation at 5/2 rate (23.976/24/25 -> 2.5x) before mpv's GPU shaders.
#  - Gate: motion vectors from a cheap half-resolution search decide per frame pair.
#  - Interpolated pairs use full-resolution mvtools FlowFPS (32px blocks, 16 overlap, half-pel);
#    it is only computed for pairs the gate passes (FrameEval is lazy).
#  - Every other pair reproduces mpv's tscale=oversample (hold, 50/50 blend on the straddling
#    vsync), so untouched scenes look exactly as without the filter.
#  - Catch-up bypass: after a seek mpv pushes frames from the previous keyframe as fast as it can;
#    while source frames are requested much faster than real time, the cheap hold path is used.
import collections, threading, time
import numpy as np
import vapoursynth as vs

core = vs.core

BLK, OVERLAP, PEL = 32, 16, 2      # full-res interpolation (validated: no block-edge ticks)
GBLK = 16                          # gate search block size on the half-res clip (= 32 px full res)
MIN_PX = 4                         # minimum motion, full-res px per drawn frame
SHARE = 0.4                        # pans: share of textured blocks agreeing on one vector
CATCHUP_WINDOW = 12                # source frames used to judge the request rate
CATCHUP_SPEED = 1.3                # faster than this x real time = catching up after a seek
import os as _os
_LOG = _os.environ.get('PANSMOOTH_LOG')   # debug: log bypass decisions
if _os.environ.get('PANSMOOTH_NOBYPASS'):    # tests: encode faster than real time
    CATCHUP_SPEED = 0


def oversample(src):
    num, den = src.fps.numerator * 5, src.fps.denominator * 2
    base = core.std.BlankClip(src, length=src.num_frames * 5 // 2, fpsnum=num, fpsden=den)
    blend = core.std.Merge(src, src[1:] + src[-1], 0.5)
    return core.std.FrameEval(base, lambda n: (blend if 2 * n % 5 == 4 else src)[2 * n // 5])


def finest_vectors(blob):
    # mvtools vector blob: int32 total, int32 valid, then levels coarsest->finest,
    # each an int32 byte size followed by blocks of (int32 x, int32 y, int64 sad)
    b = np.frombuffer(blob, np.int32)
    i, last = 2, None
    while i < len(b):
        n = b[i] // 4
        last = (i + 1, i + n)
        i += n
    return b[last[0]:last[1]].reshape(-1, 4)[:, :2]


class _Pace:
    """Detects catch-up: new source frames requested much faster than real time.
    Each source frame is judged once (on first request) and the decision remembered."""
    def __init__(self, fps):
        self.fps = fps
        self.t = collections.deque(maxlen=CATCHUP_WINDOW)
        self.seen = collections.OrderedDict()
        self.lock = threading.Lock()

    def catching_up(self, n):
        with self.lock:
            if n in self.seen:
                return self.seen[n]
            now = time.monotonic()
            self.t.append(now)
            if len(self.t) < CATCHUP_WINDOW:
                r = True
            else:
                r = (now - self.t[0]) * CATCHUP_SPEED < (CATCHUP_WINDOW - 1) / self.fps
            self.seen[n] = r
            if len(self.seen) > 256:
                self.seen.popitem(last=False)
            if _LOG:
                with open(_LOG, 'a') as f:
                    f.write('%.3f %d %d %.3f\n' % (now, n, r, now - self.t[0]))
            return r


def _gate(src, tex_th=3.0):
    """Per source frame i: props Pan (interpolate pair i,i+1?)."""
    half = core.resize.Bilinear(src, src.width // 2, src.height // 2)
    hsup = core.mv.Super(half, pel=1, hpad=8, vpad=8)
    hfv = core.mv.Analyse(hsup, isb=False, blksize=GBLK, overlap=0, truemotion=False)
    tex = core.resize.Bilinear(src, src.width // 4, src.height // 4, format=vs.GRAY8)
    bw, bh = half.width // GBLK, half.height // GBLK
    c = GBLK // 2                       # texture cells (quarter res) per gate block
    min_v = MIN_PX / 2                  # half-res px

    def sel(n, f):
        out = f[0].copy()
        go = False
        blob = f[2].props.get('MVTools_vectors')
        if blob is not None:
            v = finest_vectors(blob)
            if len(v) == bw * bh:
                y = np.asarray(f[1][0], dtype=np.int16)
                g = np.abs(np.diff(y, axis=1, append=y[:, -1:])) + np.abs(np.diff(y, axis=0, append=y[-1:]))
                g = g[:bh * c, :bw * c].reshape(bh, c, bw, c).mean(axis=(1, 3)).ravel()
                t = g > tex_th
                if t.sum() >= 0.05 * len(t):
                    vt = v[t]
                    key = (vt[:, 0].astype(np.int64) << 20) + vt[:, 1]
                    u, cnt = np.unique(key, return_counts=True)
                    m = int(u[np.argmax(cnt)])
                    mx = (m + (1 << 19)) >> 20
                    my = m - (mx << 20)
                    near = (np.abs(vt[:, 0] - mx) <= 1) & (np.abs(vt[:, 1] - my) <= 1)
                    go = (mx * mx + my * my) ** .5 >= min_v and near.mean() >= SHARE
        cut = f[3].props['PlaneStatsDiff'] > CUT
        out.props['Pan'] = int(go and not cut)
        out.props['Cut'] = int(cut)
        return out

    nxt = core.std.PlaneStats(tex, tex[1:] + tex[-1])   # frame i: diff(i, i+1)
    analysed = core.std.ModifyFrame(src, [src, tex, hfv[1:] + hfv[-1], nxt], sel)
    skip = core.std.SetFrameProps(src, Pan=0, Bypass=1)
    if CATCHUP_SPEED <= 0:          # offline tests: never bypass
        return analysed
    pace = _Pace(src.fps.numerator / src.fps.denominator)
    # the decision is made when a source frame is first requested; VapourSynth caches it
    return core.std.FrameEval(src, lambda n: skip if pace.catching_up(n) else analysed)


def smooth(src, ana=None):
    # ana: branch used for all analysis (see run(): it is guarded during script loading);
    # the shown hold path reads the source directly.
    ana = src if ana is None else ana
    num, den = src.fps.numerator * 5, src.fps.denominator * 2
    sup = core.mv.Super(ana, pel=PEL, hpad=16, vpad=16)
    kw = dict(blksize=BLK, overlap=OVERLAP, truemotion=False)
    bv = core.mv.Analyse(sup, isb=True, **kw)
    fv = core.mv.Analyse(sup, isb=False, **kw)
    flow = core.mv.FlowFPS(ana, sup, bv, fv, num=num, den=den)
    hold = oversample(src)
    g = _gate(ana)
    g60 = core.std.FrameEval(hold, lambda n: g[2 * n // 5])
    out = core.std.FrameEval(hold, lambda n, f: flow if (2 * n % 5 and f.props['Pan']) else hold, prop_src=g60)
    # mpv times frames by their _Duration props: every output frame lasts one output period
    return core.std.SetFrameProps(out, _DurationNum=den, _DurationDen=num)


CUT = 60e-3      # quarter-res mean abs diff above this = scene cut, never interpolate


def run(video_in, container_fps):
    fps = float(container_fps or 0)
    rate = next((r for r in ((24000, 1001), (24, 1), (25, 1)) if abs(fps - r[0] / r[1]) < 0.01), None)
    if not rate:
        return video_in
    # mvtools reads frame 0 while the graph is built. Serve those reads from a blank clip so
    # mpv never returns its black dummy frames (they would be cached and shown after a seek).
    loading = [True]
    blank = core.std.BlankClip(video_in)
    guarded = core.std.FrameEval(video_in, lambda n: blank if loading[0] else video_in)
    fps = lambda c: core.std.AssumeFPS(c, fpsnum=rate[0], fpsden=rate[1])
    out = smooth(fps(video_in), ana=fps(guarded))
    loading[0] = False
    return out
