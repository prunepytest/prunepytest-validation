from typing import AbstractSet

from prunepytest.api import DefaultHook

class RequestsPruneHook(DefaultHook):
    def external_imports(self) -> AbstractSet[str]:
        return {
            # weird import remapping...
            "requests.packages.urllib3",
            "requests.packages.idna",
            "requests.packages.chardet",
        }

    def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
        return {
            f for f in files
            if not (
                f.startswith("docs/")
                or f.endswith(".md")
            )
        }