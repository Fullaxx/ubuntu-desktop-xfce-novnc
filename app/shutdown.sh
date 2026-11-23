#!/bin/bash
# This script runs as root
# supervisord event listener (conf/supervisord.conf): stops supervisord, and with it the container,
# when the desktop ends (log out, or an error in ubuntu-desktop-xfce's startup stages), as
# ubuntu-desktop-xfce stops when its desktop session ends; and when a program can't be started
# (FATAL), such as websockify without its CERTFILE
#
# supervisord's listener protocol (http://supervisord.org/events.html): write READY, read a header
# line that ends with len:N, read the N-byte payload, then write RESULT 2\nOK
# stdout carries the protocol, so messages go to stderr (docker logs)

# supervisord stops this listener last, with SIGTERM: exit 0, so it isn't logged as a WARN
trap 'exit 0' TERM

while echo READY; read -r HEADER; do
  # e.g. processname:desktop groupname:desktop from_state:RUNNING expected:1 pid:12
  read -r -N "${HEADER##*len:}" PAYLOAD
  case " ${HEADER} ${PAYLOAD} " in
    *" processname:desktop "*|*" eventname:PROCESS_STATE_FATAL "*)
      echo "shutdown: ${PAYLOAD}: stopping the container" >&2
      # supervisord stops the other programs, then exits
      kill -TERM "${PPID}"
      ;;
  esac
  printf 'RESULT 2\nOK'
done
