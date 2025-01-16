from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class BlackPruneHook(DefaultHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            # importlib entrypoint resolution...
            "tests/test_schema.py": {"black.schema", "black.resources"}
        }

    # def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
    #     return {
    #         f for f in files
    #         if not (
    #             f.startswith("docs/")
    #             or f.endswith(".md")
    #         )
    #     }