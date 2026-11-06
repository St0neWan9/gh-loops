#!/bin/bash
# watch.sh [seconds, default 600] — the issue loop's watcher. See LOOP.md.
dir=$(cd "$(dirname "$0")" && pwd)
exec "$dir/../common/watch-loop.sh" "$dir/pending.sh" "${1:-600}"
