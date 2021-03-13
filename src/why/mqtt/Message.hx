package why.mqtt;

import tink.Chunk;

class Message {
	public final topic:Topic;
	public final payload:Chunk;
	public final qos:Qos;
	public final retain:Bool;
	
	public function new(topic, payload, qos:Qos = AtMostOnce, retain = false) {
		this.topic = topic;
		this.payload = payload;
		this.qos = qos;
		this.retain = retain;
	}
}