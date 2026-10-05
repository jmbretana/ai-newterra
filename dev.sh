#!/usr/bin/env bash
# Levanta backend y frontend juntos. Ctrl+C corta los dos.
cd "$(dirname "$0")"
trap 'kill 0' EXIT

(cd src/backend && npm run dev:log) &
(cd src/frontend && pnpm dev) &
wait
