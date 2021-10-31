#!/bin/bash
set -euo pipefail

NAME="${1}"

cp -r build "${NAME}"
find "${NAME}" -type f -not '(' -name '*.sym' -or -name '*.gb' ')' -delete
rm -f "${NAME}".zip "${NAME}".tar.gz "${NAME}".tar.xz
zip -r "${NAME}".zip "${NAME}"
tar -czvf "${NAME}".tar.gz "${NAME}"
tar -cJvf "${NAME}".tar.xz "${NAME}"
