// ignore_for_file: annotate_overrides, avoid_single_cascade_in_expression_statements

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:http/http.dart' as http;

final appDir = Directory("${Platform.environment['HOME']}/.config/durl");
final botTokenFile = File("${appDir.path}/bot-token.json");
final clientFile = File("${appDir.path}/client.json");
final tokenFile = File("${appDir.path}/token.json");

void main(List<String> args) {
  CommandRunner(
    "durl",
    "A curl-like authenticated REST client pointed at Discord's API",
  )
    ..addCommand(AuthUserCommand())
    ..addCommand(AuthBotCommand())
    ..addCommand(TokenRefreshCommand())
    ..addCommand(ApiCommand())
    ..run(args);
}

class ApiCommand extends Command {
  final name = "api";
  final description = "Dispatch an API request";

  ApiCommand() {
    argParser
      ..addOption(
        "method",
        abbr: "X",
        defaultsTo: "get",
        allowed: ["get", "post", "put", "patch", "delete"],
      )
      ..addOption(
        "type",
        abbr: "y",
        defaultsTo: "bot",
        allowed: ["bot", "user"],
      )
      ..addFlag("silent", defaultsTo: false, help: "Suppress STDOUT")
      ..addOption("path", abbr: "p", mandatory: true)
      ..addOption("version", abbr: "v", defaultsTo: "10")
      ..addOption("headers", abbr: "H", defaultsTo: "{}", help: "JSON encoded")
      ..addOption("body", abbr: "b", defaultsTo: "");
  }

  @override
  Future<void> run() async {
    final method = argResults?["method"] as String;
    final path = argResults?["path"] as String;
    final version = argResults?["version"] as String;
    final body = argResults?["body"] as String;
    final useBotToken = argResults?["type"] == "bot";

    final uri = Uri.parse("https://discord.com/api" "/v$version" "/$path");
    final token = useBotToken
        ? botTokenFile.readAsStringSync()
        : jsonDecode(tokenFile.readAsStringSync())['access_token'];
    final headers = <String, String>{
      if (useBotToken)
        "Authorization": "Bot $token"
      else
        "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      ...jsonDecode(argResults?["headers"]),
    };

    late final http.Response res;
    switch (method.toLowerCase()) {
      case "get":
        res = await http.get(uri, headers: headers);
        break;
      case "post":
        res = await http.post(uri, body: body, headers: headers);
        break;
      case "put":
        res = await http.put(uri, body: body, headers: headers);
        break;
      case "patch":
        res = await http.patch(uri, body: body, headers: headers);
        break;
      case "delete":
        res = await http.delete(uri, body: body, headers: headers);
        break;
    }

    if (!argResults?['silent']) print(res.body);
  }
}

class AuthUserCommand extends Command {
  final name = "auth-user";
  final description = "Authenticate user via Oauth";

  AuthUserCommand() {
    argParser
      ..addOption("client_id", abbr: "i", mandatory: true)
      ..addOption("client_secret", abbr: "s", mandatory: true)
      ..addOption("scope", defaultsTo: "identify messages.read");
  }

  @override
  Future<void> run() async {
    // Ask the user to follow a link to request an auth code redirect
    final url = Uri.parse(
      "https://discord.com/api/oauth2/authorize"
      "?client_id=${argResults?['client_id']}"
      "&redirect_uri=http://localhost:3000"
      "&response_type=code"
      "&scope=${argResults?['scope']}",
    );

    print("Authenticate by clicking this link $url");

    // Setup webserver to receive auth code
    final codeCompleter = Completer<String>();
    final server = await serve((Request req) {
      codeCompleter.complete(req.requestedUri.queryParameters["code"]);
      return Response.ok("Success! You can close this browser");
    }, "localhost", 3000);
    final code = await codeCompleter.future;
    server.close();
    print("Received auth code from redirect");

    // Trade offer: I receive auth token, Discord receives code
    final res = await http.post(
      Uri.parse(
        "https://discord.com/api/v10/oauth2/token",
      ),
      body: {
        "client_id": argResults?["client_id"],
        "client_secret": argResults?["client_secret"],
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": "http://localhost:3000",
      },
    );

    // Ensure that we received a refresh token, save it
    if (!res.body.contains("refresh_token")) {
      print("Did not receive a refresh token. res.body: ${res.body}");
      return;
    }
    if (!tokenFile.existsSync()) tokenFile.createSync(recursive: true);
    tokenFile.writeAsStringSync(res.body);
    print("Received auth token");

    // Save the client id and secret for later use
    if (!clientFile.existsSync()) clientFile.createSync(recursive: true);
    clientFile.writeAsStringSync(jsonEncode({
      "client_id": argResults?["client_id"],
      "client_secret": argResults?["client_secret"],
    }));
  }
}

class AuthBotCommand extends Command {
  final name = "auth";
  final description = "Authenticate bot via Oauth";

  AuthBotCommand() {
    argParser
      ..addOption("client_id", abbr: "i", mandatory: true)
      ..addOption("bot_token", abbr: "t", mandatory: true)
      ..addOption("permissions", abbr: "p", defaultsTo: "8")
      ..addOption("scope", defaultsTo: "bot");
  }

  @override
  Future<void> run() async {
    // Ask the user to follow a link to request an auth code redirect
    final url = Uri.parse(
      "https://discord.com/api/oauth2/authorize"
      "?client_id=${argResults?['client_id']}"
      "&permissions=${argResults?['permissions']}"
      "&scope=${argResults?['scope']}",
    );

    print("Authenticate by clicking this link $url");

    // Save the bot token
    if (!botTokenFile.existsSync()) botTokenFile.createSync();
    botTokenFile.writeAsStringSync(argResults?["bot_token"]);
  }
}

class TokenRefreshCommand extends Command {
  final name = "token-refresh";
  final description = "Refresh the auth token on file";

  Future<void> run() async {
    final clientInfo = jsonDecode(clientFile.readAsStringSync());
    final token = jsonDecode(tokenFile.readAsStringSync());

    // Trade offer: I receive auth token, Discord receives refresh token
    final res = await http.post(
      Uri.parse(
        "https://discord.com/api/v10/oauth2/token",
      ),
      body: {
        "client_id": clientInfo["client_id"],
        "client_secret": clientInfo["client_secret"],
        "grant_type": "refresh_token",
        "refresh_token": token["refresh_token"],
      },
    );

    // Ensure that we received a refresh token, save it
    if (!res.body.contains("refresh_token")) {
      print("Did not receive a refresh token. res.body: ${res.body}");
      return;
    }
    if (!tokenFile.existsSync()) tokenFile.createSync(recursive: true);
    tokenFile.writeAsStringSync(res.body);
    print("Refreshed auth token");
  }
}
