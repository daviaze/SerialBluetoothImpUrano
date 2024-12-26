import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({required this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {
  static final clientID = 0;
  BluetoothConnection? connection;

  List<_Message> messages = List<_Message>.empty(growable: true);
  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => (connection?.isConnected ?? false);

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    print(widget.server.address);

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;

      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      // Escutando os dados recebidos da balança
      connection!.input!.listen(_onDataReceived).onDone(() {
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occurred');
      print(error);
    });
  }

// Função para enviar o comando inicial
  void sendInitialCommand() {
    if (connection != null) {
      // Envia o dígito '4' como comando inicial
      connection!.output.add(Uint8List.fromList('4'.codeUnits));
      connection!.output.allSent.then((x) {
        print(x);
        print('Initial command sent successfully.');
      }).catchError((error) {
        print('Failed to send the initial command: $error');
      });
    } else {
      print('Connection is null, cannot send initial command.');
    }
  }

// Função para processar os dados recebidos
  void _onDataReceived(Uint8List data) {
    // Converter os dados recebidos em texto
    String receivedData = String.fromCharCodes(data).trim();
    messages.add(_Message(clientID, receivedData));
    print('Data received: $receivedData');
    setState(() {

    });
  }


  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                    (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final serverName = widget.server.name ?? "Unknown";
    return Scaffold(
      appBar: AppBar(
          title: (isConnecting
              ? Text('Connecting chat to ' + serverName + '...')
              : isConnected
              ? Text('Live chat with ' + serverName)
              : Text('Chat log with ' + serverName))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: list),
            ),
            isConnecting ? CircularProgressIndicator() : Row(
              children: <Widget>[
                /*Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                            ? 'Type your message...'
                            : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),*/
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.indigoAccent),
                    child: IconButton(
                        icon: const Icon(Icons.get_app, color: Colors.white,),
                        onPressed: isConnected
                            ? () => _sendCommandToGetValue()
                            : null),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.redAccent),
                    child: IconButton(
                        icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white,),
                        onPressed: isConnected
                            ? () => _clearValues()
                            : null),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _sendCommandToGetValue() async {
    textEditingController.clear();

      try {
        connection!.output.add(Uint8List.fromList([4]));
        await connection!.output.allSent;

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
  }

  _clearValues() {
    setState(() {
      messages.clear();
    });
  }
}