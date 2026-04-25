# CI/CD Simulation Using Docker and Python Unit Tests

This project demonstrates a minimal CI/CD-style pipeline:

* A **Python application** is built into a **Docker container**
* The container **runs unit tests** using `pytest`
* If tests **fail**, the pipeline **stops** (non-zero exit code)
* If tests **pass**, the pipeline continues

Three versions of the application are included to demonstrate the workflow:

* **v1** — Working implementation (tests pass).
* **v2** — Introduces a bug (tests fail, pipeline stops).
* **v3** — Bug fixed (tests pass again).

**Artifact integrity validation** is included in the test phase. When an app
version is chosen, a zip archive and sha256 checksum sidecar are created. The
container build verifies the archive matches the checksum before running any
tests. This ensures the artifact under test is identical to the one that will
be promoted. This also closes the gap between what was tested and what gets
deployed. A mismatch stops the pipeline immediately.

Artifacts are only written on a green run; a missing artifact indicates the
pipeline has not been run or did not pass.

---

## System requirements

* **Docker**
  * Docker Engine / Docker Desktop that can run Linux containers.
  * Internet access to download the Linux image

* **Unix-like environment**
  * Shell for running the `ci_shim.sh`
  * Indented to run on **MacOS** or **Linux**
  
* A few hundred MB free disk space for the Docker images

---

## Usage

Make the CI simulation script executable:

```bash
chmod u+x ci_shim.sh
```

Run the script:

```bash
./ci_shim.sh v1
./ci_shim.sh v2
./ci_shim.sh v3
```

You may also use numeric forms:

```bash
./ci_shim.sh 1
./ci_shim.sh 2
./ci_shim.sh 3
```

Usage:

```bash
./ci_shim.sh --help
```

---

## Version Behavior Summary

| Version | ⎇ Behavior    | Notes                                            |
| ------- | ------------  | ------------------------------------------------ |
| **v1**  | ✅ Tests pass | Contains a harmless docstring bug                |
| **v2**  | ❌ Tests fail | Intentional logic error: addition bug introduced |
| **v3**  | ✅ Tests pass | All issues fixed                                 |

This sequence provides a green -> red -> green CI/CD demonstration.

---

## Debugging a failing container (optional)

The v2 scenario intentionally cause tests to fail. By default, the container
exits immediately, mimicking CI/CD behavior.

To keep a failing container running for inspection, use the `--debug` flag:

```bash
./ci_shim.sh v2 --debug
```

When debug mode is enabled:

* The container remains running after a test failure
* The container state can be examined interactively
* The pipeline still reports failure (non-zero exit code)

---

## Simulating artifact mismatch (optional)

Use the `--hash-mismatch` switch to cause an intentional hash mismatch, and
to stop the pipeline.

A hash mismatch will stop the Docker build before any tests are being run.
The `--debug` flag is not effective when hash mismatch is detected, as the
container never enters executable state.

```bash
./ci_shim.sh v1 --simulate-mismatch
```

---

### Build and run a version manually

```bash
docker build --no-cache --build-arg APP_VERSION=1 -t simulate-cicd:v1 .
docker run --rm simulate-cicd:v1
```

### Enter a container for interactive debugging

After building a version:

```bash
docker run --rm -it --entrypoint /bin/bash simulate-cicd:v1
```
