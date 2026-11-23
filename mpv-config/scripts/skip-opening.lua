-- Tab: jump forward 85 s = 1:25, the opening/ending length. Shift+Tab: jump back 85 s.
mp.add_key_binding('TAB', 'skip-op', function() mp.commandv('seek', '85', 'relative+exact'); mp.osd_message('Skipped 1:25  (Shift+Tab to go back)', 2) end)
mp.add_key_binding('Shift+TAB', 'skip-op-back', function() mp.commandv('seek', '-85', 'relative+exact'); mp.osd_message('Back 1:25', 2) end)
