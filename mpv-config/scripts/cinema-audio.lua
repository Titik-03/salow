-- Alt+a cycles audio modes: Off (native) -> Cinema -> Dolby Atmos -> X-Fi -> Razor Surround.
-- IR modes convolve with captured impulse responses (~/.config/mpv/irs, copied from EasyEffects irs).
-- Gains bring each mode to ~-19 LUFS (native ~-22.5); a limiter keeps peaks under -1 dBFS.
local lim = "alimiter=limit=0.89:attack=3:release=60:level=disabled"

local function ir(file, gain)
    local path = mp.command_native({"expand-path", "~~/irs/" .. file})
    return "amovie=" .. path .. ",aresample=48000[ir];[in]aresample=48000[a];" ..
           "[a][ir]afir=gtype=gn,volume=" .. gain .. "dB," .. lim .. "[out]"
end

local modes = {
    { name = "Off (native)" },
    { name = "Cinema (subtle)", graph = "volume=-3dB,crossfeed=strength=0.3:range=0.5,bass=g=2.5:f=100:w=0.7,aexciter=amount=0.6:drive=4:freq=7500:ceil=16000,acompressor=threshold=-18dB:ratio=2:attack=20:release=250:makeup=1.5," .. lim },
    { name = "Dolby Atmos", ir = {"dolby-atmos.wav", 22} },
    { name = "X-Fi Crystalizer", ir = {"xfi-crystalizer.wav", 30} },
    { name = "Razor Surround (+bass)", ir = {"razor-surround.wav", 19} },
}
local utils = require "mp.utils"
for i = #modes, 1, -1 do
    if modes[i].ir and not utils.file_info(mp.command_native({"expand-path", "~~/irs/" .. modes[i].ir[1]})) then
        table.remove(modes, i)
    end
end
local idx = 1
for i, mode in ipairs(modes) do
    if mode.name == "X-Fi Crystalizer" then idx = i end
end

local function apply(show)
    local m = modes[idx]
    mp.command("no-osd af remove @fx")
    local g = m.graph or (m.ir and ir(m.ir[1], m.ir[2]))
    if g then mp.commandv("af", "add", "@fx:lavfi=[" .. g .. "]") end
    if show then mp.osd_message("Audio: " .. m.name) end
end

apply(false)
mp.add_key_binding(nil, "cinema-audio-toggle", function()
    idx = idx % #modes + 1
    apply(true)
end)
