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
- You must have a [Discord app](https://discord.com/developers/applications)

A bot account is HIGHLY RECOMMENDED. User accounts are severely limited by
Discord's API and Terms of Service. That said, a full user Oauth2 flow is
implemented under `durl auth-user`

## Installation

```bash
dart pub global activate --source git https://github.com/lukepighetti/durl
durl auth -i $APPLICATION_ID -t $BOT_TOKEN
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

Use `jq` to parse response objects when using `durl` to write shell scripts.

```bash
# Fetch the authenticated user id and store it
USER_ID=$(durl api -p /users/@me | jq -r ".id")
```

## Contributing

This project is intended to be *very simple*, that said, here are some missing
features:

1. Support for operating systems that don't use *nix style paths.
See [durl.dart:11](https://github.com/lukepighetti/durl/blob/main/bin/durl.dart#L11-L14)
2. Automatically refresh the user token when it expires.
See [durl.dart:202](https://github.com/lukepighetti/durl/blob/main/bin/durl.dart#L202-L236)