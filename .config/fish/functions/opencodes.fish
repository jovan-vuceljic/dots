function opencodes --description 'contained opencode' 
  bwrap \
    --unshare-all \
    --new-session \
    --clearenv \
    --die-with-parent \
    --share-net \
    --dev /dev \
    --proc /proc \
    --ro-bind /usr /usr \
    --ro-bind /lib /lib \
    --ro-bind /lib64 /lib64 \
    --ro-bind /bin /bin \
    --ro-bind /etc /etc \
    --ro-bind ~/.config/opencode ~/.config/opencode \
    --tmpfs /tmp/node-compile-cache \
    --bind ~/.local/state/opencode ~/.local/state/opencode \
    --bind ~/.local/share/opencode ~/.local/share/opencode \
    --bind "$(pwd)" "$(pwd)" \
  opencode
end



