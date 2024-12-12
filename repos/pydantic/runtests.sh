#!/bin/bash
set -e -x
exec uv run -m pytest "${@}"