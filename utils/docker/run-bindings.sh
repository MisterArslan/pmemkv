#!/usr/bin/env bash
# SPDX-License-Identifier: BSD-3-Clause
# Copyright 2019-2020, Intel Corporation

#
# run-bindings.sh - checks bindings' building and installation
#

set -e

source `dirname $0`/prepare-for-build.sh

# master: Merge pull request #44 from lukaszstolarczuk/update-travis-files, 21.11.2019
RUBY_VERSION="3741e3df698245fc8a15822a1aa85b5c211fd332"

# master: Merge pull request #33 from lukaszstolarczuk/update-travis-files, 21.11.2019
JNI_VERSION="5239d6bb3214c56bc45b3296872be50b38bfbab3"

# master: Merge pull request #34 from lukaszstolarczuk/update-offline-de..., 5.12.2019
JAVA_VERSION="47f02b6b52c56ca53fd3dafdff52167719f1e7dd"

# master: Merge pull request #48 from lukaszstolarczuk/update-travis-files, 21.11.2019
NODEJS_VERSION="d19b026207e8a78ebffdccaffb27181a9bdbe51d"

# master: Merge pull request #16 from lukaszstolarczuk/update-travis-files, 21.11.2019
PYTHON_VERSION="4483f6561a94255546d26f0e9ac4cdcfe209feae"

# build and install pmemkv
cd $WORKDIR
mkdir build
cd build

cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DCMAKE_INSTALL_PREFIX=$PREFIX
make -j$(nproc)
sudo_password -S make -j$(nproc) install

echo
echo "##################################################################"
echo "### Verifying building and installing of the pmemkv-ruby bindings "
echo "##################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-ruby.git
cd pmemkv-ruby
git checkout $RUBY_VERSION
mkdir -p vendor/cache/
cp -r /opt/bindings/ruby/* vendor/cache/
bundle install --local
bundle exec rspec

echo
echo "#################################################################"
echo "### Verifying building and installing of the pmemkv-jni bindings "
echo "#################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-jni.git
cd pmemkv-jni
git checkout $JNI_VERSION

make test
sudo_password -S make install prefix=$PREFIX

echo
echo "##################################################################"
echo "### Verifying building and installing of the pmemkv-java bindings "
echo "##################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-java.git
cd pmemkv-java
git checkout $JAVA_VERSION
mkdir -p ~/.m2/repository
cp -r /opt/bindings/java/repository ~/.m2/
mvn --offline install

echo
echo "####################################################################"
echo "### Verifying building and installing of the pmemkv-nodejs bindings "
echo "####################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-nodejs.git
cd pmemkv-nodejs
git checkout $NODEJS_VERSION
cp -r /opt/bindings/nodejs/node_modules .
npm install --save
npm test

echo
echo "####################################################################"
echo "### Verifying building and installing of the pmemkv-python bindings "
echo "####################################################################"
cd ~
git clone https://github.com/pmem/pmemkv-python.git
cd pmemkv-python
git checkout $PYTHON_VERSION
python3 setup.py install --user
cd tests
python3 -m unittest -v pmemkv_tests.py
cd ../examples
PMEM_IS_PMEM_FORCE=1 python3 basic_example.py
