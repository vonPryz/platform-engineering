# CI/CD Overview

This document shows how the individual samples in this repository map to
a typical DevOps CI/CD pipeline, from source code to production-readiness.

There are two implementations: a locally-run, and GitHub Actions -based
version. Both demonstrate the same idea with different tools. The local
versions emphasize subtle differences in how CI/CD pipeline gates work, and the
GitHub version is a real-world example that handles a simple case of mandatory
testing and releasing a version.

The local versions using Docker build and shell scripts are independent of
product-based CI/CD environments. The concepts are easily transferable into
GitHub, GitLab, Bitbucket, and others. The `ci_shim.sh` is the main workhorse
for each part, while product-dependent sections are a collection of YAML files
that define configuration and how the shell script should be invoked.

## Projects and dependencies

### Locally-run CI/CD

```text
          Developer
            |
            |  code changes
            v
+======================+
|   Git repository     |
|======================|
|  commits / merges    |
+======================+
            |
            |
            v
+================================+ 
|  CI: Continuous Integration    |
|================================|
|                                |
|  - build test artifacts        |
|    (zip archive +              |
|     sha256 hash sidecar)       |
|  - verify artifact integrity   |
|  - run tests                   |          +=================+
|                                |  (RED)   | Error reporting |
|  GREEN -> continue             | -------> |=================|
|  RED   -> stop pipeline        |          | - Report to the |
|                                |          |   dev team      |
|  [simulate-cicd]               |          +=================+ 
|  [simulate-cicd-cpp]           |
|  [simulate-cicd-node]          |
+================================+   
            | 
            | (GREEN)
            v
+==============================+
|  Cloud Handoff / S3          |
|==============================|
|                              |
|  - verify artifact integrity |
|  - promote to S3 bucket      |
|  - sidecar travels with zip  |
|                              |
|  Pipeline authority ends     |
|  at the bucket               |
|                              |
|  [localstack-s3-promotion]   |
+==============================+
```

### GitHub Actions

```text
          Developer
            |
            |  code changes
            v
+======================+
|   GitHub repository  |
|======================|
|  commits / merges    |
+======================+
            |
            | PR
            v
+================================+
|  CI: Continuous Integration    |
|================================|
|                                |
|  - run automated tests         |          +=================+ 
|                                |  (RED)   | Error reporting | 
|  GREEN -> continue             | -------> |=================|
|  RED   -> stop pipeline        |          | - Report to the |
|                                |          |   dev team      | 
|  [.github/workflows/ci.yml]    |          +=================+ 
+================================+
            |
            | (GREEN)
            v
+================================+
|  GitHub: Merge                 |
|================================|
|                                |
| - merge to main updates the    |
|   main branch with tested      |
|   code from the feature branch |
|                                |
+================================+
            |
            | (/COMMENT)
            v
+==================================+
|  Release Generation              |
|==================================|
|                                  |
|  Tested, and merged code is used |
|  to create new GitHub releases.  |
|                                  |
|  - A comment /release, or        |
|    /major-release triggers       |
|    GitHub Release creation       |
|                                  |
|  [.github/workflows/release.yml] |
+==================================+
```

## Sample mapping

### CI/CD gating mechanics

#### simulate-cicd, simulate-cicd-cpp, simulate-cicd-node

  CI gating mechanics.
  
  These projects demonstrate the same CI/CD concept using different
  implementation languages, showing that pipeline behavior is
  **language-agnostic**. The two first samples demonstrate test failure
  detection. The third is **non-code failure** caused on **dependency**
  **metadata** mismatch.

### CI/CD artifact handoff

#### localstack-s3-promotion

  Artifact handover from development to SRE. The sample promotes an artifact
  to production handoff location. A sidecar hash file is moved along to verify
  the artifact integrity.

### Github Actions

#### CI Pipeline

  CI gating mechanics.

  This workflow runs tests when committed code is pushed into an open PR.

  Only code that has passed tests can be merged into the `main` branch. This
  guarantees the contents of a release were tested automatically.

#### Release Pipeline

  GitHub version release.

  The workflow allows developers to publish minor and major versions of the
  `main` branch. The version numbers are incremented automatically, and the
  release is built from the tested codebase.
