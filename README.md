# `popsql/dbt` docker images

This repo contains the code for generating our dbt Docker images, which are located on
the GitHub container registry.

Based off of the official python image, we then add:

- `dbt-core`
- `dbt-rpc`
- one or all of the `dbt` adapters (e.g. `dbt-postgres`)

Where each image is available for dbt 0.19 onward.

## Use

Images are published to the GitHub container registry, where we have one image that
contains all the adapters, and then a container per adapter:

```bash
# has all adapters
docker pull ghcr.io/popsql/dbt-full:${VERSION}
# individual adapters
docker pull ghcr.io/popsql/dbt-${ADAPTER}:${VERSION}
```

Each image has both the dbt CLI as well as RPC programs available to use. The image
sets the following environment variables by default:
* `DBT_PROFILES_DIR=/.dbt` - where dbt should look for the profiles directory
* `AWS_SHARED_CREDENTIALS_FILE=/.dbt/aws_credentials` - where boto3/AWS libraries will look for the AWS credentials file

The `DBT_PROFILES_DIR` variable can be overwritten when passing the `--profiles-dir` flag for a command.

On image start, the image entrypoint will do the following checks to setup the `/.dbt` directory:
* If `DBT_PROFILES` is set:
  * write the contents to `/.dbt/profiles.yml`
  * If `AWS_CREDENTIALS` is set, write its contents to `/.dbt/aws_credentials`
  * If `BQ_KEYFILE` is set, write its contents to `/.dbt/bq_keyfile.json`
* else:
  * If `~/.dbt/profiles.yml` exists, copy it to `/.dbt/profiles.yml`
  * If `~/.aws/credentials` exists, copy it to `/.dbt/aws_credentials`

## Development

The repo is structured such that under the `./requirements` folder, there is a folder
that contains each version of dbt we support. Within each folder, there is then
`pyproject.toml` and `poetry.lock` files. Within each `pyproject.toml`, there is then
the list of adapters we support for that given version, along with the shared
dependencies (e.g. `dbt-core` and `dbt-rpc`). After changing something within the
`pyproject.toml` file, you will need to run `poetry lock` to update the `poetry.lock`
file (use `poetry lock --no-update` to avoid unnecessarily updating all dependencies
in the lock file).

As part of our CD process, we then handle generating a per adapter requirements file
from these two files.

### Requirements

* Python 3.8+
* [poetry](https://python-poetry.org/)

### Building Images Locally

Docker images can be built locally via the `./bin/build.sh` script, which takes two
arguments: a version and optionally an adapter. For example, the following command
builds the full image for dbt 1.4:

```bash
./bin/build.sh 1.4
```

and then to build the image for just Athena adapter for 1.4:

```bash
./bin/build.sh 1.4 athena
```

The image is named and tagged in the same fashion as when it's built by the deploy
pipeline, meaning that it can be used locally in place of such an image until it's
pulled down from ghcr again.

## Docker Platforms

Most of the produced images should support the following platforms:

- linux/amd64
- linux/arm64

Some images may not have a `linux/arm64` target if building for it is not possible, or
very ardous. For example, `dbt-snowflake <= 1.1` requires building pyarrow from source
which requires a bunch of additional packages and time, so we only have `linux/amd64`
platforms available there.

The information on which platforms to build for a given image is captured within our
`deploy.yml` CD script.
