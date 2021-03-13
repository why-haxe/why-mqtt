package why.mqtt;

@:forward
abstract Topic(String) to String {
	@:from
	public static function sanitize(v:String):Topic {
		var start = 0, end = v.length - 1;
		while(v.charCodeAt(start) == '/'.code) start++;
		while(v.charCodeAt(end) == '/'.code) end--;
		return cast v.substring(start, end + 1);
	}
	public function match(v:Topic):Bool {
		final filter = this.split('/');
		final target = v.split('/');
		
		for(i in 0...filter.length) {
			switch filter[i] {
				case '#': return target.length > i;
				case '+': // skip
				case part: if(part != target[i]) return false;
			}
		}
		
		return filter.length == target.length;
	}
}