#!/bin/bash
set -e -x
# this returns a pytest command, which might be invoked with slipcover wrapper
exec python -c 'import shlex ; print(*(shlex.quote(s) for s in __import__("runtests").cmds["pytest-fast"]))'