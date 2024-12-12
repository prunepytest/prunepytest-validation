from typing import AbstractSet, Mapping

from prunepytest.api import ZeroConfHook

class PydanticPruneHook(ZeroConfHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            # this import happens via entrypoint registered at install time...
            "tests/test_hypothesis_plugin.py": {"pydantic._hypothesis_plugin"},

            # some tests do a bunch of dynamic imports...
            "tests/mypy/test_mypy.py": {"tests.mypy.modules.*"},
            "tests/test_structural_pattern_matching.py": {"pydantic"},
            "tests/test_v1.py": {"pydantic.v1.*"},
        }
