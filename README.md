# Platform Engineering Showcase

This repository contains a set of small, focused examples that illustrate
how to approach **platform engineering, CI/CD, and production artifact design**.

Each project is intentionally scoped to demonstrate a **single concept well**,
rather than combining everything into one large example.

The projects are best explored **in order**.

For a visual overview how the projects fit together, see the
**[PIPELINE_OVERVIEW.md](PIPELINE_OVERVIEW.md)**

---

## Recommended reading order

### 1.  **CI/CD gating mechanics**

This set of projects present a minimal CI/CD-style pipeline:

* A Dockerized test run
* A green -> red -> green version progression
* A real regression stopping the pipeline
* Explicit failure preventing promotion

**Focus:**  
How CI pipelines gate deployments and prevent broken artifacts from shipping,
independent of language. Each variant demonstrates a distinct failure class:

#### Local implementations

* `simulate-cicd`
  Test-gated artifact creation with integrity validation.

* `simulate-cicd-cpp`
  Language-agnostic behavior example with a C++ implementation.

* `simulate-cicd-node`
  Supply-chain metadata drift (lockfile enforcement).

#### GitHub Actions

* `ci.yml`
  GitHub Workflow. Automated test gating.

---

### 2. **CI/CD artifact handoff**

**Focus:**  
How a pipeline-blessed artifact is promoted to a handoff point between pipeline
authority and operational responsibility.

#### Local implementation

* `localstack-s3-promotion`

  A tested artifact is delivered to an S3 handoff location. Artifact integrity
  is verified to ensure the promoted version is the one passed tests.

### **3. Version release management**

#### GitHub implementation

* `release.yml`

  A GitHub release is created from code that is known to have passed automatic
  testing prior to merging into `main`.

---

## Design philosophy

Across all projects:

* Each demo has a **single responsibility**
* CI/CD behavior is explicit and deterministic
* Containers are treated as **immutable artifacts**
* Developer convenience tooling is separated from pipeline logic

---
