package;

import why.mqtt.client.*;

class Playground {
	static function main() {
		final mqtt = new MqttJsClient({
			url: 'ws://10.97.42.150:8083/mqtt',
			username: 'username',
			password: 'password',
			clientId: 'client-id',
			cleanSession: false,
		});
		
		mqtt.messageReceived.handle(message -> {
			trace(message.topic, message.payload.toString());
		});
		
		trace('connect');
		mqtt.connect().handle(function(o) switch o {
			case Success(_):
				trace('connected');
				mqtt.subscribe('topic');
			case Failure(e):
				trace(e);
		});
	}
}