#!/usr/bin/env bash
# Low-battery notifier (uses acpi). Run from niri spawn-at-startup.
notified_20=0
notified_10=0
notified_5=0

while true; do
  status=$(acpi -b 2>/dev/null | grep -o 'Discharging\|Charging' | head -1)
  level=$(acpi -b 2>/dev/null | grep -P -o '[0-9]+(?=%)' | head -1)
  [[ -z "$level" ]] && { sleep 60; continue; }

  if [[ "$status" == "Discharging" ]]; then
    if (( level <= 20 && level > 10 )) && (( notified_20 == 0 )); then
      notify-send -u critical "Battery 20%" "Connect charger"
      notified_20=1
    fi
    if (( level <= 10 && level > 5 )) && (( notified_10 == 0 )); then
      notify-send -u critical "Battery 10%" "Connect charger now"
      notified_10=1
    fi
    if (( level <= 5 )) && (( notified_5 == 0 )); then
      notify-send -u critical "Battery 5%" "System will shutdown soon"
      notified_5=1
    fi
  fi

  if [[ "$status" == "Charging" || "$level" -gt 21 ]]; then
    notified_20=0; notified_10=0; notified_5=0
  fi

  sleep 60
done
