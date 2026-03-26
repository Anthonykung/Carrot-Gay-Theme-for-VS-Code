#!/bin/bash

# SPDX-License-Identifier: MIT
# Author: Anthony Kung <hi@anth.dev> (anth.dev)
#
# Basic machine information script

set -u

print_section() {
  printf '\n== %s ==\n' "$1"
}

safe_cmd() {
  local fallback="$1"
  shift

  if command -v "$1" >/dev/null 2>&1; then
    "$@"
  else
    printf '%s\n' "$fallback"
  fi
}

print_section "System"
printf 'Hostname: %s\n' "$(hostname 2>/dev/null || printf 'unknown')"
printf 'User: %s\n' "${USER:-unknown}"
printf 'Shell: %s\n' "${SHELL:-unknown}"
printf 'Kernel: %s\n' "$(uname -srmo 2>/dev/null || printf 'unknown')"
printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || printf 'unknown')"

print_section "CPU"
if [[ -r /proc/cpuinfo ]]; then
  cpu_model="$(awk -F: '/model name/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)"
  cpu_cores="$(awk -F: '/cpu cores/ {gsub(/^[ \t]+/, "", $2); print $2; exit}' /proc/cpuinfo)"
  printf 'Model: %s\n' "${cpu_model:-unknown}"
  printf 'Cores: %s\n' "${cpu_cores:-unknown}"
else
  safe_cmd "Model: unknown" uname -p
fi

print_section "Memory"
if [[ -r /proc/meminfo ]]; then
  awk '
    /MemTotal/ { total = $2 / 1024 }
    /MemAvailable/ { available = $2 / 1024 }
    END {
      printf "Total: %.0f MiB\n", total
      printf "Available: %.0f MiB\n", available
    }
  ' /proc/meminfo
else
  safe_cmd "Memory info unavailable" free -h
fi

print_section "Disk"
safe_cmd "Disk info unavailable" df -h /

print_section "Network"
printf 'Primary IP: %s\n' "$(hostname -I 2>/dev/null | awk '{print $1}' || printf 'unknown')"
safe_cmd "No routing info available" ip route show default
