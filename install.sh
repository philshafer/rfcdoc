#!/bin/sh

fail () {
    echo "$@"
    exit 1
}

cd `dirname $0`

TOP=`pwd`
TOOLS="$TOP/tools"
mkdir -p $TOOLS

if [ -z "$TOOLSCRIPT" ]; then
    TOOLSCRIPT=$TOOLS/install.log
    exec script $TOOLSCRIPT env "TOOLSCRIPT=$TOOLSCRIPT" /bin/sh install.sh "$@"
fi

echo "Current directory is $TOP"

echo "Downloading submodules (if needed) ... "
git submodule update --init --recursive

PYTHON=python
VERS=`$PYTHON --version 2>&1 | awk '{print $2}'`

case "$VERS" in
    3*)
        echo "Using $PYTHON version $VERS"
        ;;
    *)
        echo "$PYTHON version $VERS not acceptable; trying python3"
        PYTHON=python3
        VERS=`$PYTHON --version | awk '{print $2}' 2>/dev/null`
        case "$VERS" in
            3*)
                echo "Using $PYTHON version $VERS"
                ;;
            *)
                fail "Unable to find python3; instant death"
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
if [ $? -ne 0 ]; then
    fail "libslax build failed"
fi

echo "Installing xml2rfc ..."
cd $TOP/submodules/xml2rfc
$PYTHON setup.py install --user --install-scripts=$TOOLS/bin
if [ $? -ne 0 ]; then
    fail "xml2rfc build failed"
fi

echo "Installing pyang ..."
cd $TOP/submodules/pyang
$PYTHON setup.py install --user --install-scripts=$TOOLS/bin
if [ $? -ne 0 ]; then
    fail "pyang build failed"
fi

echo "Install complete"
exit 0
