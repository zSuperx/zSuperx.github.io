---
title: Tiktok Discord Bot
---

[Project Link](https://github.com/zSuperx/tiktok-bot)

Tiktok and Discord don't mesh well together. Unlike Youtube, which allows for
playing videos in-app on Discord, Tiktok links get automatically converted to
**images of the thumbnail**. This means that in order to view Tiktok links your
friends send you on Discord, you necessarily have to open a new window to go to
the source site.

What's worse, mobile Discord links often end up opening a "browser within
Discord". But instead of letting you view the link there, Tiktok's website
mobile-detection kicks in and prompts you to download the TikTok app! And the
cherry on top is that _even if you have the app_, you're sent to the App Store.

Well, I got tired of this and decided to write a Discord bot that automatically
fetches the TikTok video and uploads it as playable media _as a Discord
message_. No more popups, external links, or redirects! All you need to do is
send a message whose content is **only a TikTok link**, and the bot will detect
and replace it with a playable media message!

## Todo

1. Reconfigure the caching mechanism to detect if Discord has removed the media
   link from their internal database
2. Add `<` and `>` around the TikTok link, which should disable Discord's
   automatic embed
3. Look into APIs or `curl` + HTML parsing to extract basic info like
   - Video author
   - Likes
   - Views
