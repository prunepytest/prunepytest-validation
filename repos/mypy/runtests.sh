#!/bin/bash
set -e -x

eval $(python -c 'import shlex ; print(*(shlex.quote(s) for s in __import__("runtests").cmds["pytest-fast"]))') --prune --prune-no-select 

