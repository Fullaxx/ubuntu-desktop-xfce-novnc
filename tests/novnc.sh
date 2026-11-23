#!/bin/bash
# Start an ubuntu-desktop-xfce-novnc image the way users do and check the whole path:
# the VNC server answers on localhost and only there, websockify serves noVNC on :8080 and its
# WebSocket reaches the VNC server, Xfce is running, and the container stops when the desktop
# session ends. Run it on a Docker host, as .github/workflows/ci.yml does before it publishes:
#   tests/novnc.sh IMAGE

set -euo pipefail

IMAGE="${1:?usage: ${0##*/} IMAGE}"
NAME="udxn-test-$$"

fail() {
  echo "FAIL: $*" >&2
  docker logs --tail 40 "${NAME}" 2>&1 || true
  exit 1
}

running() {
  [ "$(docker inspect -f '{{.State.Running}}' "${NAME}" 2>/dev/null)" == "true" ]
}

trap 'docker rm -f "${NAME}" >/dev/null 2>&1 || true' EXIT

docker run -d --name "${NAME}" "${IMAGE}" >/dev/null

# A VNC server speaks first, with an RFB ProtocolVersion banner such as "RFB 003.008"
BANNER=""
for _ in $(seq 60); do
  running || fail "${IMAGE} exited before the desktop came up"
  BANNER=$(docker exec "${NAME}" timeout 5 bash -c 'exec 3<>/dev/tcp/127.0.0.1/5901 && head -c 12 <&3' 2>/dev/null || true)
  if [[ "${BANNER}" == RFB* ]]; then
    break
  fi
  sleep 1
done
[[ "${BANNER}" == RFB* ]] || fail "no VNC server answered on 127.0.0.1:5901 within 60 s"

# Only on localhost: the container's own address refuses it
if docker exec "${NAME}" timeout 5 bash -c 'ADDR=$(hostname -i); exec 3<>/dev/tcp/${ADDR%% *}/5901' 2>/dev/null; then
  fail "the VNC server also answers on the container's address"
fi

# websockify serves noVNC's web client, and the index.html that opens it
docker exec "${NAME}" curl -fsS -o /dev/null http://127.0.0.1:8080/vnc.html || fail "noVNC's vnc.html is not served on :8080"
docker exec "${NAME}" curl -fsS http://127.0.0.1:8080/ | grep -q 'vnc.html?autoconnect=1' || fail "index.html does not open vnc.html"

# A WebSocket on :8080 reaches the VNC server: websockify accepts the upgrade,
# then forwards the VNC server's RFB banner in a WebSocket frame
WS=$(docker exec "${NAME}" timeout 10 bash -c '
  exec 3<>/dev/tcp/127.0.0.1/8080
  printf "GET /websockify HTTP/1.1\r\nHost: 127.0.0.1:8080\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Protocol: binary\r\n\r\n" >&3
  timeout 3 cat <&3' 2>/dev/null | tr -d '\0' || true)
[[ "${WS}" == *" 101 "* ]] || fail "websockify did not accept a WebSocket on :8080"
[[ "${WS}" == *"RFB 003."* ]] || fail "the WebSocket on :8080 did not reach the VNC server"

# The window manager starts after the VNC server, from its xstartup
SESSION=""
for _ in $(seq 30); do
  if docker exec "${NAME}" sh -c 'grep -qsx xfce4-session /proc/[0-9]*/comm'; then
    SESSION=yes
    break
  fi
  sleep 1
done
[ -n "${SESSION}" ] || fail "the VNC server is up but xfce4-session did not start within 30 s"

# Ending the desktop session stops the container, as in ubuntu-desktop-xfce
docker exec "${NAME}" pkill -x xfce4-session
for _ in $(seq 15); do
  if ! running; then
    echo "OK: ${IMAGE} serves noVNC on :8080 (VNC on localhost only: ${BANNER}), runs Xfce, and stops when the session ends"
    exit 0
  fi
  sleep 1
done
fail "the desktop session ended, but the container is still running after 15 s"
