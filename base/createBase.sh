#!/usr/bin/env bash
#
# Create a base CentOS Docker image.
#
# This script is useful on systems with yum installed (e.g., building
# a CentOS image on CentOS).  See contrib/mkimage-rinse.sh for a way
# to build CentOS images on other systems.

usage() {
    cat <<EOOPTS
$(basename $0) [OPTIONS] <name>
OPTIONS:
  -y <yumconf>  The path to the yum config to install packages from. The
                default is /etc/yum.conf.
EOOPTS
    exit 1
}

# option defaults
export PATH=$HOME/docker-1.8.2-rhel7.1-20150929:$PATH
yum_config=/etc/yum.conf
while getopts ":y:h" opt; do
    case $opt in
        y)
            yum_config=$OPTARG
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            usage
            ;;
    esac
done
shift $((OPTIND - 1))
name=$1

if [[ -z $name ]]; then
    usage
fi

#--------------------

set -x

export TMPDIR=/var/tmp
target=$(mktemp -d --tmpdir $(basename $0).XXXXXX)

mkdir -m 755 "$target"/dev
mknod -m 600 "$target"/dev/console c 5 1
mknod -m 600 "$target"/dev/initctl p
mknod -m 666 "$target"/dev/full c 1 7
mknod -m 666 "$target"/dev/null c 1 3
mknod -m 666 "$target"/dev/ptmx c 5 2
mknod -m 666 "$target"/dev/random c 1 8
mknod -m 666 "$target"/dev/tty c 5 0
mknod -m 666 "$target"/dev/tty0 c 4 0
mknod -m 666 "$target"/dev/urandom c 1 9
mknod -m 666 "$target"/dev/zero c 1 5

# amazon linux yum will fail without vars set
if [ -d /etc/yum/vars ]; then
	mkdir -p -m 755 "$target"/etc/yum
	cp -a /etc/yum/vars "$target"/etc/yum/
fi

yum -c "$yum_config" --installroot="$target" --releasever=/ --setopt=tsflags=nodocs \
    --setopt=group_package_types=mandatory -y install \
    centos-release \
    ncurses-base filesystem nss-softokn-freebl glibc libstdc++ bash pcre zlib libdb bzip2-libs popt libacl libgpg-error lua audit-libs sqlite libcom_err nss-softokn libassuan sed libxml2 keyutils-libs glib2 pinentry cyrus-sasl-lib diffutils libidn gmp gdbm ustr dbus-libs p11-kit-trust libcap-ng libssh2 openssl-libs curl cracklib rpm-libs systemd-libs rpm nss-tools coreutils openldap nss-sysinit libutempter python-libs gnupg2 pygpgme rpm-python python-pycurl python-iniparse pyxattr vim-minimal libgcc tzdata setup basesystem glibc-common xz-libs ncurses-libs libsepol libselinux info nspr nss-util libattr libcap readline libffi elfutils-libelf chkconfig \
     libuuid p11-kit libgcrypt grep file-libs pkgconfig shared-mime-info libdb-utils gawk cpio ncurses pth expat libsemanage libtasn1 ca-certificates libverto krb5-libs libcurl gzip cracklib-dicts libmount libpwquality libuser nss pam libblkid shadow-utils util-linux python gpgme rpm-build-libs yum-metadata-parser python-urlgrabber pyliblzma yum
yum -c "$yum_config" --installroot="$target" clean all

cat > "$target"/etc/sysconfig/network <<EOF
NETWORKING=yes
HOSTNAME=localhost.localdomain
EOF

# effectively: febootstrap-minimize --keep-zoneinfo --keep-rpmdb
# --keep-services "$target".  Stolen from mkimage-rinse.sh
#  locales
rm -rf "$target"/usr/{{lib,share}/locale,{lib,lib64}/gconv,bin/localedef,sbin/build-locale-archive}
#  docs
rm -rf "$target"/usr/share/{man,doc,info,gnome/help}
#  cracklib
rm -rf "$target"/usr/share/cracklib
#  i18n
rm -rf "$target"/usr/share/i18n
#  sln
rm -rf "$target"/sbin/sln
#  ldconfig
rm -rf "$target"/etc/ld.so.cache
rm -rf "$target"/var/cache/ldconfig/*

version=
for file in "$target"/etc/{redhat,system,clefos,centos}-release
do
    if [ -r "$file" ]; then
        version="$(sed 's/^[^0-9\]*\([0-9.]\+\).*$/\1/' "$file")"
        break
    fi
done

if [ -z "$version" ]; then
    echo >&2 "warning: cannot autodetect OS version, using '$name' as tag"
    version=$name
fi

tar --numeric-owner -c -C "$target" . | docker import - $name:$version
docker run -i -t $name:$version echo success

rm -rf "$target"