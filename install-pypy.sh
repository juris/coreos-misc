#!/usr/bin/env bash
#
# Install PyPy Python interpreter in CoreOS
#

PYPY_PATH="/opt/pypy"
PYPY_VERSION="5.6"

if [ "$(whoami)" != "core" ]; then
  echo 'Please run script as "core" user'
  exit 1
fi

# check if PyPy is already there
if $(${PYPY_PATH}/bin/pypy --version &> /dev/null); then
  echo "Looks like you've got pypy in place! So long!"
  exit 0
fi

sudo mkdir -p $PYPY_PATH
sudo chown core:core $PYPY_PATH
curl -Lo $PYPY_PATH/pypy.tar.bz2 https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-${PYPY_VERSION}-linux_x86_64-portable.tar.bz2
tar jxf $PYPY_PATH/pypy.tar.bz2 -C $PYPY_PATH --strip-components 1
rm $PYPY_PATH/pypy.tar.bz2
$PYPY_PATH/bin/pypy -m ensurepip

exit 0
