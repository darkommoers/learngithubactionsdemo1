#!/bin/sh
#
echo "Run"

PLATFORM=$1
if [ -z "$PLATFORM" ]; then
    ARCH="amd64"
else
    case "${PLATFORM}" in
        linux/386)
            ARCH="386"
            ;;
        linux/amd64)
            ARCH="amd64"
            ;;
        linux/arm/v5)
            ARCH="arm5"
            ;;
        linux/arm/v6)
            ARCH="arm6"
            ;;
        linux/arm/v7)
            ARCH="arm7"
            ;;
        linux/arm64|linux/arm64/v8)
            ARCH="arm64"
            ;;
        linux/mips64le)
            ARCH="mips64le"
            ;;
        linux/ppc64le)
            ARCH="ppc64le"
            ;;
        linux/riscv64)
            ARCH="riscv64"
            ;;
        linux/s390x)
            ARCH="s390x"
            ;;
        *)
            ARCH=""
            ;;
    esac
fi
[ -z "${ARCH}" ] && echo "Error: Not supported OS Architecture" && exit 1

TARGET_FILE="phantun-linux-${ARCH}.tar.gz"
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
