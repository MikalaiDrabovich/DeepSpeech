#!/bin/bash

set -xe

source $(dirname "$0")/tc-tests-utils.sh

pyver_full=$1

if [ -z "${pyver_full}" ]; then
    echo "No python version given, aborting."
    exit 1
fi;

pyver=$(echo "${pyver_full}" | cut -d':' -f1)

# 2.7.x => 27
pyver_pkg=$(echo "${pyver}" | cut -d'.' -f1,2 | tr -d '.')

py_unicode_type=$(echo "${pyver_full}" | cut -d':' -f2)
if [ "${py_unicode_type}" = "m" ]; then
  pyconf="ucs2"
elif [ "${py_unicode_type}" = "mu" ]; then
  pyconf="ucs4"
fi;

unset PYTHON_BIN_PATH
unset PYTHONPATH
export PYENV_ROOT="${HOME}/ds-test/.pyenv"
export PATH="${PYENV_ROOT}/bin:$PATH"

mkdir -p ${PYENV_ROOT} || true

model_source=${DEEPSPEECH_PROD_MODEL}
model_name=$(basename "${model_source}")

model_source_mmap=${DEEPSPEECH_PROD_MODEL_MMAP}
model_name_mmap=$(basename "${model_source_mmap}")

download_data

install_pyenv "${PYENV_ROOT}"
install_pyenv_virtualenv "$(pyenv root)/plugins/pyenv-virtualenv"

PYENV_NAME=deepspeech-test
PYTHON_CONFIGURE_OPTS="--enable-unicode=${pyconf}" pyenv install ${pyver}
pyenv virtualenv ${pyver} ${PYENV_NAME}
source ${PYENV_ROOT}/versions/${pyver}/envs/${PYENV_NAME}/bin/activate

platform=$(python -c 'import sys; import platform; plat = platform.system().lower(); plat = "manylinux1" if plat == "linux" else plat; sys.stdout.write("%s_%s" % (plat, platform.machine()));')
deepspeech_pkg="deepspeech-0.1.1-cp${pyver_pkg}-cp${pyver_pkg}${py_unicode_type}-${platform}.whl"

pip install --upgrade ${DEEPSPEECH_ARTIFACTS_ROOT}/${deepspeech_pkg} | cat

run_prod_inference_tests

deactivate
pyenv uninstall --force ${PYENV_NAME}
