# PR-driven pipeline with automated releases

A GitHub Actions -driven CI/CD pipeline. A commit to open PR launches automatic
tests. To create a new `release` in the repository, the committer can submit a
slash-command comment. As best practice, the repository has branch protection
rules to require passed tests before merge, and commits must be signed.

## What this demonstrates

The `pr-driven-pipeline` demonstrates how a GitHub repository is set up using
best practices of automatic testing, release version promotion, and managing
identity spoofing risk.

### Commit signing

A best practice method of **commit signing** is used to verify the commit
origin, and to establish **cryptographic chain of custody**. This prevents
identity spoofing where a malicious actor pushes code with spoofed name and
email. It adds a layer of security where a stolen session, or login credentials
are not alone sufficient for pushing malicious code changes. The signing key
must also be compromised.

### Branch protection

Untested code cannot be merged into the `main` branch. Pushing directly into
the `main` branch is prevented via a branch protection rule. Pushing a commit
into a PR triggers automatic tests. A failed test prevents merging of the
branch.

GitHub branch protection rules are active only on public repositories, or for
commercial subscription. Rules on private repositories exist, but are not
enforced.

### Version promotion

A workflow manages GitHub version releases. A contributor can generate a release
after a tested PR is successfully merged into the `main`.

## How this example differs from `simulate-cicd`

The `simulate-cicd` and its versions demonstrate how a pipeline executes
automatic tests, and stops on a failed test. The reviewer can try the different
setups, and experiment how the pipeline works, and how to debug a Docker
container too. This would be how a DevOps engineer develops, and troubleshoots
a complex build process outside of GitHub.

A public GitHub repository won't allow non-contributors to trigger the CI/CD
actions, so the reviewer must examine the Actions workflows.

## How it works

There are two GitHub Actions: `CI Pipeline`, and `Release Pipeline`.

### **CI Pipeline**

The workflow acts on pull requests on the demo path. It gets the latest commit,
and runs a simplified version of `ci_shim.sh` that executes Docker-based build,
and test for the application.

### **Release Pipeline**

The workflow acts on a comment submitted to the PR.

A `/release` will create a new minor release, tagged by incrementing the minor
version by one.

A `/major-release` will create a new major release, tagged by incrementing the
major version by one, and resetting the minor version to zero.

## Trying it yourself

Fork this repository to your own GitHub account. As the fork owner you have
full contributor access and can:

* Open PRs and trigger the CI pipeline
* Comment `/release` or `/major-release` to create releases
* Observe the full green/red/green cycle firsthand

Note: after forking, GitHub Actions may require you to enable workflows
manually in the Actions tab of your fork.

### System requirements

Browsing the repository has no special requirements.

For testing a fork of this repository, system requirements are:

* GitHub repository
* Command line tools:
  * git
  * gh
* Docker (optional, if you want to run the workflow locally)
* No LocalStack, or AWS account is needed.

### Testing a forked repo

1. Fork the repository
2. Enable Actions in your fork (Actions tab → enable)
3. Clone your fork locally
4. Create a feature branch and make a change to `pr-driven-pipeline/app/app.py`
5. Push and open a PR
6. Watch CI run automatically
7. Try the negative path — copy `simulate-cicd/app/app2.py` as `app.py`, push, watch CI fail
8. Fix it, push again, watch CI pass
9. Merge the PR
10. Comment `/release` on the merged PR
11. Check the Releases page for the new tag

## Reviewing without forking the repo

The workflows cannot be triggered without contributor access to the repository.
To verify the demo works as intended:

* **Actions tab** — shows CI pipeline run history, including green and red runs
  triggered by PR commits
* **Releases page** — shows versioned releases created by `/release` comments,
  with release notes referencing the PR that triggered them
* **Pull request history** — shows CI check results directly on individual PRs

The run history demonstrates the full green/red/green cycle and the
release trigger in action.

## Design notes

### Workflows in the **main**

The Release Pipeline workflow must exist on the `main` branch to be triggered
by issue comments. Unlike the CI Pipeline which runs from the PR branch,
`issue_comment` events always execute workflows from the default branch. This
means the release workflow must be merged to `main` before the `/release`
comment trigger becomes active.

### Release policy

The releases are created from the `main` branch from a merged PR comment. A
non-merged development or work-in-progress branch with failed tests does not
affect release generation.

The `/release` comment must be made on a merged PR.

The release workflow includes a merge check that aborts the workflow if it's
triggered on an unmerged PR.

### Known behaviors

The `ci.yml` is configured to react only on path `pr-driven-pipeline/**`.
However, modifying any workflow file in the `.github/workflows` directory may
trigger the `ci.yml` execution. This is a known feature in GitHub Actions,
where a change in a workflow triggers other workflows in case they would need
to be rerun.

### Hash sidecar is absent

GitHub release assets do not include a hash sidecar. Unlike S3 promotion
where independent verification is necessary, GitHub's release infrastructure
provides custody guarantees tied to the release tag. The trust model
differs: S3 requires explicit verification, GitHub releases rely on
platform integrity.
