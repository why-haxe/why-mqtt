package why.mqtt.client;

import why.mqtt.Client;

using tink.CoreApi;


typedef SubscriptionConfig = {final topic:Topic; final ?options:SubscribeOptions;}
class KeepAliveClient extends BaseClient {
	public final reconnected:Signal<Connack>;
	final reconnectedTrigger:SignalTrigger<Connack>;
	
	final subscriptions:Array<SubscriptionConfig> = [];
	final makeClient:()->Promise<Client>;
	var disconnecting:Bool;
	var client:Promise<Client>;
	var binding:CallbackLink;
	
	public function new(makeClient) {
		super();
		this.makeClient = makeClient;
		reconnected = reconnectedTrigger = Signal.trigger();
	}
	
	inline function log(v:String) {
		#if sys
			Sys.println
		#elseif js
			untyped console.log
		#else
			trace
		#end
		
		('${Date.now().toString()}: [KeepAliveClient] $v');
	}
	
	/*
		try connect:
			create client + connect:
			if failed:
				try connect (with delay)
			if succeeded:
				forward messages, resolve promise
				wait for disconnect
					clear bindings
					try connect
						
		close:
			stop "try connect" if the loop is active
			if connected, disconnect
	*/
	function doConnect():Promise<Connack> {
		disconnecting = false;
		
		function abort() {
			client = null;
			return new Error(Gone, 'Closed');
		}
		
		return (function tryConnect(delay = 100, reconnecting = false):Promise<Connack> {
			log('try connect: $delay, $reconnecting');
			return
				if(disconnecting)
					abort();
				else
					(client = makeClient())
						.next(c -> {
							if(disconnecting)
								abort();
							else
								c.connect()
									.next(connack -> {
										if(disconnecting)
											abort();
										else {
											if(reconnecting)
												reconnectedTrigger.trigger(connack);
											
											binding = [
												c.messageReceived.handle(messageReceivedTrigger.trigger),
												c.disconnected.nextTime().handle(_ -> {
													binding.cancel();
													binding = tryConnect(true).handle(function() {});
												}),
											];
											if(!connack.sessionPresent) {
												resubscribe().swap(connack);
											} else {
												connack;
											}
										}
									})
									.tryRecover(e -> {
										if(e.code == Gone) {
											e;
										} else {
											var nextDelay = delay * 2;
											if(nextDelay > 60000) nextDelay = 60000;
											Future.delay(nextDelay, Noise).next(_ -> tryConnect(nextDelay, reconnecting));
										}
									});
						});
		})();
	}
	
	function doPublish(message:Message):Promise<Noise> {
		return client.next(c -> c.publish(message));
	}
	
	function doSubscribe(topic:Topic, ?options:SubscribeOptions):Promise<Subscription> {
		final subscription:SubscriptionConfig = {topic: topic, options: options};
		subscriptions.push(subscription);
		return client
			.next(c -> c.subscribe(topic, options))
			.next(sub -> new Subscription((sub:CallbackLink) & () -> subscriptions.remove(subscription), sub.topic, sub.qos));
	}
	
	function doClose():Promise<Noise> {
		return client.next(c -> {
			client = null;
			disconnecting = true;
			binding.cancel();
			c.close();
		});
	}
	
	function resubscribe():Promise<Noise> {
		return client.next(c -> Promise.inParallel([for(sub in subscriptions) c.subscribe(sub.topic, sub.options)]));
	}
	
	function get_active() {
		return client != null;
	}
}