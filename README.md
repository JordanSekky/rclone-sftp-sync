# rclone-sftp-sync

Continuously syncs a remote rclone source to a local destination on a configurable interval. After each sync completes, a dry-run check detects whether files changed on the source during the transfer -- if so, the sync re-runs immediately instead of waiting for the next interval.

## Quick Start (Docker)

```bash
docker run --rm \
  -e RCLONE_REMOTE="myremote" \
  -e RCLONE_REMOTE_PATH="path/to/source/" \
  -e RCLONE_LOCAL_PATH="/data/" \
  -v /mnt/data/destination:/data \
  -v ~/.config/rclone:/config/rclone:ro \
  ghcr.io/jordansekky/rclone-sftp-sync:main
```

## Running Directly

Prerequisites:
- [rclone](https://rclone.org/downloads/) installed and available on `PATH`
- An rclone remote already configured (`rclone config`)

```bash
export RCLONE_REMOTE="myremote"
export RCLONE_REMOTE_PATH="path/to/source/"
export RCLONE_LOCAL_PATH="/mnt/data/destination/"

./rclone_sync.sh
```

Press `Ctrl+C` to stop.

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `RCLONE_REMOTE` | Yes | -- | Name of the rclone remote (e.g. `dest`) |
| `RCLONE_REMOTE_PATH` | Yes | -- | Path on the remote (e.g. `downloads/jordan-downloads/`) |
| `RCLONE_LOCAL_PATH` | Yes | -- | Local destination path (e.g. `/mnt/plex_library/downloads/`) |
| `SLEEP_TIME` | No | `300` | Seconds to wait between sync cycles |
| `RCLONE_EXTRA_FLAGS` | No | -- | Additional flags passed to every rclone invocation |

## How It Works

1. **Sync** -- runs `rclone sync` from `RCLONE_REMOTE:RCLONE_REMOTE_PATH` to `RCLONE_LOCAL_PATH` with 16 parallel transfers, size-only comparison, and real-time progress.
2. **Dry-run check** -- immediately after sync finishes, runs `rclone sync --dry-run --combined -` to detect any files that changed on the source while the previous sync was in progress.
3. **Re-sync or sleep** -- if the dry-run finds differences, the sync runs again right away. Otherwise the script sleeps for `SLEEP_TIME` seconds before the next cycle.

### Default rclone Flags

Every sync invocation uses:

```
--transfers 16 --stats-one-line --stats 10s --log-level INFO --size-only
```

Append additional flags via `RCLONE_EXTRA_FLAGS`:

```bash
export RCLONE_EXTRA_FLAGS="--exclude '*.tmp' --bwlimit 50M"
```

## Deployment Examples

### Docker Compose

```yaml
services:
  rclone-sync:
    image: ghcr.io/jordansekky/rclone-sftp-sync:main
    restart: unless-stopped
    environment:
      RCLONE_REMOTE: myremote
      RCLONE_REMOTE_PATH: path/to/source/
      RCLONE_LOCAL_PATH: /data/
      SLEEP_TIME: "300"
    volumes:
      - /mnt/data/destination:/data
      - ~/.config/rclone:/config/rclone:ro
```

### systemd Service

```ini
[Unit]
Description=rclone continuous sync
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=RCLONE_REMOTE=myremote
Environment=RCLONE_REMOTE_PATH=path/to/source/
Environment=RCLONE_LOCAL_PATH=/mnt/data/destination/
Environment=SLEEP_TIME=300
ExecStart=/path/to/rclone_sync.sh
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
```

## License

MIT
