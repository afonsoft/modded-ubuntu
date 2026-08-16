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

6. Run lint:
   ```bash
   bash -n setup.sh distro/user.sh distro/gui.sh
   shellcheck -S warning setup.sh distro/user.sh distro/gui.sh
   ```

## Devin secrets needed

None.
