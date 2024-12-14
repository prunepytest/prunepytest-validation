from typing import AbstractSet, Mapping

from prunepytest.api import ZeroConfHook

class PydanticPruneHook(ZeroConfHook):
    def include_typechecking(self) -> bool:
        return True

    def dynamic_dependencies(self) -> Mapping[str, AbstractSet[str]]:
        from pydantic import _migration
        def _extract_imports(d):
            return {v.partition(':')[0] for t in d for v in (t if isinstance(t, tuple) else (t,))}

        migration_imports = (
            _extract_imports(_migration.MOVED_IN_V2.items())
            | _extract_imports(_migration.DEPRECATED_MOVED_IN_V2.items())
            | _extract_imports(_migration.REDIRECT_TO_V1.items())
            | _extract_imports(_migration.REMOVED_IN_V2)
        )

        return {
            "tests/test_migration.py": migration_imports,
            "tests/mypy/test_mypy.py": {"tests.mypy.modules.*"},
            "tests/test_structural_pattern_matching.py": {"pydantic"},
            "tests/test_v1.py": {"pydantic.v1.*"},
        }

    def always_run(self) -> AbstractSet[str]:
        # these are just too complicated to deal with as they may have arbitrary
        # dynamic imports from docstrings / markdown examples
        # instead of manually maintaining a list of imports covered by those
        # examples, we just bail and always run those tests...
        return {
            "tests/test_docs.py:test_docstrings_examples",
            "tests/test_docs.py:test_docs_examples"
        }