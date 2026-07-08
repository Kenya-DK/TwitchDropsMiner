# ---- Builder Stage ----
FROM jlesage/baseimage-gui:alpine-3.18-v4.7 AS builder

RUN add-pkg \
    python3 \
    py3-pip \
    build-base \
    python3-dev \
    musl-dev \
    linux-headers \
    jpeg-dev \
    zlib-dev \
    freetype-dev \
    tk-dev \
    tcl-dev \
    python3-tkinter

WORKDIR /app
COPY . .

RUN python3 -m venv env && \
    . env/bin/activate && \
    pip install --upgrade pip wheel && \
    grep -v -E '^PyGObject' requirements.txt > req_filtered.txt && \
    pip install --no-cache-dir -r req_filtered.txt validators pyinstaller && \
    pyinstaller build.spec && \
    mv "/app/dist/Twitch Drops Miner (by DevilXD)" /app/dist/TwitchDropsMiner

# ---- Runtime Stage ----
FROM jlesage/baseimage-gui:alpine-3.18-v4.7

ENV LANG=en_US.UTF-8 \
    DARK_MODE=1 \
    KEEP_APP_RUNNING=1 \
    APP_ICON_URL=https://raw.githubusercontent.com/Davixk/TwitchDropsMiner/stable/appimage/pickaxe.png

RUN add-pkg \
    jpeg \
    zlib \
    freetype \
    tk \
    tcl \
    font-noto \
    font-noto-emoji \
    fontconfig \
    libx11 \
    libxrender

RUN mkdir -p /TwitchDropsMiner

COPY --from=builder /app/dist/TwitchDropsMiner /TwitchDropsMiner/TwitchDropsMiner

RUN mkdir -p /config /cache && \
    chmod -R 777 /TwitchDropsMiner && \
    chown -R 1000:1000 /TwitchDropsMiner /config /cache

COPY startapp.sh /startapp.sh
RUN chmod +x /startapp.sh

RUN install_app_icon.sh "$APP_ICON_URL"

RUN set-cont-env APP_NAME "Twitch Drops Miner" && \
    set-cont-env APP_VERSION "1.0"

EXPOSE 5800
