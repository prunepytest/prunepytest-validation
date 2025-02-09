from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class TomliPruneHook(DefaultHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            # make sure changes to the vendored typeshed trigger test runs
            "tests/test_misc.py": {"tomli._types"}
        }
