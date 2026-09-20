#!/usr/bin/env bash
while true; do
  sleep 1
  wlrctl pointer move 1 1 || true
  wlrctl pointer move -1 -1 || true
done
