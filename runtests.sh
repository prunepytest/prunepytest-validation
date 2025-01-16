#!/bin/bash

set -x -eu -o pipefail

readonly abs_dir=$(cd "$(dirname "${BASH_SOURCE[0]}" )" && pwd)

readonly pymin=${PYMINOR:-}
readonly python=python3${pymin}

cd "${abs_dir}"

# install uv locally if not already available
if ! command -v uv ; then
  echo "--- installing uv locally"
  ${python} -m venv .venv
  export PATH=$(pwd)/.venv/bin:$PATH
  ${python} -m pip install uv
fi

# default to most recent version
prunepytest=${PRUNEPYTEST_INSTALL:-prunepytest}

if [[ -n "${1:-}" ]] ; then
  repos=(repos/${1})
else
  # default omits pandas because its test suite is slow and unreliable
  repos=(repos/mypy repos/pydantic repos/pydantic.v1 repos/tomli)
fi

# TODO: sort input folders for predictable ordering
for repo in "${repos[@]}" ; do
    echo "--- validating: $repo"

    # use subshell to avoid cross-contamination
    (
      set -e
      cd "$repo"
      d=".repo"

      if [[ "${DIRTY:-}" == "1" ]] && [[ -d "$d/.venv" ]]; then
        cd "$d"
      else
        clone_args=($(cat repo_url))

        # quick repo clone
        rm -rf "$d"
        # NB: tree-less clone works fine for validation but gets extremely slow
        # for impact analysis... stick to blob-less
        # --filter=tree:0
        git clone --filter=blob:none --single-branch "${clone_args[@]}" "$d"

        cd "$d"

        # venv setup
        if [[ -n "${pymin}" ]] ; then
          uv venv --python "3${pymin}" .venv --seed
        else
          uv venv .venv --seed
        fi
      fi

      source .venv/bin/activate

      pyver=$(${python} -c 'import sys ; print(".".join(str(v) for v in sys.version_info[0:2]))')
      pyminor=$(cut -d. -f2 <<<"$pyver")

      if [[ -f ../maxpyver ]] && (( $pyminor > $(cat ../maxpyver) )); then
        echo "incompatible python version ($pyver). skipping..."
        # exit subshell, so jump to next iteration of the loop
        exit
      fi

      # NB: for some packages, this might recreate the venv...
      if [ -x ../setup.sh ] ; then
          ../setup.sh
      else
        uv pip install -e .
        uv pip install pytest
      fi

      # ensure we have prunepytest installed
      uv pip install ${prunepytest} --force-reinstall

      if [[ "${PY_COVERAGE:-}" == "1" ]] ; then
        uv pip install slipcover

        libpath=".venv/lib/python$pyver"

        runpy=(${python} -m slipcover)
        runpy+=(--source $libpath/site-packages/prunepytest)
        runpy+=(--json --out cov.json)
        runpy+=(-m)
      else
        runpy=(${python} -m)
      fi

      prune_args=()
      if [ -f "../hook.py" ] ; then
          prune_args+=(--prune-hook=../hook.py)
      fi

      if [[ "${VALIDATE:-1}" == "1" ]] ; then
        # save graph in pre-test validation for use at test-time
        prune_args+=(--prune-graph=graph.bin)

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
      fi

      echo "impact check"
      impact_depth=${IMPACT_DEPTH:-100}
      pytest_args=(--prune -vv ${prune_args:+"${prune_args[@]}"} --prune-impact --prune-impact-depth="${impact_depth}")
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
  ${python} -m slipcover \
    --out "${PY_COVERAGE_OUT}" \
    --merge \
    repos/*/.repo/cov.json \
    repos/*/.repo/cov.pretest.json
fi
