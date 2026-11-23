-- Touchscreen gestures: double-tap the left third = back 10 s, right third = forward 10 s, middle = play/pause.
local function dbl()
    local pos, dim = mp.get_property_native('mouse-pos'), mp.get_property_native('osd-dimensions')
    if not pos or not dim or dim.w == 0 then return end
    local f = pos.x / dim.w
    if f < 1/3 then mp.commandv('seek', '-10'); mp.osd_message('⏪ 10 s', 1)
    elseif f > 2/3 then mp.commandv('seek', '10'); mp.osd_message('10 s ⏩', 1)
    else mp.command('cycle pause') end
end
mp.add_key_binding('MBTN_LEFT_DBL', 'touch-double-tap', dbl)
