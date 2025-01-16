from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class CherryPyPruneHook(DefaultHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            "cherrypy/test/test_tutorials.py": {"cherrypy.tutorial.*"}
        }

    def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
        return {
            f for f in files
        }