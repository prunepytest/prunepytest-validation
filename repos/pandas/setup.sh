#!/bin/sh
set -e -x
python -m pip install -r requirements-dev.txt
python -m pip install -ve . --no-build-isolation
