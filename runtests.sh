#!/bin/bash

set -x -eu -o pipefail

readonly abs_dir=$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)

cd "${abs_dir}"

# install uv locally if not already available
if ! command -v uv ; then
  echo "--- installing uv locally"
  python3 -m venv .venv
  export PATH=$(pwd)/.venv/bin:$PATH
  python -m pip install uv
fi

# default to most recent version
prunepytest=${PRUNEPYTEST_INSTALL:-prunepytest}

# TODO: sort input folders for predictable ordering
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
        git clone --filter=tree:0 --single-branch "${clone_args[@]}" "$d"

        cd "$d"

        # venv setup
        uv venv .venv --seed
        source .venv/bin/activate

        # NB: for some packages, this might recreate the venv...
        if [ -x ../setup.sh ] ; then
            ../setup.sh
        fi
      else
        cd "$d"
        source .venv/bin/activate
      fi

      pyver=$(python -c 'import sys ; print(".".join(str(v) for v in sys.version_info[0:2]))')
      pyminor=$(cut -d. -f2 <<<"$pyver")

      if [[ -f ../maxpyver ]] && (( $pyminor > $(cat ../maxpyver) )); then
        echo "incompatible python version ($pyver). skipping..."
        # exit subshell, so jump to next iteration of the loop
        exit
      fi

      # ensure we have prunepytest installed
      uv pip install ${prunepytest} --force-reinstall

      if [[ "${PY_COVERAGE:-}" == "1" ]] ; then
        uv pip install slipcover

        libpath=".venv/lib/python$pyver"

        runpy=(python3 -m slipcover)
        runpy+=(--source $libpath/site-packages/prunepytest)
        runpy+=(--json --out cov.json)
        runpy+=(-m)
      else
        runpy=(python3 -m)
      fi

      # save graph in pre-test validation for use at test-time
      prune_args=(--prune-graph graph.bin)
      if [ -f "../hook.py" ] ; then
          prune_args+=(--prune-hook ../hook.py)
      fi

      echo "pre-test validation"
      "${runpy[@]}" prunepytest.validator "${prune_args[@]}"

      if [[ "${PY_COVERAGE:-}" == "1" ]] ; then
        mv cov.json cov.pretest.json
      fi

      echo "test-time validation"
      pytest_args=(--prune --prune-no-select "${prune_args[@]}")
      export PYTEST_ADDOPTS="${pytest_args[@]}"
      if [ -x ../runtests.sh ] ; then
        ../runtests.sh
      else
        "${runpy[@]}" pytest
      fi
    )
done

if [[ "${PY_COVERAGE:-}" == "1" ]] ; then
  echo
  echo "--- merging python coverage data"

  # NB: we're just using the last subfolder venv we activated
  # which is guaranteed to have slipcover installed if we're collecting coverage data
  python3 -m slipcover \
    --out "${PY_COVERAGE_OUT}" \
    --merge \
    repos/*/.repo/cov.json \
    repos/*/.repo/cov.pretest.json
fi
