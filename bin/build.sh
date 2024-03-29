#!/usr/bin/env bash
#
# Given a version and adapter, builds a docker image for it locally.
# Useful for testing changes to images without pushing them to ghcr (note that
# you may need to comment out the logic in dbt-server that pulls the images on
# startup, if images for the specified adapter/version already exist in gchr).

set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=${SCRIPT_DIR}/..

version=$1
adapter=$2

python3 "${SCRIPT_DIR}"/generate_requirements.py "${version}" "${adapter}"

if [ -z "${adapter}" ]; then
    requirements_file="requirements.txt"
    image_name="dbt-full"
else
    requirements_file="requirements-${adapter}.txt"
    image_name="dbt-${adapter}"
fi

tag="ghcr.io/popsql/${image_name}:${version}"

docker build \
    --build-arg REQUIREMENTS_FILE="${requirements_file}" \
    --build-arg DBT_VERSION="${version}" \
    --tag "${tag}" \
    "${BASE_DIR}"

echo "Successfully built image ${tag}"
