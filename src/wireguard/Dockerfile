FROM --platform=${TARGETPLATFORM} alpine:latest AS final
# FROM --platform=${TARGETPLATFORM} alpine:edge AS final

ARG TARGETPLATFORM

WORKDIR /root

ADD --chmod=777 wireguard.sh /root/entrypoint.sh

RUN set -ex \
	&& apk add --no-cache bash ca-certificates wireguard-tools nftables iproute2 openresolv grep tzdata dumb-init tini catatonit \
	&& rm -rfv /var/cache/apk/*

VOLUME ["/etc/wireguard"]

ENTRYPOINT ["/usr/bin/catatonit", "--"]
# ENTRYPOINT ["/usr/bin/dumb-init", "--"]
# ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/root/entrypoint.sh"]
