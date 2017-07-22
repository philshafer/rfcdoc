#!/bin/sh

TOP=`pwd`
TOOLS="$TOP/tools"
mkdir -p $TOOLS

if -z "$TOOLSCRIPT"; then
    TOOLSCRIPT=$TOOLS/install.log
    exec script $TOOLSCRIPT env TOOLSCRIPT=$TOOLSCRIPT "$0" "$@"
fi

echo "Current directory is $TOP"

echo "Downloading submodules (if needed) ... "
git submodule update --init --recursive

PYTHON=python
VERS=`$PYTHON --version | awk '{print $2}' 2>/dev/null`

case "$VERS" in
    3*)
        echo "Using $PYTHON version $VER"
        ;;
    *)
        echo "$PYTHON version $VER not acceptable; trying python3"
        PYTHON=python3
        VERS=`$PYTHON --version | awk '{print $2}' 2>/dev/null`
        case "$VERS" in
            3*)
                echo "Using $PYTHON version $VER"
                ;;
            *)
                echo "Unable to find python3; instant death"
                exit 1
                ;;
        esac
        ;;
esac

echo "Installing libslax ..."
cd submodules/libslax/
autoreconf --install
autoreconf --install
mkdir build
cd build
../configure --prefix $TOOLS
make && make install && make test

echo "Installing xml2rfc ..."
cd $TOP/submodules/xml2rfc
$PYTHON setup.py install --user --install-scripts=$TOOLS/bin

echo "Installing pyang ..."
cd $TOP/submodules/pyang
$PYTHON setup.py install --user --install-scripts=$TOOLS/bin

echo "Install complete"
exit 0
