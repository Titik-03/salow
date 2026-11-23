-- Reproduce mpv builds returning a trailing nil from format_json.
local scratch = os.tmpname()
os.remove(scratch)
local hook
package.preload['mp.msg'] = function() return {error=function(e) error(e) end} end
package.preload['mp.utils'] = function() return {
    parse_json=function() return {} end,
    format_json=function() return '{"saved":true}', nil end,
    join_path=function(a,b) return a .. '/' .. b end,
    split_path=function() return '/videos/', 'episode.mp4' end,
} end
mp = {
    command_native=function() return scratch end,
    get_property=function(n) return ({path='episode.mp4', ['working-directory']='/videos'})[n] end,
    get_property_number=function(n) return ({['time-pos']=45,duration=1000})[n] end,
    get_property_native=function() return false end,
    command=function() end,
    add_hook=function(_,_,f) hook=f end,
    add_periodic_timer=function() end,
    register_event=function() end,
}
dofile('mpv-config/scripts/resume-everywhere.lua')
hook()
local f=assert(io.open(scratch,'r'))
assert(f:read('*a')=='{"saved":true}')
f:close()
os.remove(scratch)
print('Resume JSON trailing-nil regression passed')
