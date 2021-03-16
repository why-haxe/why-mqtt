package;

import why.mqtt.Client;
import why.mqtt.Message;

using tink.CoreApi;

@:asserts
class ClientTest {

	final client:Client;
	
	public function new(client) {
		this.client = client;
	}
	
	@:before
	public function before() {
		return client.connect();
	}
	
	@:after
	public function after() {
		return client.close();
	}
	
	public function publish() {
		var binding:CallbackLink = null;
		
		function check(message:Message) {
			asserts.assert(message.topic == 'haxe/why/mqtt/test');
			asserts.assert(message.payload.toString() == 'heyo');
			asserts.assert((message.qos == 0)); // the extra parenthesis is for https://github.com/HaxeFoundation/haxe/issues/10173
			binding.cancel();
			asserts.done();
		}
		
		final b1 = client.messageReceived.handle(check);
		var b2:CallbackLink = null;
		b2 = client.subscribe('haxe/why/mqtt/test').handle(function(o) switch o {
			case Success(sub):
				b2 = sub;
				client.publish(new Message('haxe/why/mqtt/test', 'heyo')).handle(o -> switch o {
					case Success(_): // ok
					case Failure(e): asserts.fail(e);
				});
			case Failure(e):
				asserts.fail(e);
		});
		
		binding = () -> {
			b1.cancel();
			b2.cancel();
		}
		
		
		
		return asserts;
	}

}