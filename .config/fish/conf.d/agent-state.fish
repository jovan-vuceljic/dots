# Mark the tmux window when a long shell command finishes, through the same
# ~/.config/tmux/scripts/agent-state.sh the coding agents use (tool tag "sh"):
# ✓ on exit 0, ! on failure — coloured when it happened while you were elsewhere, grey once
# visited, gone at the next command. Only commands longer than $agent_state_min_ms
# (default 30 s) count, and interactive programs are skipped: the agents mark themselves,
# and quitting a long nvim or lazygit session is not news. No-op outside tmux.
set -q agent_state_min_ms; or set -g agent_state_min_ms 30000

function __agent_state_preexec --on-event fish_preexec
    set -q TMUX_PANE; or return
    ~/.config/tmux/scripts/agent-state.sh sh busy
end

function __agent_state_postexec --on-event fish_postexec
    set -l st $status # first statement: anything before it would clobber the command's status
    set -q TMUX_PANE; or return
    test "$CMD_DURATION" -gt "$agent_state_min_ms"; or return
    switch (string split -m1 ' ' -- $argv[1])[1]
        case nvim vim vi less man lazygit ssh mosh tmux claude claudes pi opencode opencodes codex aichat htop btop top journalctl tail watch
            return
    end
    if test $st -eq 0
        ~/.config/tmux/scripts/agent-state.sh sh done
    else
        ~/.config/tmux/scripts/agent-state.sh sh error
    end
end
