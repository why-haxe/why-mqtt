package why.mqtt.client;

import why.mqtt.Client;

using tink.CoreApi;

abstract class BaseClient implements Client {
	public final messageReceived:Signal<Message>;
	public final disconnected:Signal<Noise>;
	final messageReceivedTrigger:SignalTrigger<Message>;
	final disconnectedTrigger:SignalTrigger<Noise>;
	
	public var active(get, never):Bool;
	
	function new() {
		messageReceived = messageReceivedTrigger = Signal.trigger();
		disconnected = disconnectedTrigger = Signal.trigger();
	}
	
	public function connect():Promise<Noise> {
		return if(active) new Error(Conflict, 'Already attempted to connect') else doConnect();
	}
	
	public function publish(message:Message):Promise<Noise> {
		return if(!active) new Error('Client not active, call connect() first') else doPublish(message);
	}
	
	public function subscribe(topic:Topic, ?options:SubscribeOptions):Promise<Subscription> {
		return if(!active) new Error('Client not active, call connect() first') else doSubscribe(topic, options);
	}
	
	public function close():Promise<Noise> {
		return if(!active) new Error('Client not active, call connect() first') else doClose();
	}
	
	abstract function doConnect():Promise<Noise>;
	abstract function doPublish(message:Message):Promise<Noise>;
	abstract function doSubscribe(topic:Topic, ?options:SubscribeOptions):Promise<Subscription>;
	abstract function doClose():Promise<Noise>;
	abstract function get_active():Bool;
	
	public inline function asClient():Client {
		return this;
	}
	
}