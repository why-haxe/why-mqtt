package why.mqtt;

import tink.Chunk;

using tink.CoreApi;

interface Client {
	final messageReceived:Signal<Message>;
	final disconnected:Signal<Noise>;
	var active(get, never):Bool;
	function connect():Promise<Noise>;
	function publish(message:Message):Promise<Noise>;
	function subscribe(topic:Topic, ?options:SubscribeOptions):Promise<Subscription>;
	function close():Promise<Noise>;
}

// standard mqtt configs
typedef Config = {
	final ?keepAlive:Int; // seconds
	final ?clientId:String;
	final ?version:Int;
	final ?cleanSession:Bool;
	final ?username:String;
	final ?password:String;
	final ?willMessage:Message;
}

typedef SubscribeOptions = {
	final ?qos:Qos;
}

class Subscription extends tink.core.Callback.SimpleLink {
	public final topic:Topic;
	public final qos:Qos;
	
	public inline function new(f, topic, qos) {
		super(f);
		this.topic = topic;
		this.qos = qos;
	}
}