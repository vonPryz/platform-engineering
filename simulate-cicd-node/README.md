# CI/CD Simulation Using Docker and Node.js (TypeScript)

This example demonstrates CI/CD gating mechanics using
**Node.js and TypeScript**.

It mirrors the Python-based [`simulate-cicd`](../simulate-cicd/README.md)
and the C++-based [`simulate-cicd-cpp`](../simulate-cicd-cpp/README.md) samples.
CI/CD pipelines are **language- and toolchain-agnostic**.

Instead of runtime test failures, this variant demonstrates
**dependency metadata enforcement** via `npm ci`. A **non-code reason** failure
can be stopped from being deployed by CI/CD gating.

---

## What this variant demonstrates

Compared to the Python and C++ versions, this Node.js variant adds one
additional failure mode:

* **Dependency lockfile enforcement**

  * `npm ci` fails if `package.json` and `package-lock.json` are inconsistent
  * The pipeline can fail *before tests run*

This reflects a common real-world CI/CD failure class:
**supply-chain metadata drift**, not application bugs.

---

## Versions

Three versions are provided:

* **v1** — dependencies and lockfile are in sync, build succeeds
* **v2** — `package.json` is changed but the lockfile is not, `npm ci` fails
* **v3** — lockfile is updated to match dependencies, build succeeds again

This produces the same green → red → green pipeline behavior as the other
examples, but for a different reason.

---

## Usage

Make the script executable:

```bash
chmod u+x ci_shim.sh
```

Run the pipeline simulation:

```bash
./ci_shim.sh v1
./ci_shim.sh v2
./ci_shim.sh v3
```

As with the other versions, numeric forms are also accepted:

```bash
./ci_shim.sh 1
./ci_shim.sh 2
./ci_shim.sh 3
```

To see available options:

```bash
./ci_shim.sh --help
```

---

## Debugging a failing build (optional)

In the **v2** scenario, the pipeline fails during the image build step
because `npm ci` detects a lockfile mismatch.

Because the failure occurs at Docker build time, the `--debug` flag cannot be
used to troubleshoot the problem - the lockfile issue prevents the container
from being built.

---
