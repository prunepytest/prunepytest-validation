from typing import AbstractSet, Mapping

from prunepytest.api import DefaultHook

class GunicornPruneHook(DefaultHook):
    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        return {
            "tests/test_arbiter.py": {"gunicorn.glogging", "gunicorn.http.wsgi", "gunicorn.workers.sync"},
            "tests/test_config.py": {"config.test_cfg"},
            "tests/test_invalid_requests.py": {"gunicorn.config", "gunicorn.http.errors"},
            "tests/test_valid_requests.py": {"gunicorn.config", "gunicorn.http.errors"},
        }

    #
    # def filter_irrelevant_files(self, files: AbstractSet[str]) -> AbstractSet[str]:
    #     return {
    #         f for f in files
    #         if not (
    #             f.startswith("docs/")
    #             or f.endswith(".md")
    #         )
    #     }