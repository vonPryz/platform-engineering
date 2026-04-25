# CI/CD Simulation Using Docker and C++ Unit Tests

This project demonstrates CI/CD gating mechanics using C++.

It mirrors the Python-based [`simulate-cicd`](../simulate-cicd/README.md) demo
and exists solely to show that CI/CD pipelines are **language-agnostic**.

Three versions are provided:

- v1 — tests pass
- v2 — intentional bug, tests fail
- v3 — bug fixed, tests pass again

The pipeline behavior is identical regardless of language.
