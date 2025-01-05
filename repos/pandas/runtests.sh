#!/bin/bash
set -e -x

export PANDAS_CI=1
export PYTEST_TARGET=pandas
export PYTEST_WORKERS=auto
export PATTERN="not slow and not network and not clipboard and not single_cpu"

export PYTHONHASHSEED=$(python -c 'import random; print(random.randint(1, 4294967295))')
export PYTHONDEVMODE=1
export PYTHONWARNDEFAULTENCODING=1

exec python -m pytest -r fE  -n "${PYTEST_WORKERS}" --dist=worksteal -s "${PYTEST_TARGET}" -m "$PATTERN"