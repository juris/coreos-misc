#!/usr/bin/env bash
#
# Install PyPy Python interpreter in CoreOS
#

PYPY_PATH="/opt/pypy"
PYPY_VERSION="5.10.0"

if [ "$(whoami)" != "core" ]; then
  echo 'Please run script as "core" user'
  exit 1
fi

# Check if PyPy is already there
if $(${PYPY_PATH}/bin/pypy --version &> /dev/null); then
  echo "Looks like you've got pypy in place! So long!"
  exit 0
fi

sudo mkdir -p $PYPY_PATH /opt/bin
sudo chown core:core $PYPY_PATH
curl -Lso $PYPY_PATH/pypy.tar.bz2 https://bitbucket.org/squeaky/portable-pypy/downloads/pypy-${PYPY_VERSION}-linux_x86_64-portable.tar.bz2
tar jxf $PYPY_PATH/pypy.tar.bz2 -C $PYPY_PATH --strip-components 1
rm $PYPY_PATH/pypy.tar.bz2
sudo ln -s $PYPY_PATH/bin/pypy /opt/bin/python
/opt/bin/python -m ensurepip

exit 0
