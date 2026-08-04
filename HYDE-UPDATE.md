# HyDE on wm — is it out of date, do I update it, can it be reverted?

Full background for the `migrate-new-dots` test. Short version lives at the end of
`MIGRATION-TEST.md`; this is the detail.

## Key fact: wm already runs HyDE (it's just older than lw)

"Out of date" here means **older version**, not missing. The *old* dots-wm config already
depends on HyDE — on `main`:

```
git show main:.config/hypr/hyprland.conf   # line 31:
source = ~/.local/share/hyde/hyprland.conf
```

That HyDE-generated file (which defines `$mainMod` and other framework vars, and is **not**
tracked by dots) is what makes Hyprland start at all. Since wm boots today, that file
already exists on wm. The **new** `.dots` config sources the *same* file — so the hard HyDE
dependency it needs is **already satisfied**.

(Per `~/.dots/README.md` "HyDE dependency": without HyDE a GUI host dies with
`source globbing error` + `invalid mod $mainMod`. That's already handled on wm.)

## Q1 — should I update HyDE too?

**No, not as a prerequisite.** The HyDE update and the dots migration are **decoupled** — do
them one at a time so a single change is easy to attribute.

- Test the `migrate-new-dots` branch on wm's **current** HyDE first. It should boot, because
  the framework file it sources is already present.
- The visible bar on wm is the **standalone cava rig** (`layouts/custom.jsonc`, launched raw
  via `waybar -c …custom.jsonc -s …custom.css`) — it is **not** HyDE-managed, so it does not
  ride on HyDE's `waybar.py` version.
- Low-risk version caveat: HyDE's version affects `waybar.py`'s generated `config.jsonc` and
  the header/footer module fragments (`~/.dots/ToDo.md` notes upstream deprecated them; our
  `modules/footer.jsonc` still works with the current generator). Doesn't affect the raw rig.

**Recommendation:** migrate the dots first, verify, *then* optionally update HyDE to bring wm
in line with lw — or only if a HyDE-version-specific issue actually shows up.

## Q2 — can a HyDE update be reverted?

**Only partially.** It is not cleanly, fully reversible on these machines.

What a HyDE update does (`~/HyDE/Scripts/install.sh -r`):
- overwrites `~/.config/hypr/*` (everything in `Scripts/restore_cfg.psv`),
- **replaces your stow symlinks with real files** (HyDE's new defaults),
- backs the old configs up to `~/.config/cfg_backups`,
- **installs/upgrades packages**.

Recoverable:
- **Config layer** — dots are git-tracked; `~/.dots/bin/reconcile-hyde.sh --relink` re-stows
  the repo versions (backing up severed files to a timestamped dir), and `~/.config/cfg_backups`
  holds HyDE's pre-update copies.

**Not** auto-recoverable:
- **Packages** installed/upgraded by the update,
- HyDE's **generated state** — `~/.local/share/hyde/*`, `hyde/themes/`, wallpapers — untracked
  and overwritten in place.
- There are **no system snapshots** on these machines (no timeshift, no btrfs `/.snapshots`),
  so there is no whole-system rollback.

**A real undo therefore requires a manual backup taken beforehand** (see below).

## Optional — align wm's HyDE with lw (only after the dots test passes)

1. **Back up first** (this is your only real revert path):
   ```fish
   tar czf ~/hyde-pre-update-(date +%F).tgz -C ~ .local/share/hyde .config/hypr .config/waybar
   pacman -Qe > ~/pkgs-pre-update.txt
   ```
   (Optionally set up timeshift or a btrfs snapshot if you want true rollback.)
2. **Update HyDE** with its own installer (clone HyDE first if `~/HyDE` is absent):
   ```fish
   ~/HyDE/Scripts/install.sh        # -r restore mode overwrites ~/.config/hypr/*
   ```
3. **Reconcile the dots** (HyDE just severed the stow symlinks):
   ```fish
   cd ~/.dots
   git commit -am wip               # so reconcile choices are reviewable
   ./bin/reconcile-hyde.sh wm       # report only (safe)
   ./bin/reconcile-hyde.sh -i wm    # interactive: keep/take/merge each file
   #   or: ./bin/reconcile-hyde.sh --relink wm   # repo versions win, re-stow
   ```
4. **One-time bar disable** (same as lw — the gui exec-once launches the custom rig):
   ```fish
   systemctl --user stop hyde-(echo $XDG_SESSION_DESKTOP)-bar.service
   systemctl --user mask hyde-(echo $XDG_SESSION_DESKTOP)-bar.service
   ```
5. **Verify:** `hyprctl configerrors` clean, and `git -C ~/.dots status` reviewed after
   reconcile.

### Reverting that HyDE update
Partial only: `./bin/reconcile-hyde.sh --relink wm` + `git restore` bring back the config
layer; `~/.config/cfg_backups` holds HyDE's copies. Packages and `~/.local/share/hyde/*` are
**not** auto-reverted — restore those from the `hyde-pre-update-*.tgz` tarball from step 1.
