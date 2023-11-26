FROM --platform=${TARGETPLATFORM} debian:stable-slim AS ready
# FROM --platform=${TARGETPLATFORM} debian:sid-slim AS ready

ARG TARGETPLATFORM

ADD --chmod=777 phantun.sh /usr/local/bin/

# See https://github.com/dndx/phantun/tree/main/docker for details
RUN set -ex \
	&& apt-get update \
	&& apt-get upgrade -y \
	&& apt-get install -y --no-install-recommends ca-certificates curl wget libcap2-bin mailcap \
	&& phantun.sh "${TARGETPLATFORM}" \
	&& rm -rfv /usr/local/bin/phantun.sh \
	&& apt-get remove --purge --auto-remove -y \
	&& apt-get purge -y --auto-remove \
	&& apt-get autoremove -y \
	&& apt-get autoclean -y \
	&& apt-get clean -y \
	&& rm -rfv /var/lib/apt/lists/*

FROM --platform=${TARGETPLATFORM} debian:stable-slim AS final
# FROM --platform=${TARGETPLATFORM} debian:sid-slim AS final

ADD --chmod=777 docker-entrypoint.sh /usr/local/bin/
COPY --from=ready --chmod=755 /usr/bin/phantun_server /usr/bin/phantun_server
COPY --from=ready --chmod=755 /usr/bin/phantun_client /usr/bin/phantun_client

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

ENTRYPOINT ["/usr/bin/catatonit", "--", "docker-entrypoint.sh"]
# ENTRYPOINT ["/usr/bin/dumb-init", "--", "docker-entrypoint.sh"]
# ENTRYPOINT ["/sbin/tini", "--", "docker-entrypoint.sh"]
