FROM --platform=${TARGETPLATFORM} debian:stable-slim AS ready
# FROM --platform=${TARGETPLATFORM} debian:sid-slim AS ready

ARG TARGETPLATFORM

ADD --chmod=777 caddy.sh /root/caddy.sh

# See https://github.com/caddyserver/caddy-docker for details
RUN set -ex \
	&& mkdir -p /config/caddy /data/caddy /etc/caddy /usr/share/caddy \
	&& install -d /config/caddy /data/caddy /etc/caddy /usr/share/caddy \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends ca-certificates curl wget libcap2-bin mailcap \
	&& /root/caddy.sh "${TARGETPLATFORM}" \
	&& rm -rfv /root/caddy.sh \
	&& apt-get remove --purge --auto-remove -y \
	&& apt-get purge -y --auto-remove \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& apt-get clean -y \
	&& rm -rfv /var/lib/apt/lists/*

FROM --platform=${TARGETPLATFORM} debian:stable-slim AS final
# FROM --platform=${TARGETPLATFORM} debian:sid-slim AS final

COPY --from=ready --chmod=755 /usr/bin/caddy /usr/bin/caddy

RUN set -eux; \
	apt-get update; \
	apt-get upgrade -y; \
	apt-get install -y --no-install-recommends bash ca-certificates tzdata; \
	apt-get remove --purge --auto-remove -y; \
	apt-get purge -y --auto-remove; \
	apt-get autoremove -y; \
	apt-get autoclean -y; \
	apt-get clean -y; \
	rm -rfv /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/catatonit", "--", "/root/entrypoint.sh"]
# ENTRYPOINT ["/usr/bin/dumb-init", "--", "/root/entrypoint.sh"]
# ENTRYPOINT ["/sbin/tini", "--", "/root/entrypoint.sh"]
