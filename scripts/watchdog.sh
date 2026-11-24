#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
need systemd-run; need systemctl
[[ -f .state/aws.env ]] || fail 'Primero debe existir el inventario AWS'
# Timers de usuario sobreviven al cierre de esta terminal, no a WSL/PC apagado.
export UNIT="$LAB_ID-cleanup"
if ! systemctl --user show-environment >/dev/null; then fail 'systemd de usuario no está disponible'; fi
systemd-run --user --collect --unit="$UNIT" --on-active="${LAB_HOURS}h" --timer-property=AccuracySec=10s --property=Restart=on-failure --property=RestartSec=5min --property=StartLimitIntervalSec=0 --setenv="PATH=$PATH" --setenv="AWS_PROFILE=${AWS_PROFILE:-default}" /bin/bash "$ROOT/scripts/cleanup.sh" --aws --apply
systemctl --user is-active "$UNIT.timer"
printf '%s\n' "$UNIT" > .state/timer-unit
echo "Temporizador local armado. Mantener equipo/WSL encendido y sesión AWS válida durante ${LAB_HOURS}h y la limpieza."
