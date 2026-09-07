#!/usr/bin/env bash
# Starts the dedicated server from the container's environment. Extra
# arguments are appended, so `docker run ... --public --nostats` works too.
set -euo pipefail

# stdbuf is load-bearing: without a TTY Godot block-buffers stdout, which
# hides every print() diagnostic ("Server started.", registration results,
# player joins) from docker logs until the process exits.
#
# --xr-mode off because the build carries the OpenXR module and would
# otherwise spend startup failing to find a runtime.
#
# Everything after -- lands in OS.get_cmdline_user_args(), which the server
# reads alongside the engine arguments.
# shellcheck disable=SC2086
exec stdbuf -oL -eL /opt/fugitive3d/Fugitive3D_Server_Linux.x86_64 --headless --xr-mode off -- \
	--name "${SERVER_NAME}" \
	--port "${SERVER_PORT}" \
	${SERVER_FLAGS} \
	"$@"
