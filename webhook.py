from __future__ import annotations

import asyncio
import logging
from typing import TYPE_CHECKING

import aiohttp

if TYPE_CHECKING:
    from settings import Settings


logger = logging.getLogger("TwitchDrops")


class WebhookLogger:
    # Discord embed colors (decimal values)
    COLOR_INFO = 0x9146FF  # Twitch purple
    COLOR_SUCCESS = 0x57F287  # green
    COLOR_WARNING = 0xFEE75C  # yellow

    def __init__(self, settings: Settings):
        self.settings: Settings = settings
        self._tasks: set[asyncio.Task[bool]] = set()

    @property
    def enabled(self) -> bool:
        webhook_url = self.settings.webhook_url
        return bool(self.settings.webhook_enabled and webhook_url and webhook_url.host is not None)

    def notify(self, title: str, description: str = "", *, color: int = COLOR_INFO) -> None:
        """
        Fire-and-forget wrapper around the async send method.
        This never blocks and silently ignores failures.
        """
        if not self.enabled:
            return
        task = asyncio.create_task(self.send(title, description, color=color))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def send(self, title: str, description: str = "", *, color: int = COLOR_INFO) -> bool:
        if not self.enabled:
            return False
        webhook_url = self.settings.webhook_url
        payload = {
            "embeds": [
                {
                    "title": title,
                    "description": description,
                    "color": color,
                    "footer": {"text": "Twitch Drops Miner"},
                }
            ]
        }
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(webhook_url, json=payload) as response:
                    # Discord webhooks respond 204 No Content on success
                    return response.status == 204
        except Exception as exc:
            # never let webhook failures affect the app
            logger.warning(f"Failed to send Discord webhook: {exc}")
            return False