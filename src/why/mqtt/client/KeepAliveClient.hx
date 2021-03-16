package why.mqtt.client;

import why.mqtt.Client;

using tink.CoreApi;

class KeepAliveClient extends BaseClient {
	public final reconnected:Signal<Noise>;
	final reconnectedTrigger:SignalTrigger<Noise>;
	
	final makeClient:()->Promise<Client>;
	var disconnecting:Bool;
	var client:Promise<Client>;
	var binding:CallbackLink;
	
	public function new(makeClient) {
		super();
		this.makeClient = makeClient;
		reconnected = reconnectedTrigger = Signal.trigger();
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
	function doConnect():Promise<Noise> {
		disconnecting = false;
		
		function abort() {
			client = null;
			return new Error(Gone, 'Closed');
		}
		
		return (function tryConnect(delay = 100, reconnecting = false):Promise<Noise> {
			trace('[KeepAliveClient] try connect: $delay, $reconnecting');
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
									.next(_ -> {
										if(disconnecting)
											abort();
										else {
											if(reconnecting)
												reconnectedTrigger.trigger(Noise);
											
											binding = [
												c.messageReceived.handle(messageReceivedTrigger.trigger),
												c.disconnected.nextTime().handle(_ -> {
													binding.cancel();
													binding = tryConnect(true).handle(function() {});
												}),
											];
											Promise.NOISE;
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
		return client.next(c -> c.subscribe(topic, options));
	}
	
	function doClose():Promise<Noise> {
		return client.next(c -> {
			client = null;
			disconnecting = true;
			binding.cancel();
			c.close();
		});
	}
	
	function get_active() {
		return client != null;
	}
}