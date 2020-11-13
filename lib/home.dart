import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  MqttClient client;
  bool isConnected = false;
  String message = '';
  // http://www.hivemq.com/demos/websocket-client/
  setup() async {
    client = MqttServerClient(
      'broker.mqttdashboard.com',
      'clientId-i4hdkpVSsI',
    );
    client.autoReconnect = true;
    client.logging(on: true);
    client.keepAlivePeriod = 90;
    client.onDisconnected = () {
      print('desconectado');
      isConnected = false;
      setState(() {});
      return;
    };
    try {
      await client.connect();
      if (client.connectionStatus.state != MqttConnectionState.connected) {
        client.disconnect();
        isConnected = false;
        return;
      }

      isConnected = true;
      client.subscribe('flutter/1', MqttQos.exactlyOnce);
      client.published.listen((MqttPublishMessage event) {
        this.message += '\n' +
            MqttPublishPayload.bytesToStringAsString(event.payload.message);
        setState(() {});
      });

      client.updates
          .listen((List<MqttReceivedMessage<MqttMessage>> listEvents) {
        listEvents.forEach((element) {
          final MqttPublishMessage recMess = element.payload;
          final messagebytes =
              MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
          message += '\n' + messagebytes;
          setState(() {});
        });
      });
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT CC2'),
      ),
      body: Column(
        children: [
          Center(
            child: Text(
              isConnected ? 'Conectado com sucesso' : 'Falha na conexão',
            ),
          ),
          Text('$message')
        ],
      ),
    );
  }
}
