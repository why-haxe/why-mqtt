package;

import tink.unit.*;
import tink.testrunner.*;
import why.mqtt.client.MqttJsClient;

class RunTests {

	static function main() {
		Runner.run(TestBatch.make([
			new TopicTest(),
			#if js
			new ClientTest(new MqttJsClient({
				url:
				#if nodejs
					'mqtt://test.mosquitto.org:1883'
				#else
					'ws://test.mosquitto.org:8080'
				#end
			})),
			#end
		])).handle(Runner.exit);
	}

}