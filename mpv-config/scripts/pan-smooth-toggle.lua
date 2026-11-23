-- pan-smooth-toggle.lua (anime-shader, 2026-11-22)
-- Pan smoothing is off by default at mpv launch.
-- Alt+2 (input.conf: script-message pan-smooth-toggle) turns it off/on.
-- On = profile [pan-smooth] in mpv.conf. Off restores the profile's settings and also removes
-- the filter if it got there some other way.
local function is_on()
    for _, f in ipairs(mp.get_property_native("vf") or {}) do
        if f.label == "pansmooth" then return true end
    end
    return false
end

mp.register_script_message("pan-smooth-toggle", function()
    if is_on() then
        mp.command("apply-profile pan-smooth restore")
        mp.command("vf remove @pansmooth")
        mp.osd_message("Motion: pan smoothing off")
    else
        mp.command("apply-profile pan-smooth")
        mp.osd_message("Motion: pan smoothing ON (camera pans to 60 fps; more GPU/CPU)")
    end
end)

