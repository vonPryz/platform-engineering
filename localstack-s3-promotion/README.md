# CI/CD artifact promotion using LocalStack/AWS S3

This project demonstrates how **artifacts are promoted into production**. A S3
bucket is used as the final destination of an artifact that's passed tests.

A common method for handoff from DevOps to SRE teams is to upload the tested
artifact into S3 bucket. The demo uses a LocalStack S3 as the target
destination, while supporting AWS S3 too.

The demo retrieves a specific version of application tested with the
`simulate-cicd` project. As a convenience, the script can invoke
`simulate-cicd/ci_shim.sh` to create missing artifacts.

---

## System Requirements

Either AWS or LocalStack emulation can be used.

* **A LocalStack S3 bucket or an AWS S3 Bucket**
  * LocalStack:
    * Auth token
    * awslocal-cli
    * dummy AWS environment variables (see notes)
    * 2 GB free disk space for LocalStack image
  * AWS:
    * Pre-created bucket, or permissions to create one
    * Permissions to create objects in the bucket
    * awscli

If there are no deployable artifact files, the
[**simulate-cicd**](../simulate-cicd/README.md) requirements to build apply:

* **Docker**
  * Docker Engine / Docker Desktop that can run Linux containers
  * Internet access to download the Linux image

* **Unix-like environment**
  * Shell for running the `ci_shim.sh`
  * Intended to run on **MacOS** or **Linux**
  
* A few hundred MB free disk space for the Docker images

---

## Running the demo

Make the script executable before the first run:

```bash
chmod u+x ci_shim.sh
```

Run the script:

```bash
./ci_shim.sh v1
./ci_shim.sh v3 --create-artifacts
```

---

## Design notes

The artifact promotion works in five steps, including housekeeping routines for
checking LocalStack connectivity and bucket access. The same steps would be used
with live AWS to generate an early error if cloud access doesn't work.

1. Artifact zip and sidecar hash file existence are checked from
`simulate-cicd`'s output directory.
2. The zip file hash is checked against the value stored in the sidecar hash
file. This is done to be sure the artifact file is a) un-tampered, and b) the
same archive build process has tested.
3. AWS/LocalStack connectivity and bucket access are tested. The demo version
also creates a LocalStack S3 bucket to make the demo self-contained, as
LocalStack's resources - including S3 buckets are ephemeral.
4. Both the artifact archive and the sidecar hash file are copied into the
destination S3 bucket. This is a common method for handoffs. When the file has
arrived in S3 bucket, the responsibility is handed over from the DevOps team
to the SRE team.
5. Artifact existence in the S3 bucket is verified, and the process is reported
as completed.

A Makefile is provided with a single convenience target.

`clean` target will remove any artifact files from this and the `simulate-cicd`
project. This is used to help removing stale versions and make the process to
reset to a well-known initial state.

Usage:

```bash
make clean
```

---

## LocalStack requirements

To work with LocalStack, license key and activation are needed. Free tier
license is sufficient for running the demo. Refer to the LocalStack
documentation for acquiring one.

Running LocalStack on MacOS sometimes needs a workaround for Docker issues. If
LocalStack container doesn't start in a controlled manner, try disabling events.

```bash
DISABLE_EVENTS=1 DEBUG=1 localstack start -d
```

Dummy AWS keys need to be set up, and default region too. LocalStack doesn't
need these, but awscli expects to have those present.

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=eu-central-1
```

To verify if LocalStack is up and running, query it with cUrl:

```bash
curl -s http://localhost:4566/_localstack/info | jq
```

Instead of using `awslocal-cli` commands, one can use `awscli` by just passing
LocalStack as endpoint-url:

```bash
aws --endpoint-url=http://localhost:4566 s3 ls
````
