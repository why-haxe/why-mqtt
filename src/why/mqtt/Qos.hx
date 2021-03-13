package why.mqtt;

enum abstract Qos(Int) to Int {
	var AtMostOnce = 0;
	var AtLeastOnce = 1;
	var ExactlyOnce = 2;
	
	@:op(A==B) public static function eqInt(lhs:Qos, rhs:Int):Bool;
	@:op(A!=B) public static function neqInt(lhs:Qos, rhs:Int):Bool;
}