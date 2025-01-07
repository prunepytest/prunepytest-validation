from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class MypyPruneHook(DefaultHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            # make sure changes to the vendored typeshed trigger test runs
            "mypy.util": {"mypy.typeshed.stdlib.*"}
        }

    def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
        return {
            f for f in files
            if not (
                f.startswith("docs/")
                or f.startswith("misc/")
                or f.endswith(".md")
                or f.endswith(".rst")
            )
        }