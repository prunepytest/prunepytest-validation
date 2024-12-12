#!/bin/bash

set -ex -o pipefail

python3 -m venv .venv
source .venv/bin/activate

python3 -m pip install "pytest~=$1"
python3 -m pip install prunepytest


for repo in repos/* ; do
    echo "validating: $repo"
    
    (
    cd "$repo"
    d=$(basename "$repo")
    url=$(cat repo_url)

    rm -rf "$d"
    git clone --filter=tree:0 "$url" "$d"

    cd "$d"

    if [ -x ../setup.sh ] ; then
        ../setup.sh
    fi

    hook_args=()
    if [ -f "../hook.py" ] ; then
        hook_arg+=(-h ../hook.py)
    fi

    echo "pre-test validation"
    python3 -m prunepytest.validator ${hook_args[@]}

    echo "test-time validation"
    if [ -x ../runtests.sh ] ; then
        ../runtests.sh
    else
        pytest --prune --prune-no-select
    fi
    )

done

