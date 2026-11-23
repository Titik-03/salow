-- Remember motion and audio choices across launches; shader selection starts at Salow.
local utils = require 'mp.utils'
local state_path = mp.command_native({'expand-path', '~~/salow-state.json'})
local state = {mix = false, pan = false, audio = 'xfi'}
local f = io.open(state_path, 'r')
if f then
    local saved = utils.parse_json(f:read('*a'))
    f:close()
    if type(saved) == 'table' then
        if type(saved.mix) == 'boolean' then state.mix = saved.mix end
        if type(saved.pan) == 'boolean' then state.pan = saved.pan end
        if saved.audio == 'original' or saved.audio == 'atmos' or saved.audio == 'xfi' then state.audio = saved.audio end
    end
end
local function save()
    local file, err = io.open(state_path .. '.tmp', 'w')
    if file then
        local ok = file:write(utils.format_json(state))
        local closed = file:close()
        if ok and closed then
            local renamed
            renamed, err = os.rename(state_path .. '.tmp', state_path)
            if renamed then return end
        end
    end
    mp.msg.error('Could not save Salow settings: ' .. tostring(err))
    mp.osd_message('Could not save Salow settings')
end
local model, tv = 'salow.hook', true
local function shaders()
    local list = {}
    if model then
        list[1] = mp.command_native({'expand-path', '~~/shaders/' .. model})
        if tv then list[2] = mp.command_native({'expand-path', '~~/shaders/tv-dynamic.glsl'}) end
    end
    mp.set_property_native('glsl-shaders', list)
    for _, name in ipairs({'saturation', 'contrast', 'brightness', 'gamma'}) do mp.set_property_number(name, 0) end
end
mp.register_script_message('salow-model', function(value)
    if value == 'full' then model = 'salow.hook'
    elseif value == 'medium' then model = 'salow-medium.hook'
    elseif value == 'off' then model = nil
    else return end
    shaders()
    mp.osd_message(model and (value == 'full' and 'Salow' or 'Salow Medium') or 'Shaders off')
end)
mp.register_script_message('salow-look', function()
    tv = not tv
    shaders()
    mp.osd_message(tv and 'TV Dynamic (applies when shaders are on)' or 'Natural look')
end)
local function motion()
    mp.set_property_native('interpolation', state.mix)
    if state.pan then mp.command('apply-profile pan-smooth') end
end
mp.register_script_message('salow-mix', function()
    state.mix = not state.mix
    mp.set_property_native('interpolation', state.mix)
    save()
    mp.osd_message(state.mix and 'Frame mixing on' or 'Frame mixing off')
end)
mp.register_script_message('pan-smooth-toggle', function()
    state.pan = not state.pan
    if state.pan then mp.command('apply-profile pan-smooth')
    else
        mp.command('apply-profile pan-smooth restore')
        mp.command('vf remove @pansmooth')
    end
    save()
    mp.osd_message(state.pan and 'Pan smoothing on' or 'Pan smoothing off')
end)
local modes = {'original', 'atmos', 'xfi'}
local irs = {atmos = {'dolby-atmos.wav', 22}, xfi = {'xfi-crystalizer.wav', 30}}
local function audio(show)
    mp.command('no-osd af remove @fx')
    local ir = irs[state.audio]
    local message = 'Audio: ' .. state.audio
    if ir then
        local path = mp.command_native({'expand-path', '~~/irs/' .. ir[1]})
        if utils.file_info(path) then
            -- Escape both the filter-option and filtergraph parsing layers.
            path = path:gsub('([\\\':])', '\\%1'):gsub('([\\\'%,;%[%]])', '\\%1')
            local graph = 'amovie=filename=' .. path .. ',aresample=48000[ir];[in]aresample=48000[a];[a][ir]afir=gtype=gn,volume=' .. ir[2] .. 'dB,alimiter=limit=0.89:attack=3:release=60:level=disabled[out]'
            mp.commandv('af', 'add', '@fx:lavfi=[' .. graph .. ']')
        else message = message .. ' unavailable (missing impulse response); original audio' end
    end
    if show then mp.osd_message(message) end
end
mp.register_script_message('salow-audio', function()
    local index = 1
    for i, name in ipairs(modes) do if name == state.audio then index = i end end
    state.audio = modes[index % #modes + 1]
    audio(true)
    save()
end)
shaders()
motion()
-- Reapply after watch-later settings have been loaded.
mp.register_event('file-loaded', function() audio(false) end)
