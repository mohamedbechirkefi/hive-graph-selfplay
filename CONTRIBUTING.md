# Contributing to HiveMind

Thank you for your interest in HiveMind.

HiveMind is an independent, source-available AI research project
maintained by Mohamed Bechir Kefi.

We welcome technical suggestions, bug reports, reproducibility
results, performance improvements, and Pull Requests.

The project is available for non-commercial research under its
current license (the HiveMind Source-Available Non-Commercial Research
License). It is not OSI-approved open-source software.

## 1. How to contribute

Contributions are welcome in the following areas:

- Bug fixes and correctness improvements
- Neural network architecture research
- Monte Carlo Tree Search (MCTS) improvements
- Reinforcement learning and self-play optimization
- Performance benchmarking
- Graph-based and grid-based representations
- Testing and reproducibility improvements
- Documentation and research discussions

For major architectural changes, please open an Issue before
starting implementation.

Any change to move generation must keep the correctness checks green
(perft tables, UHP conformance, differential fuzzing); see the
"Correctness" section of the README.

## 2. Non-commercial research

The current LICENSE permits downloading, running, testing,
benchmarking, and locally modifying newly licensed material
for non-commercial research and educational purposes.

Commercial use, incorporation into other products, and general
redistribution are not permitted without separate authorization.

Earlier MIT-licensed releases (up to and including v2.1-report) retain
their original permissions. See [NOTICE.md](NOTICE.md).

## 3. Pull Request requirements

Before submitting a Pull Request, please ensure that:

1. Your contribution is original or appropriately licensed.
2. You have the necessary rights to submit the work.
3. Your code does not contain credentials, secrets, or
   confidential information.
4. You have included relevant tests when appropriate.
5. You have described any performance or research results.
6. You have identified third-party dependencies and licenses.
7. New files carry the header
   `SPDX-License-Identifier: LicenseRef-HiveMind-NC-Research-1.0`.
8. You are prepared to accept the Contributor License
   Agreement (CLA) before your contribution is merged.

## 4. Contributor License Agreement

A recorded acceptance of the Contributor License Agreement
([CLA.md](CLA.md)) is required before merging copyrightable code or
documentation contributions.

How to sign: when you open a Pull Request, an automated "CLA Assistant"
check comments on it. Read the CLA, then post this exact comment on
your Pull Request:

> I have read the HiveMind CLA v1.0 and I hereby sign it

The check records your signature (your public GitHub username and
account ID, the date and the PR) and turns green. You sign once; it
covers your later contributions too. If the check does not update,
comment `recheck`.

The CLA allows the maintainer to use, modify, distribute,
relicense, and commercially exploit accepted contributions.

Contributors retain copyright in their original contributions.

Submitting a Pull Request does not automatically transfer
ownership of your code.

Checking a Pull Request checkbox is not, by itself, a
signature of the CLA; the signing comment above is.

## 5. Attribution

Contributors may be recognized through:

- Git commit history
- Pull Request records
- Release notes
- Contributor acknowledgments

Attribution does not create ownership of the repository
or confer additional commercial licensing rights.

## 6. Project governance

Mohamed Bechir Kefi is the project owner and lead maintainer.

The maintainer retains responsibility for:

- Project direction and roadmap
- Acceptance or rejection of contributions
- Release management
- Repository administration
- Licensing decisions for material the maintainer owns
  or has sufficient rights to relicense

## 7. Responsible disclosure

Please avoid publicly disclosing sensitive security issues
before they can be addressed.

Use GitHub's private vulnerability reporting feature when
available, or request a private contact method.

## 8. Questions and suggestions

Open a GitHub Issue to discuss technical ideas, experiments,
or proposed improvements.

Repository:
https://github.com/mohamedbechirkefi/hive-graph-selfplay

Thank you for contributing to HiveMind research.
