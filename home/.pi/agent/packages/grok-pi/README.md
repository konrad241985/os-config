# grok-pi (local patch)

This is [grok-pi 1.5.0](https://github.com/luongnv89/pi-extensions/tree/main/extensions/grok-pi) with one fix. Pi now folds the system prompt and tool list into a system message whose `content` is a string. The published serializer called `.map` on that string and crashed with `message.content.map is not a function` on every Grok turn.

The patched `buildPrompt` replays system messages into the system-prompt and tool sections, and it skips those messages in the transcript. npm has no release newer than 1.5.0.

Pi loads this directory from `packages/grok-pi` in `settings.json`. It is not published.

Original work is MIT, copyright pi-extensions contributors. See `LICENSE`.
