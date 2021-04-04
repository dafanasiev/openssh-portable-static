#!/usr/bin/env bash

set -uex
umask 0077

ZLIB_VERSION=1.2.11
OPENSSL_VERSION=1.1.1k
OPENSSH_VERSION=V_8_5_P1

prefix="/opt/openssh"
top="$(pwd)"
root="$top/root"
build="$top/build"
dist="$top/dist"

export CPPFLAGS="-I$root/include -L. -fPIC"
export CFLAGS="-I$root/include -L. -fPIC"
export LDFLAGS="-L$root/lib"

rm -rf "$root" "$build" "$dist"
mkdir -p "$root" "$build" "$dist"

curl --output $dist/zlib-$ZLIB_VERSION.tar.gz --location https://zlib.net/zlib-$ZLIB_VERSION.tar.gz
gzip -dc $dist/zlib-*.tar.gz |(cd "$build" && tar xf -)
cd "$build"/zlib-*
./configure --prefix="$root" --static
make
make install
cd "$top"

curl --output $dist/openssl-$OPENSSL_VERSION.tar.gz --location https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
gzip -dc $dist/openssl-*.tar.gz |(cd "$build" && tar xf -)
cd "$build"/openssl-*
./config --prefix="$root" no-shared
make
make install
cd "$top"

curl --output $dist/openssh-$OPENSSH_VERSION.tar.gz --location https://github.com/openssh/openssh-portable/archive/refs/tags/$OPENSSH_VERSION.tar.gz
gzip -dc $dist/openssh-*.tar.gz |(cd "$build" && tar xf -)
cd "$build"/openssh-*
cp -p "$root"/lib/*.a .
[ -f sshd_config.orig ] || cp -p sshd_config sshd_config.orig
sed \
  -e 's/^#\(PubkeyAuthentication\) .*/\1 yes/' \
  -e '/^# *Kerberos/d' \
  -e '/^# *GSSAPI/d' \
  -e 's/^#\([A-Za-z]*Authentication\) .*/\1 no/' \
  sshd_config.orig \
  >sshd_config \
;
autoreconf
./configure --enable-static LIBS="-lpthread" --prefix="$root" --with-privsep-user=nobody --with-privsep-path="$prefix/var/empty"
make
#make install
cd "$top"
