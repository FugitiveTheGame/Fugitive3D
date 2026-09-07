# Fugitive 3D dedicated server.
#
# Published on every release as ghcr.io/fugitivethegame/fugitive3d-server
# (tags X.Y.Z and latest), so most people never build this:
#
#   docker run -d --name fugitive3d -p 31000:31000/udp \
#     -e SERVER_NAME="My Server" ghcr.io/fugitivethegame/fugitive3d-server:latest
#
# To build it yourself, VERSION is a release tag; the Linux server build is
# taken from that GitHub release:
#
#   docker build --build-arg VERSION=0.8.0 -t fugitive3d-server docker/

ARG VERSION

FROM ubuntu:24.04 AS fetch
ARG VERSION
RUN test -n "$VERSION" || { echo "VERSION build-arg is required, e.g. --build-arg VERSION=0.8.0" >&2; exit 1; }
RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates curl unzip \
	&& rm -rf /var/lib/apt/lists/*
RUN curl -fsSL --retry 5 --retry-delay 15 --retry-all-errors -o /tmp/server.zip \
		"https://github.com/FugitiveTheGame/Fugitive3D/releases/download/${VERSION}/Fugitive3D_Server_Linux_${VERSION}.zip" \
	&& mkdir -p /server \
	&& unzip -q /tmp/server.zip -d /server \
	&& chmod 755 /server/Fugitive3D_Server_Linux.x86_64 \
	&& rm /tmp/server.zip

FROM ubuntu:24.04
ARG VERSION
LABEL org.opencontainers.image.source="https://github.com/FugitiveTheGame/Fugitive3D" \
	org.opencontainers.image.description="Fugitive 3D dedicated game server" \
	org.opencontainers.image.version="${VERSION}"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates \
	&& rm -rf /var/lib/apt/lists/* \
	&& useradd --system --uid 1001 --create-home --home-dir /home/fugitive --shell /usr/sbin/nologin fugitive \
	&& mkdir -p /data \
	&& chown fugitive:fugitive /data

COPY --from=fetch /server /opt/fugitive3d
COPY --chmod=755 entrypoint.sh /usr/local/bin/fugitive3d-server

# Godot derives user:// from XDG_DATA_HOME; the server keeps its identity
# (SERVER_ID) there, so /data is the one thing worth persisting.
ENV SERVER_NAME="Fugitive 3D Server" \
	SERVER_PORT=31000 \
	SERVER_FLAGS="" \
	HOME=/data \
	XDG_DATA_HOME=/data

VOLUME ["/data"]
EXPOSE 31000/udp
USER fugitive
WORKDIR /opt/fugitive3d
ENTRYPOINT ["/usr/local/bin/fugitive3d-server"]
