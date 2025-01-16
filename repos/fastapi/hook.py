import glob
from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class FastapiPruneHook(DefaultHook):
    def __init__(self, *args, **kwargs):
        super().__init__(
            {"fastapi", "docs_src", "tests"},
            set(),
            {"fastapi": "fastapi", "docs_src": "docs_src", "tests": "tests"},
            {"tests": "tests"}
        )

    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            **{
                f: {f"docs_src.{p}.*"}
                for p in (
                    "query_param_models", "cookie_param_models", "header_param_models", "sql_databases",
                    "additional_status_codes"
                )
                for f in glob.iglob(f"tests/test_tutorial/test_{p}/test_tutorial*.py")
            },
        }

    def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
        return {
            f for f in files
            if not (
                f.startswith("docs/")
            )
        }