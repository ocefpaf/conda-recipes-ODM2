#!/usr/bin/env bash

if [ "${BINSTAR_TOKEN}" ]; then
  export UPLOAD="--upload-channels odm2"
else
  export UPLOAD=""
fi

REPO_ROOT=$(cd "$(dirname "$0")/.."; pwd;)
UPLOAD_OWNER="odm2"
IMAGE_NAME="ocefpaf/conda-recipes:latest_x64"

config=$(cat <<CONDARC

channels:
 - ${UPLOAD_OWNER}
 - defaults

show_channel_urls: True

CONDARC
)

cat << EOF | docker run -i \
                        -v ${REPO_ROOT}:/conda-recipes \
                        -a stdin -a stdout -a stderr \
                        $IMAGE_NAME \
                        bash || exit $?

if [ "${BINSTAR_TOKEN}" ];then
    echo
    export BINSTAR_TOKEN=${BINSTAR_TOKEN}
fi

export CONDA_NPY='19'
export PYTHONUNBUFFERED=1
echo "$config" > ~/.condarc

conda update conda --yes
conda install conda-build jinja2 anaconda-client --yes
conda install -c conda-forge conda-build-all --yes

# A lock sometimes occurs with incomplete builds.
conda clean --lock

conda info

conda-build-all /conda-recipes/recipes $UPLOAD --inspect-channels $UPLOAD_OWNER --matrix-conditions "numpy >=1.9" "python >=2.7,<3|>=3.4"

EOF
