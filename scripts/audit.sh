#!/usr/bin/env bash
source "$(dirname "$0")/common.sh"
aws_state
python3 scripts/audit.py
