FROM node:20-bookworm-slim

ENV DEBIAN_FRONTEND="noninteractive" \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PIP_NO_CACHE_DIR=1

# hadolint ignore=DL3008,DL3013,DL4006
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
      dos2unix \
      novnc \
      python3-pip \
      tini \
      websockify \
      x11vnc \
      xvfb \
    && apt-get install --no-install-recommends -y \
      libasound2 \
      libatk1.0-0 \
      libcairo-gobject2 \
      libcairo2 \
      libdbus-glib-1-2 \
      libgdk-pixbuf-2.0-0 \
      libgtk-3-0 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libxcomposite1 \
      libxcursor1 \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf \
      /tmp/* \
      /usr/share/doc/* \
      /var/cache/* \
      /var/lib/apt/lists/* \
      /var/tmp/* \
    && ln -s /usr/share/novnc/vnc_auto.html /usr/share/novnc/index.html \
    && pip install apprise

WORKDIR /fgc
COPY package*.json ./

RUN npm install \
    && npx patchright install chrome

COPY . .

# Shell scripts need Linux line endings. On Windows, git might be configured to check out dos/CRLF line endings, so we convert them for those people in case they want to build the image. They could also use --config core.autocrlf=input
RUN dos2unix ./*.sh && chmod +x ./*.sh
COPY docker-entrypoint.sh /usr/local/bin/

ARG COMMIT=""
ARG BRANCH=""
ARG NOW=""
ENV COMMIT=${COMMIT}
ENV BRANCH=${BRANCH}
ENV NOW=${NOW}

LABEL org.opencontainers.image.title="free-games-claimer" \
      org.opencontainers.image.name="free-games-claimer" \
      org.opencontainers.image.description="Automatically claims free games on the Epic Games Store, Amazon Prime Gaming and GOG" \
  org.opencontainers.image.url="https://github.com/caycehouse/free-games-claimer" \
  org.opencontainers.image.source="https://github.com/caycehouse/free-games-claimer" \
      org.opencontainers.image.revision=${COMMIT} \
      org.opencontainers.image.ref.name=${BRANCH} \
      org.opencontainers.image.base.name="ubuntu:noble" \
      org.opencontainers.image.version="latest"

# Configure VNC via environment variables:
ENV VNC_PORT 5900
ENV NOVNC_PORT 6080
EXPOSE 5900
EXPOSE 6080

# Configure Xvfb via environment variables:
ENV WIDTH 1920
ENV HEIGHT 1080
ENV DEPTH 24

ENTRYPOINT ["docker-entrypoint.sh"]

CMD node epic-games; node prime-gaming; node gog
