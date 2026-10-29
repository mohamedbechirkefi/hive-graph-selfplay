# Licensing notice: which material is under which license

This repository contains material under two licenses. This file says which is which.

## 1. MIT: everything up to and including release v2.1-report

Every file as it exists at tag **v2.1-report** (commit
`e608452069475fd2e1459d24457a29a5d62f60bd`, 27 October 2026) and every earlier
commit, tag and release is licensed under the **MIT License**
([`licenses/MIT-PRIOR.txt`](licenses/MIT-PRIOR.txt)).

This includes the engine (`crates/`), the Python training code (`python/`), the
scripts (`scripts/`), the configurations (`configs/`), the protocols and documentation
(`docs/`), the results tables (`results/`), the report sources and PDFs (`paper/`),
the experiment journals (`journal/`) and the records archives attached to the
`v2.0-report` and `v2.1-report` releases.

These MIT permissions, including commercial use, remain valid permanently for that
material, including where it still appears unchanged in later versions of this
repository.

## 2. HiveMind Source-Available Non-Commercial Research License v1.0: new material

Original material **added after the adoption commit** recorded in
[`LICENSE_HISTORY.md`](LICENSE_HISTORY.md) is licensed under the
[HiveMind Source-Available Non-Commercial Research License v1.0](LICENSE), where the
Licensor is entitled to license it on those terms.

- **New files** carry the header `SPDX-License-Identifier: LicenseRef-HiveMind-NC-Research-1.0`.
- **Changes to existing MIT files**: the added or modified lines are covered by the new
  license; the MIT-licensed material they build on remains MIT.
- **Files without a header** that existed at v2.1-report remain MIT unless and until
  they are substantially rewritten and marked with the header above.

When in doubt, the git history is the record: material present at commit
`e608452069475fd2e1459d24457a29a5d62f60bd` is MIT.

## 3. Third-party material

Dependencies, reference engines fetched by `scripts/fetch_opponents.sh` (not shipped
here), fonts, and any other third-party material keep their own licenses.

## 4. The Hive board game

This is an independent research project, not affiliated with or endorsed by the
publisher of the Hive board game. No license here grants rights in Hive's trademarks,
artwork or other third-party rights.
