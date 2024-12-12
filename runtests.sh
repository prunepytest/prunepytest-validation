#!/bin/bash

set -x -eu -o pipefail

# install uv locally if not already available
if ! command -v uv ; then
  echo "--- installing uv locally"
  python3 -m venv .venv
  export PATH=$(pwd)/.venv/bin:$PATH
  python -m pip install uv
fi

prunepy=${PRUNEPY_INSTALL:-prunepy}

for repo in repos/${1:-*} ; do
    echo "--- validating: $repo"

    # use subshell to avoid cross-contamination
    (
      cd "$repo"
      d=".repo"

      if [[ "${DIRTY:-}" != "1" ]] ; then
        clone_args=($(cat repo_url))

        # quick repo clone
        rm -rf "$d"
        git clone --filter=tree:0 "${clone_args[@]}" "$d"

        cd "$d"

        # venv setup
        uv venv .venv --seed
        export PATH=$(pwd)/.venv/bin:$PATH

        # NB: for some packages, this might recreate the venv...
        if [ -x ../setup.sh ] ; then
            ../setup.sh
        fi
      else
        cd "$d"
        export PATH=$(pwd)/.venv/bin:$PATH
      fi

      # ensure we have prunepytest installed
      uv pip install "${prunepy}" --force-reinstall

      # save graph in pre-test validation for use at test-time
      prune_args=(--prune-graph graph.bin)
      if [ -f "../hook.py" ] ; then
          prune_args+=(--prune-hook ../hook.py)
      fi

      echo "pre-test validation"
      python3 -m prunepytest.validator "${prune_args[@]}"

      echo "test-time validation"
      pytest_args=(--prune --prune-no-select "${prune_args[@]}")
      if [ -x ../runtests.sh ] ; then
          ../runtests.sh "${pytest_args[@]}"
      else
          pytest "${pytest_args[@]}"
      fi
    )
done
