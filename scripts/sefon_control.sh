#!/usr/bin/env fish

set SOCKET /tmp/mpv-sefon-socket
set PLAYLIST "$HOME/Documents/config/numetal_sefon.m3u"

# Check if MPV is running using the socket argument
set PID (pgrep -f "mpv .*$SOCKET")

function send_cmd
    # Use netcat to send JSON commands to the socket
    # -U: Unix socket
    # -w 1: Timeout 1 sec
    echo "$argv[1]" | nc -U -w 1 $SOCKET > /dev/null 2>&1
end

function control_mpv
    switch $argv[1]
        case play
            if test -z "$PID"
                # Wait for socket
                for i in (seq 1 50)
                    if test -e $SOCKET
                        break
                    end
                    sleep 0.1
                end
                if not pgrep -f "mpv .*$SOCKET" > /dev/null
                    notify-send "Sefon Error" "Failed to start mpv. Check /tmp/mpv-sefon.log"
                end
            else
                # Resume playback
                send_cmd '{ "command": ["set_property", "pause", false] }'
            end
        case pause
            if test -n "$PID"
                # Toggle pause
                send_cmd '{ "command": ["cycle", "pause"] }'
            end
        case stop
            if test -n "$PID"
                # Quit mpv
                send_cmd '{ "command": ["quit"] }'
            end
        case menu
            # Get current playlist index (0-based) if playing
            set current_idx -1
            if test -n "$PID"
                set response (echo '{ "command": ["get_property", "playlist-pos"] }' | nc -U -w 1 $SOCKET 2>/dev/null)
                if test -n "$response"
                    set current_idx (echo $response | jq -r .data)
                end
            end

            # 1-based index for awk
            set awk_idx (math "$current_idx" + 1)

            # Generate list with markers using awk
            # Format: "Index: [Marker] Title"
            set tracks (grep "^#EXTINF" $PLAYLIST | cut -d, -f2- | awk -v cur="$awk_idx" '{ if (NR == cur) printf "%d: ▶ %s\n", NR, $0; else printf "%d:   %s\n", NR, $0; }')

            # Determine header
            if test "$current_idx" != "-1" -a "$current_idx" != "null"
                # Extract title from tracks list using grep
                set current_line (echo "$tracks" | grep "^$awk_idx:")
                # Remove prefix "N: ▶ "
                set current_title (echo "$current_line" | cut -d "▶" -f2 | string trim)
                set header "Playing: $current_title"
            else
                set header "Select track to play"
            end

            # Show menu
            set selection (string join \n $tracks | fzf --reverse --header="$header | Enter: Play, Esc: Quit" --prompt="> ")

            if test -n "$selection"
                # Extract index from start of line "12: ..."
                set index (echo "$selection" | cut -d: -f1)
                set index (math $index - 1)

                # Kill previous instance if running
                if test -n "$PID"
                    send_cmd '{ "command": ["quit"] }'
                    sleep 0.5
                end

                # Start new instance detached
                setsid -f mpv --no-video --pause=no --input-ipc-server=$SOCKET --playlist=$PLAYLIST --playlist-start=$index < /dev/null > /tmp/mpv-sefon.log 2>&1

                # Wait for socket
                for i in (seq 1 50)
                    if test -e $SOCKET
                        break
                    end
                    sleep 0.1
                end
                if not pgrep -f "mpv .*$SOCKET" > /dev/null
                    notify-send "Sefon Error" "Failed to start mpv. Check /tmp/mpv-sefon.log"
                end
                exit 0
            end
        case update
            notify-send "Sefon" "Обновление плейлиста..."
            systemctl --user start sefon-update.service
    end
end

if test (count $argv) -gt 0
    control_mpv $argv[1]
else
    # Launch in kitty if no args provided (menu mode)
    # Check if we are already inside kitty running this script
    # To prevent infinite loop if TERM is set but args are missing (should not happen with waybar call)
    kitty --class "sefon-menu" --title "Sefon Player" fish -c "$HOME/Documents/config/scripts/sefon_control.sh menu"
end
