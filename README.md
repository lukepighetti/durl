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

```bash
dart pub global activate --source git https://github.com/lukepighetti/durl
durl auth
```

## Examples

```bash
# Fetch my user info with a GET request
durl api -p /users/@me

# Send message with a POST request
durl api -X post -p "/channels/101503/messages" -b "{\"content\":\"hellooo!\"}"

# Update guild icon with base64 image in a PATCH request
durl api -X patch -p "/guilds/101429" -b "{\"icon\":\"data:image/jpeg;base64,$(base64 -i avatar.jpg)\"}"
```

## Tips

`durl` was built to make it easier to write shell scripts that control a
Discord server. `jq` is an amazing tool and it's absolutely essential in my
own work.

## Contributing

This project is intended to be *very simple*, that said, here are some missing
features:

1. Support for operating systems that don't use *nix style paths.
See [durl.dart:13](https://github.com/lukepighetti/durl/blob/main/bin/durl.dart#L13-L16)
2. Automatically refresh the user token when it expires.
See [durl.dart:195](https://github.com/lukepighetti/durl/blob/main/bin/durl.dart#L195-L225)