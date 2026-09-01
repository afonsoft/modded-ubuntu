---
name: testing-modded-ubuntu
description: End-to-end testing of afonsoft/modded-ubuntu inside the termux/termux-docker container.
---

# Testing modded-ubuntu in Termux Docker

Use this skill when asked to validate changes to `setup.sh`, `distro/user.sh`, `distro/gui.sh` or other scripts in `afonsoft/modded-ubuntu`.

## Environment

- Image: `termux/termux-docker:latest`
- Local repo checkout should be bind-mounted to `/data/data/com.termux/files/home/modded-ubuntu`.
- Use a dedicated host volume (e.g., `/tmp/modded-ubuntu-test:/termux-logs`) to collect logs across steps.
- Docker daemon must be running.

## Critical setup notes

1. Run commands inside the container as the `system` user, **not** root. `pkg` refuses to run as root:
   ```bash
   docker exec -u system -t <container> ...
   ```

2. `proot-distro` stores the Ubuntu rootfs under `${PREFIX}/var/lib/proot-distro/containers/ubuntu/rootfs` (not `installed-rootfs`) in the Docker image.

3. Environment variables are **not** propagated through `proot-distro login ubuntu -- bash -c '...'`. To pass values like `MODDED_USER`/`MODDED_PASS`, write a small wrapper script inside the rootfs and execute it:
   ```bash
   cat > /data/data/com.termux/files/usr/var/lib/proot-distro/containers/ubuntu/rootfs/root/run-user.sh <<'EOF'
   export MODDED_USER=test
   export MODDED_PASS=test123
   bash /root/user.sh
   EOF
   chmod +x /data/data/com.termux/files/usr/.../rootfs/root/run-user.sh
   proot-distro login ubuntu -- bash /root/run-user.sh
   ```

4. Do not rely on `/tmp` inside `proot-distro login` to persist across `docker exec` calls. Use the mounted host logs directory for artifacts you need to inspect later.

5. The wrapper under test is `${PREFIX}/bin/ubuntu` (`/data/data/com.termux/files/usr/bin/ubuntu`).

## Typical validation flow

1. Install dependencies and run `setup.sh`:
   ```bash
   pkg update -y
   pkg install -y pulseaudio proot-distro termux-am
   bash ./setup.sh
   ```

2. Verify the generated wrapper:
   - `head -n1` should be `#!/data/data/com.termux/files/usr/bin/env bash`
   - Contains `bash ~/.sound 2>/dev/null || true`
   - Contains `exec proot-distro login --no-sysvipc ubuntu`
   - No `--user ` flag yet
   - `bash -n` passes
   - `timeout 20 /data/data/com.termux/files/usr/bin/ubuntu` does **not** emit `line 2: -sysvipc: command not found`

3. Run `user.sh` inside the rootfs and verify the per-user wrapper:
   - Contains `exec proot-distro login --user test --no-sysvipc ubuntu --bind ... --shared-tmp --fix-low-ports`
   - Still contains shebang and sound line

4. Re-run `setup.sh` and confirm an existing user wrapper is preserved (the `--user test` line must remain).

5. Exercise `sound_fix()` from `distro/gui.sh`:
   - Extract only `sound_fix()` with `sed -n '/^sound_fix() {/,/^}/p'`
   - Source it and call `sound_fix`
   - Confirm `bash ~/.sound` is added via `mktemp` (not in-place redirect) and the `exec proot-distro` line is not corrupted

6. Run lint (mirror the CI configuration):
   ```bash
   bash -n setup.sh distro/user.sh distro/gui.sh
   # .github/workflows/shellcheck.yml ignores distro/proot-distro.sh (vendored upstream file
   # that has pre-existing SC2239/SC2046/SC1090 findings). Exclude it or you will get false failures:
   shellcheck -S warning setup.sh remove.sh $(ls distro/*.sh | grep -v proot-distro.sh) \
       distro/vncstart distro/vncstop distro/vncstart-fhd distro/vncstart-qhd
   xmllint --noout distro/xfce-config/xfconf/*.xml   # needs libxml2-utils
   ```

## Testing the GUI / VNC session (appearance, XFCE, browsers)

To actually *see* the desktop instead of only asserting on files:

