#!/bin/bash
if grep -q "release 7" /etc/redhat-release 2>/dev/null && [ "$(uname -m)" = "x86_64" ]; then
# ============================================================================
# Upgrade python
# ============================================================================
yum -y remove python36 python36-pip python36-devel python3 python3-pip python3-devel
yum -y install yum-plugin-copr
yum -y copr enable adrienverge/python37
yum -y install python37 python37-devel python37-pip
python3 --version
# ============================================================================
# Upgrade git
# ============================================================================
yum -y remove git
yum -y install https://packages.endpointdev.com/rhel/7/os/x86_64/endpoint-repo.x86_64.rpm
yum -y install git
# ============================================================================
# Upgrade CMake to 4.4.0 
# ============================================================================
curl -sLo cmake3.tar.gz https://github.com/Kitware/CMake/releases/download/v4.4.0/cmake-4.4.0-linux-x86_64.tar.gz
tar -xzf cmake3.tar.gz
mv cmake-4.4.0-linux-x86_64 /opt/cmake
rm -f /usr/bin/cmake
ln -sf /opt/cmake/bin/cmake /usr/bin/cmake

# 判断 gcc-indiff 文件是否存在
if [ -f /opt/gcc-indiff/bin/gcc ]; then
    CC=/opt/gcc-indiff/bin/gcc
    CXX=/opt/gcc-indiff/bin/g++
	if [ -f /opt/gcc-indiff/lib/libzstd.so.1.5.8 ]; then
		rm -f /opt/gcc-indiff/lib/libzstd.so
		rm -f /opt/gcc-indiff/lib/libzstd.so.1
		ln -sf /opt/gcc-indiff/lib/libzstd.so.1.5.8 /opt/gcc-indiff/lib/libzstd.so
		ln -sf /opt/gcc-indiff/lib/libzstd.so.1.5.8 /opt/gcc-indiff/lib/libzstd.so.1
		ldconfig /opt/gcc-indiff/lib
	fi
    echo "version.h not found"
fi

git clone --filter=blob:none --depth 1 https://github.com/microsoft/vcpkg.git /opt/vcpkg
/opt/vcpkg/bootstrap-vcpkg.sh
export VCPKG_ROOT=/opt/vcpkg
export PATH=/opt/gcc-indiff/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LD_LIBRARY_PATH=/opt/gcc-indiff/lib64:/opt/gcc-indiff/lib
export TRIPLET=x64-linux
export CC="/opt/gcc-indiff/bin/gcc"
export CXX="/opt/gcc-indiff/bin/g++"
export ACLOCAL_PATH=/usr/share/aclocal:${ACLOCAL_PATH:-}
# 克隆官方仓库（或镜像）
git clone https://github.com/autotools-mirror/autoconf.git
cd autoconf
./bootstrap     # 如果存在
./configure --prefix=/usr
make -j$(nproc)
make install
cd ..

function wget_gnu(){
     local suffix=$1
     wget https://ftp.gnu.org/gnu/$suffix || wget https://mirrors.aliyun.com/gnu/$suffix || wget http://mirrors.tencent.com/gnu/$suffix
}

pkg-config --version || true
wget https://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
tar xzf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
./configure --prefix=/usr --with-internal-glib
make CFLAGS="-Ubool -std=gnu11 -O2" -j$(nproc)
make install
pkg-config --version
cd ..

# insatll automake
# git clone --depth=1 https://github.com/autotools-mirror/automake.git
# wget https://ftp.gnu.org/gnu/automake/automake-1.18.1.tar.gz
wget_gnu automake/automake-1.18.1.tar.gz
tar -xzf automake-1.18.1.tar.gz
cd automake-1.18.1
./bootstrap     # 如果存在
./configure --prefix=/usr
make -j$(nproc)
make install
cd ..


# insatll libtool
# git clone --depth=1 https://https.git.savannah.gnu.org/git/libtool.git
# wget http://mirrors.tencent.com/gnu/libtool/libtool-2.5.4.tar.gz
wget_gnu libtool/libtool-2.6.2.tar.gz
tar -xzf libtool-2.6.2.tar.gz
cd libtool-2.6.2
./bootstrap  --force     # 如果存在
./configure --prefix=/usr
make -j$(nproc)
make install
cd ..

# wget https://ftp.gnu.org/gnu/m4/m4-1.4.20.tar.gz
wget_gnu m4/m4-latest.tar.gz
tar -xzf m4-latest.tar.gz
cd m4-*
env CC=/opt/gcc-indiff/bin/gcc CFLAGS="-I/opt/gcc-indiff/include " \
./configure --prefix=/usr
make -j$(nproc)
make install
cd ..
m4 --version

CC=/opt/gcc-indiff/bin/gcc CXX=/opt/gcc-indiff/bin/g++ $VCPKG_ROOT/vcpkg install \
            libice libsm libx11 libxt zlib libedit \
            --triplet x64-linux-dynamic --clean-after-build \
            || cat /workspace/vcpkg/installed/vcpkg/issue_body.md
fi

