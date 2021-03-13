package;

import why.mqtt.Topic;

@:asserts
class TopicTest {

	public function new() {}
	
	public function match() {
		
		asserts.assert(('test/+/bar':Topic).match('test/foo/bar'));
		asserts.assert(('test/foo/bar':Topic).match('test/foo/bar'));
		asserts.assert(('test/#':Topic).match('test/foo/bar'));
		asserts.assert(('test/+/#':Topic).match('test/foo/bar/baz'));
		asserts.assert(('test/+/+/baz':Topic).match('test/foo/bar/baz'));
		asserts.assert(('test/#':Topic).match('test/1'));
		asserts.assert(!('test/#':Topic).match('test'));
		asserts.assert(!('test/#':Topic).match('test/'));
		asserts.assert(!('test/+':Topic).match('test/foo/bar'));
		asserts.assert(!('test/nope/bar':Topic).match('test/foo/bar'));
    	return asserts.done();
	}

}