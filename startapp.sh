#!/bin/sh
chown -R app:app /TwitchDropsMiner/cache /TwitchDropsMiner/config
cd /TwitchDropsMiner
exec ./TwitchDropsMiner
