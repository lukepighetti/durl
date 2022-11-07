# durl

A curl-like command-line client for Discord bot and user APIs.

## Features

- Bot auth flow
- User Oauth2 flow (redirects to `http://localhost:3000`)
- `get`, `post`, `put`, `patch`, `delete` requests
- JSON body
- JSON headers

## Requirements

- You must have Dart installed on your system
- You must have a Discord app created

A bot account is HIGHLY RECOMMENDED. User accounts are severely limited by
Discord's API and Terms of Service. That said, a full user Oauth2 flow is
implemented under `durl auth-user`

## Installation

```
dart pub global activate --source git https://github.com/lukepighetti/durl
durl auth
durl api -p /users/@me
durl api -X post -p "/channels/101503/messages" -b "{\"content\":\"hellooo!\"}"
durl api -X patch -p "/guilds/101429" -b "{\"icon\":\"data:image/jpeg;base64,$(base64 -i avatar.jpg)\"}"
```

## Tips

`durl` was built to make it easier to write shell scripts that control a
Discord server. `jq` is an amazing tool and it's absolutely essential in my
own work.

## Contributing

This project is intended to be *very simple*.