#!/bin/sh
#
echo "Run"

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
    # ARCH="x86_64-unknown-linux-gnu"
    ARCH="x86_64-unknown-linux-musl"
else
    case "${PLATFORM}" in
        linux/386)
            # ARCH="i686-unknown-linux-gnu"
            ARCH="i686-unknown-linux-musl"
            ;;
        linux/amd64)
            # ARCH="x86_64-unknown-linux-gnu"
            ARCH="x86_64-unknown-linux-musl"
            ;;
        linux/arm/v5)
            # ARCH="armv5te-unknown-linux-gnueabi"
            ARCH="armv5te-unknown-linux-musleabi"
            ;;
        linux/arm/v6)
            # ARCH="arm-unknown-linux-gnueabi"
            # ARCH="arm-unknown-linux-musleabi"
            # ARCH="arm-unknown-linux-gnueabihf"
            ARCH="arm-unknown-linux-musleabihf"
            ;;
        linux/arm/v7)
            # ARCH="armv7-unknown-linux-gnueabi"
            # ARCH="armv7-unknown-linux-musleabi"
            # ARCH="armv7-unknown-linux-gnueabihf"
            ARCH="armv7-unknown-linux-musleabihf"
            ;;
        linux/arm64|linux/arm64/v8)
            # ARCH="aarch64-unknown-linux-gnu"
            ARCH="aarch64-unknown-linux-musl"
            ;;
        linux/mips64le)
            # ARCH="mips64el-unknown-linux-gnuabi64"
            ARCH="mips64el-unknown-linux-muslabi64"
            ;;
        linux/ppc64le)
            ARCH="powerpc64le-unknown-linux-gnu"
            # ARCH="powerpc64le-unknown-linux-musl"
            ;;
        linux/riscv64)
            ARCH="riscv64gc-unknown-linux-gnu"
            # ARCH="riscv64gc-unknown-linux-musl"
            ;;
        linux/s390x)
            ARCH="s390x-unknown-linux-gnu"
            # ARCH="s390x-unknown-linux-musl"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1

TARGET_FILE="phantun-${ARCH}.tar.gz"
DIR_TMP="$(mktemp -d)"

echo "Downloading archive file: ${TARGET_FILE}"

curl -LJR -o ${DIR_TMP}/phantun.tar.gz https://github.com/darkommoers/learngithubactionsdemo1/releases/download/phantun/${TARGET_FILE} > /dev/null 2>&1

# wget -O ${DIR_TMP}/phantun.tar.gz https://github.com/darkommoers/learngithubactionsdemo1/releases/download/phantun/${TARGET_FILE} > /dev/null 2>&1

if [ ! -e "${DIR_TMP}/phantun.tar.gz" ]; then echo "Error: Failed to download archive file: ${TARGET_FILE}" && exit 1; else echo "Download archive file: ${TARGET_FILE} completed" ;fi
if [ ! -f "${DIR_TMP}/phantun.tar.gz" ]; then echo "Error: Failed to download archive file: ${TARGET_FILE}" && exit 1; else echo "Download archive file: ${TARGET_FILE} completed" ;fi

echo "Extract the archive contents"
tar -xzf ${DIR_TMP}/phantun.tar.gz -C ${DIR_TMP}
cp -fr ${DIR_TMP}/phantun_server /usr/bin/phantun_server
cp -fr ${DIR_TMP}/phantun_client /usr/bin/phantun_client
rm -rfv ${DIR_TMP}
phantun_server --version
phantun_client --version
setcap 'cap_sys_admin,cap_net_admin,cap_net_bind_service=+ep' /usr/bin/phantun_server
setcap 'cap_sys_admin,cap_net_admin,cap_net_bind_service=+ep' /usr/bin/phantun_client
getcap /usr/bin/phantun_server
getcap /usr/bin/phantun_client
chmod +x /usr/bin/phantun_server
chmod +x /usr/bin/phantun_client
echo "End"
