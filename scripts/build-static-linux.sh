#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
OUT_DIR=${OUT_DIR:-"$ROOT_DIR/dist"}
TARGET_NAME=${TARGET_NAME:-autossh-linux-x86_64-static}

if ! command -v cc >/dev/null 2>&1; then
	echo "error: C compiler 'cc' was not found" >&2
	exit 1
fi

if [ -z "${BUILD_DIR:-}" ]; then
	BUILD_DIR=$(mktemp -d)
	cleanup_build_dir=1
else
	cleanup_build_dir=0
fi
trap 'if [ "$cleanup_build_dir" = 1 ]; then rm -rf "$BUILD_DIR"; fi' EXIT HUP INT TERM

mkdir -p "$BUILD_DIR" "$OUT_DIR"

tar \
	--exclude='.git' \
	--exclude='dist' \
	--exclude='autom4te.cache' \
	-cf - -C "$ROOT_DIR" . | tar -xf - -C "$BUILD_DIR"

cd "$BUILD_DIR"

: "${CFLAGS:=-Os -pipe}"
: "${LDFLAGS:=-static}"
export CFLAGS LDFLAGS

chmod +x ./configure
./configure --prefix=/usr

jobs=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 2)}
make -j"$jobs"

if command -v strip >/dev/null 2>&1; then
	strip autossh || true
fi

cp autossh "$OUT_DIR/$TARGET_NAME"
chmod 0755 "$OUT_DIR/$TARGET_NAME"

if command -v readelf >/dev/null 2>&1; then
	if readelf -l "$OUT_DIR/$TARGET_NAME" | grep -q 'INTERP'; then
		echo "error: $OUT_DIR/$TARGET_NAME still has a dynamic loader segment" >&2
		readelf -l "$OUT_DIR/$TARGET_NAME" >&2
		exit 1
	fi
fi

if command -v file >/dev/null 2>&1; then
	file "$OUT_DIR/$TARGET_NAME"
fi

"$OUT_DIR/$TARGET_NAME" -V
