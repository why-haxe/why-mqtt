package;

import why.mqtt.Message;
import why.mqtt.Client;
import why.mqtt.client.KeepAliveClient;
using tink.CoreApi;

@:asserts
@:timeout(600000)
class KeepAliveTest {
	
	final makeClient:()->Client;
	final keepAliveClient:KeepAliveClient;
	
	public function new(makeClient) {
		this.makeClient = makeClient;
		this.keepAliveClient = new KeepAliveClient(() -> makeClient());
	}
	
	@:before
	public function before() {
		return Promise.NOISE;
	}
	
	public function test() {
		final server = new Server();
		final topic = 'why-mqtt';
		server.start()
			.next(_ -> {
				keepAliveClient.connect()
					.next(connack -> {
						asserts.assert(connack.sessionPresent == false);
						keepAliveClient.subscribe(topic);
					})
					.next(v -> {
						haxe.Timer.delay(() -> keepAliveClient.publish(new Message(topic, '1')).eager(), 0);
						keepAliveClient.messageReceived.nextTime();
					})
					.next(message -> {
						asserts.assert(message.payload.toString() == '1');
					})
					.next(_ -> server.stop())
					.next(_ -> {
						haxe.Timer.delay(() -> server.start().eager(), 100);
						keepAliveClient.reconnected.nextTime();
					})
					.next(connack -> {
						asserts.assert(connack.sessionPresent == false);
						haxe.Timer.delay(() -> keepAliveClient.publish(new Message(topic, '2')).eager(), 0);
						keepAliveClient.messageReceived.nextTime();
					})
					.next(message -> {
						asserts.assert(message.payload.toString() == '2');
					});
			})
			.handle(asserts.handle);
		return asserts;
	}
}

class Server {
	var server:js.node.net.Server;
	var connections = [];
	
	public function new() {}
	
	public function start(port = 1883):Promise<Noise> {
		return Promise.irreversible((resolve, reject) -> {
			final aedes = js.Lib.require('aedes')();
			server = js.node.Net.createServer(aedes.handle);
			server.on('connection', cnx -> connections.push(cnx));
			server.listen(port, resolve.bind(Noise));
		});
	}
	
	public function stop() {
		return Future.irreversible(cb -> {
			server.close(cb.bind(Noise));
			for(cnx in connections) cnx.destroy();
		});
	}
}