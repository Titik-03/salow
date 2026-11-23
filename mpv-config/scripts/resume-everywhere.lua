-- Remember where you stopped, per episode and per show:
--  * the position is saved when you leave an episode (next/previous, playlist, autoplay), every 30 s while playing, and on quit;
--  * an episode left within its last 90 s (the ending) counts as finished and starts from the beginning next time;
--  * continue watching: opening any episode of a show jumps to the episode you were last watching in that folder,
--    at its saved position. Press Backspace within 15 s to go back to the episode you opened instead.
local utils = require 'mp.utils'
local msg = require 'mp.msg'
local FINISHED_TAIL = 90
local state_path = mp.command_native({'expand-path', '~~state/continue-watching.json'})

local function load_state()
    local f = io.open(state_path, 'r'); if not f then return {} end
    local t = utils.parse_json(f:read('*a') or '') or {}; f:close(); return t
end
local function store_state(t)
    local json, err = utils.format_json(t)
    if not json then msg.error('Could not encode resume state: ' .. tostring(err)); return end
    local f
    local ok
    ok, err = pcall(function()
        f = assert(io.open(state_path .. '.tmp', 'w'))
        assert(f:write(json))
        assert(f:close())
        f = nil
        assert(os.rename(state_path .. '.tmp', state_path))
    end)
    if f then pcall(function() f:close() end) end
    if not ok then msg.error('Could not save resume state: ' .. tostring(err)) end
end
local function folder_of(path) return (utils.split_path(path)) end

local function finished()
    local pos, dur = mp.get_property_number('time-pos'), mp.get_property_number('duration')
    return mp.get_property_native('eof-reached') or (pos and dur and dur > 300 and pos > dur - FINISHED_TAIL)
end
local suppress = false  -- true while jumping away from the opened episode, so it doesn't overwrite the saved spot
local function save()
    if suppress then return end
    local path = mp.get_property('path')
    if not path or not mp.get_property_number('time-pos') or path:find('://') then return end
    local full = utils.join_path(mp.get_property('working-directory'), path)
    local st = load_state()
    if finished() then
        mp.command('delete-watch-later-config')
    else
        mp.command('write-watch-later-config')
        st[folder_of(full)] = {file = full, time = mp.get_property_number('time-pos')}
        store_state(st)
    end
end
mp.add_hook('on_unload', 50, save)
mp.add_periodic_timer(30, function() if not mp.get_property_native('pause') then save() end end)

-- continue watching, once per mpv start
local checked, back_index = false, nil
mp.register_event('file-loaded', function()
    suppress = false
    if checked then return end
    checked = true
    local path = mp.get_property('path'); if not path or path:find('://') then return end
    local full = utils.join_path(mp.get_property('working-directory'), path)
    local last = load_state()[folder_of(full)]
    if not last or last.file == full then return end
    -- autoload builds the playlist right after the first file loads; give it a moment
    mp.add_timeout(0.3, function()
        local n = mp.get_property_number('playlist-count', 0)
        for i = 0, n - 1 do
            local f = mp.get_property('playlist/' .. i .. '/filename')
            if f and utils.join_path(mp.get_property('working-directory'), f) == last.file then
                back_index = mp.get_property_number('playlist-pos')
                -- mpv consumes a saved spot when it opens a file; put the opened episode's spot back before leaving it
                mp.command('write-watch-later-config')
                suppress = true
                mp.set_property_number('playlist-pos', i)
                local name = last.file:match('([^/]+)$'):gsub('%.%w+$', '')
                mp.osd_message(string.format('Continuing: %s at %d:%02d\nBackspace = go back to the episode you opened',
                    name, math.floor(last.time / 60), math.floor(last.time % 60)), 6)
                mp.add_forced_key_binding('BS', 'continue-undo', function()
                    mp.remove_key_binding('continue-undo')
                    if back_index then mp.set_property_number('playlist-pos', back_index); back_index = nil end
                end)
                mp.add_timeout(15, function() mp.remove_key_binding('continue-undo') end)
                return
            end
        end
    end)
end)