1. Publish the VNC port when creating the container. The Devin box itself already uses host
   port 5901 for its own display, so map a different host port:
   ```bash
   docker run -d --name mu-test -p 5911:5901 \
     -v "$PWD:/data/data/com.termux/files/home/modded-ubuntu" \
     -v /tmp/modded-ubuntu-test:/termux-logs termux/termux-docker:latest sleep infinity
   ```
2. A full `gui.sh` run is slow. To provision only what a desktop needs, install the `packs`
   array from `distro/gui.sh` package-by-package inside the rootfs (this also proves every
   package name still resolves on the target Ubuntu release):
   ```bash
   for p in "${packs[@]}"; do apt-get install -y --no-install-recommends "$p" || echo "FAILED: $p"; done
   ```
3. `vncstart` must run as the created user: `proot-distro login --user test --no-sysvipc ubuntu
   --shared-tmp --fix-low-ports -- bash /home/test/script.sh`. With no TTY it auto-creates the
   default password `modded`.
4. **Xvnc log location**: TigerVNC on recent Ubuntu writes to
   `~/.config/tigervnc/<host>:1.log`, *not* `~/.vnc/*.log`. Check it for
   `Listening for VNC connections on all interface(s), port 5901` and for
   `Bad command line option` / `unrecognized` when validating new `vncserver` arguments.
5. `ps -ef | grep Xtigervnc` is the reliable way to confirm which arguments the TigerVNC
   perl wrapper actually forwarded (e.g. `-dpi 96`, `-AlwaysShared=1`,
   `-AcceptSetDesktopSize=1`, `-localhost=0`, `-ZlibLevel 0`).
6. When the `proot-distro login` session exits, its children become zombies and the desktop
   dies. Keep the session alive with a backgrounded exec that ends in `sleep`:
   ```bash
   docker exec -d -u system mu-test bash -lc \
     "proot-distro login --user test --no-sysvipc ubuntu --shared-tmp --fix-low-ports -- \
      bash -c 'vncstart; sleep 3000'"
   ```
7. Connect from the host GUI (install `tigervnc-viewer` if missing):
   `DISPLAY=:0 vncviewer 127.0.0.1:5911`, type the password, then maximize with
   `DISPLAY=:0 wmctrl -r "modded-ubuntu - TigerVNC" -b add,maximized_vert,maximized_horz`.
8. Useful in-session assertions (run in the XFCE terminal so they appear on the recording):
   `xdpyinfo | grep resolution`, `xrdb -query | grep dpi`,
   `xfconf-query -c xsettings -p /Xft/DPI`, `xfconf-query -c xfwm4 -p /general/use_compositing`,
   `xset q | grep -A2 'Screen Saver'`. Note `xfconf-query` needs `DISPLAY` set, otherwise it
   fails with "Cannot autolaunch D-Bus without X11 $DISPLAY".
9. Expect these harmless PRoot warnings in the Xvnc log; they are not failures:
   `Failed to get a systemd proxy`, `Failed to get system bus`,
   `pm-is-supported ... No such file or directory`, `Glycin running without sandbox`,
   `Xlib: extension "DPMS" missing` / `server does not have extension for -dpms option`.

## Testing APT/PPA helpers (e.g. `setup_xtradeb.sh`, `chromium.sh`)

- Record `md5sum /etc/apt/sources.list` before and after: helper scripts must never append to it.
- After adding a repo, run `apt-get update` verbosely and check that pre-existing
  `archive.ubuntu.com` entries still appear in `apt-cache policy` (no `NO_PUBKEY` / `is not signed`).
- Verify the imported key fingerprint with
  `gpg --show-keys --with-colons /etc/apt/keyrings/<name>.gpg | grep ^fpr`.
- Run the helper twice and compare `stat -c %s` of the generated `.sources` file to prove idempotency.
- The container is `amd64` and Ubuntu `resolute` (26.04); the XtraDeb PPA does publish
  `resolute/main amd64`, so the "package unavailable" fallback branch of `chromium.sh` is
  normally *not* exercised there. If you need to test that branch, temporarily point the
  script at a non-existent suite instead of assuming it works.

## Devin secrets needed

None.
