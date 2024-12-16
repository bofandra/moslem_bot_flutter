import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';

var moslemBotBe = "moslem-bot-be";
var histories = [
  {"source": "remote", "type": moslemBotBe, "question": "bla bla", "answer": []}
];

void main() {
  initializeDateFormatting().then((_) => runApp(const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application name
      title: 'Moslem Bot',
      // Application theme data, you can set the colors for the application as
      // you want
      theme: ThemeData(
        // useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      // A widget which will be started on application startup
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: ChatPage(),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late Future<List> futureQuranFinder;
  late Future<List> futureHadithsFinder;
  late Future<List> futureBotFinder;
  List<types.Message> _messages = [];
  final _user = const types.User(
    id: '82091008-a484-4a89-ae75-a22bf8d6f3ac',
  );
  final _userBot = const types.User(
      id: '82091008-a484-4a89-ae75-a22bf8d6f3aX',
      imageUrl: "assets/icon/icon.png");

  @override
  void initState() {
    super.initState();
  }

  void _addMessage(types.Message message) {
    print("di sini!!!!");
    print(message);
    setState(() {
      _messages.insert(0, message);
    });
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {}

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = _messages.indexWhere((element) => element.id == message.id);
    final updatedMessage = (_messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      _messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);

    futureQuranFinder = fetchQuranFinder(moslemBotBe, message.text);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Chat(
          messages: _messages,
          onMessageTap: _handleMessageTap,
          onPreviewDataFetched: _handlePreviewDataFetched,
          onSendPressed: _handleSendPressed,
          showUserAvatars: true,
          showUserNames: true,
          user: _user,
        ),
      );

  Future<List> fetchQuranFinder(String feature, String query) async {
    if (query.length < 3) {
      return [
        ['Query is empty']
      ];
    }

    const int timeout = 30;
    var get_url = 'https://bofandra-' + feature + '.hf.space/call/predict';
    print(get_url);

    Map get_data = {
      'data': [query]
    };

    if (feature == moslemBotBe) {
      get_data = {
        'data': [query, 2048, 0.7, 0.95]
      };
    }
    //encode Map to JSON
    var body = json.encode(get_data);

    var response = await http.post(Uri.parse(get_url),
        headers: {
          "Content-Type": "application/json",
          'charset': 'UTF-8',
          'Authorization': 'Bearer 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'
        },
        body: body);
    String event_id = json.decode(response.body)["event_id"];

    print(event_id);

    final textMessageBot = types.TextMessage(
      author: _userBot,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: event_id,
      text: "Please, wait for the bot to process the response..",
    );

    _addMessage(textMessageBot);
    final url = Uri.parse(
        'https://bofandra-' + feature + '.hf.space/call/predict/' + event_id);
    final client = http.Client();
    var data = [];
    print("cek");
    print(url);
    try {
      final request = http.Request('GET', url);
      request.headers['Authorization'] =
          "Bearer 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";

      var response = await client.send(request);

      // Read and print the chunks from the response stream
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        print("?????????????????????");
        // Process each chunk as it is received
        if (chunk.contains("data")) {
          print("here");
          chunk = chunk.replaceAll("event: heartbeat", "");
          chunk = chunk.replaceAll("event: complete", "");
          chunk = chunk.replaceAll("event: error", "");
          chunk = chunk.replaceAll("event: generating", "");
          chunk = chunk.replaceAll("data: ", "");
          chunk = chunk.replaceAll(", [NaN]", "");
          chunk = chunk.replaceAll("[NaN], ", "");
          chunk = chunk.replaceAll("[NaN]", "");
          //chunk = chunk.replaceAll("null", "");

          print("chunk length: " + (chunk.length).toString());
          /*if (chunk.length < 7) {
          client.close();
        }*/
          //debugPrint(chunk, wrapWidth: 1000);

          if (feature == moslemBotBe && chunk.length > 7) {
            chunk = chunk.replaceAll("null", "");
            //debugPrint(chunk, wrapWidth: 1000);
            print("=====moslem-bot-be data======");
            var str = chunk;
            var parts = str.split('["');
            var content = parts[parts.length - 1].trim();
            print("cek1");
            //var list = [chunk];
            List<dynamic> list = json.decode('["' + content);
            //list.add(chunk);
            print(list.length);
            print("cek2");
            if (list.length > 0) {
              print("cek3");
              print(list.length.toString());
              data = list;
            }
            print("cek4");

            final tempTextMessageBot = types.TextMessage(
              author: _userBot,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              id: event_id,
              text: data[0],
            );

            //print(_messages.last);
            for (var i = 0; i < _messages.length; i++) {
              if (_messages[i].id == event_id) {
                setState(() {
                  _messages[i] = tempTextMessageBot;
                });
              }
            }
          } else {
            print(chunk);
            var str = chunk;
            var parts = str.split('[');
            var prefix = parts[0].trim();
            var content = parts.sublist(1).join('[').trim();
            List<dynamic> list = json.decode("[" + content);
            data = list[0]['data'];
          }

          //debugPrint(data, wrapWidth: 1000);
        }
      }
    } catch (e) {
      print("cok");
      print(e);
      return [
        ['Failed to load data']
      ];
      //throw Exception('Failed to load quran-finder');
    } finally {
      print("cik");
      if (feature == moslemBotBe) {
        print("ahuhu");
        print("data length=" + (data.length).toString());
        //data = [data[data.length - 1]];
      }
      client.close();
      if (data.length > 0) {
        var temp = {"question": query, "type": feature, "answer": data};
        /*questions.add(query);
      answers.add(data);
      types.add(feature);*/
        histories.add(temp);

        print("|||||||||");

        final textMessageBot = types.TextMessage(
          author: _userBot,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: event_id,
          text: data[0] +
              "\n\n-------------------\nUse it as a tool to help you understand, not as a ground truth. The answer is from https://huggingface.co/spaces/Bofandra/" +
              moslemBotBe,
        );

        print(_messages);
        for (var i = 0; i < _messages.length; i++) {
          if (_messages[i].id == event_id) {
            setState(() {
              _messages[i] = textMessageBot;
            });
          }
        }
        print("========");
        return data;
      } else {
        return [
          ['Failed to load data']
        ];
      }
    }
  }
}
