-- Run from the repository: lua tests/test_controls.lua
local scratch = os.tmpname()
os.remove(scratch)
local messages, events, props, commands
local save_errors = 0
local pan_available = true
package.preload['mp.msg'] = function() return {error=function() save_errors=save_errors+1 end} end
package.preload['mp.utils'] = function()
    return {
        file_info = function() return {} end,
        format_json = function(s) return ('%s %s %s'):format(tostring(s.mix), tostring(s.pan), s.audio) end,
        parse_json = function(s)
            local mix, pan, audio = s:match('(%w+) (%w+) (%w+)')
            return {mix=mix=='true', pan=pan=='true', audio=audio}
        end,
    }
end
local function start()
    messages, events, props, commands = {}, {}, {}, {}
    mp = {
        command_native = function(a) return a[2]=='~~/salow-state.json' and scratch or a[2] end,
        register_script_message = function(n,f) messages[n]=f end,
        register_event = function(n,f) events[n]=f end,
        set_property_native = function(n,v) props[n]=v end,
        set_property_number = function(n,v) props[n]=v end,
        set_property = function(n,v) props[n]=v end,
        get_property = function(n,d) return props[n] or d end,
        command = function(c) commands[#commands+1]=c end,
        commandv = function(...)
            local args={...}
            commands[#commands+1]=table.concat(args,' ')
            if args[1]=='vf' and not pan_available then return nil, 'filter unavailable' end
            return true
        end,
        osd_message = function() end,
        msg = {error=function(e) error(e) end},
    }
    dofile('mpv-config/scripts/salow-controls.lua')
    events['file-loaded']()
end
start()
assert(not props.interpolation)
assert(commands[#commands]:find('xfi%-crystalizer'))
messages['salow-model']('medium')
assert(props['glsl-shaders'][1]:find('medium'))
messages['salow-look']()
assert(#props['glsl-shaders']==1)
messages['salow-model']('off')
assert(#props['glsl-shaders']==0)
messages['salow-mix']()
messages['pan-smooth-toggle']()
messages['salow-audio']() -- X-Fi -> Original
start()
assert(props.interpolation)
assert(commands[1]:find('vf add @pansmooth'))
assert(commands[#commands]=='no-osd af remove @fx')
assert(props['glsl-shaders'][1]:find('salow.hook'))
messages['salow-mix']()
messages['pan-smooth-toggle']()
messages['salow-audio']() -- Original -> Atmos
start()
assert(not props.interpolation)
assert(not commands[1]:find('vf add @pansmooth'))
assert(commands[#commands]:find('dolby%-atmos'))
pan_available = false
messages['pan-smooth-toggle']()
messages['salow-model']('medium')
assert(props['glsl-shaders'][1]:find('medium'))
assert(props.hwdec == 'auto')
pan_available = true
save_errors = 0
-- A serialization error must not kill any registered controls.
local utils = require 'mp.utils'
utils.format_json = function() return nil, 'encoding failed' end
messages['salow-mix']()
messages['salow-audio']()
messages['pan-smooth-toggle']()
assert(save_errors == 3)
messages['salow-model']('medium')
assert(props['glsl-shaders'][1]:find('medium'))
-- An exception from the I/O layer must also leave the script alive.
utils.format_json = function() error('encoding exception') end
messages['salow-mix']()
assert(save_errors == 4)
messages['salow-model']('off')
assert(#props['glsl-shaders']==0)
os.remove(scratch)
print('Controls, persistence and save-failure checks passed')
