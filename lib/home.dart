import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import 'main.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

// http://www.hivemq.com/demos/websocket-client/
class _HomeState extends State<Home> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final topic = 'testtopic/flutter';
  MqttClient client;
  bool isConnected = false;
  String message = '';
  List<String> messages = List<String>();

  setup() async {
    client = MqttServerClient(
      'broker.mqttdashboard.com',
      'clientId-PV6Kp5KwFP',
    );
    client.autoReconnect = true;
    client.keepAlivePeriod = 90;
    client.onDisconnected = () => disconnect;
    try {
      connect();
      subscribeToTopic();
      //readLastMessagesFromMqttServer();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  connect() async {
    await client.connect();
    if (client.connectionStatus.state != MqttConnectionState.connected) {
      client.disconnect();
      isConnected = false;
      return;
    }
    isConnected = true;
    print(isConnected);
    subscribeToTopic();
    setState(() {});
  }

  subscribeToTopic() {
    client.subscribe(topic, MqttQos.exactlyOnce);
    print('subscribed');

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> listEvents) {
      listEvents.forEach((element) {
        final MqttPublishMessage recMess = element.payload;
        this.messages.add(
            MqttPublishPayload.bytesToStringAsString(recMess.payload.message));
        setState(() {});
      });
    });
    setState(() {});
  }

  readLastMessagesFromMqttServer() {
    client.published.listen((MqttPublishMessage event) {
      this
          .messages
          .add(MqttPublishPayload.bytesToStringAsString(event.payload.message));
      setState(() {});
    });
  }

  @override
  void initState() {
    setup();
    super.initState();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }

  Future disconnect() async {
    isConnected = false;
    setState(() {});
    print('disconnected');
    client.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text('MQTT CC2'),
        actions: [
          IconButton(
            icon: Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: isConnected ? Colors.blue : Colors.red,
            ),
            onPressed: () {
              isConnected ? disconnect() : connect();
            },
          )
        ],
      ),
      body: messages.length == 0
          ? Center(
              child: Text('Publique uma mensagem :)'),
            )
          : ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) {
                return ListTile(
                  title: Text(messages[index]),
                  leading: Icon(Icons.message),
                  trailing: Icon(Icons.check),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (context) => Scaffold(
              resizeToAvoidBottomInset: false,
              resizeToAvoidBottomPadding: false,
              body: SingleChildScrollView(
                reverse: true,
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.50,
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'Digite a messagem que deseja publicar',
                        style: Theme.of(context).textTheme.headline5,
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Digite o Texto',
                            icon: Icon(Icons.message),
                          ),
                          onChanged: (value) => message = value,
                        ),
                      ),
                      FlatButton(
                          color: Colors.amber,
                          onPressed: () {
                            var builder = MqttClientPayloadBuilder();
                            builder.addString(message);
                            client.publishMessage(
                                topic, MqttQos.exactlyOnce, builder.payload);
                            print(message);
                            MyApp.navigationKey.currentState.pop();
                          },
                          child: Text('Publicar')),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
