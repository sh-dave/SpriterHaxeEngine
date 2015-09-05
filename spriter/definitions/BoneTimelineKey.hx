package spriter.definitions;
import haxe.xml.Fast;

/**
 * ...
 * @author Loudo
 */
class BoneTimelineKey extends SpatialTimelineKey
{
	// unimplemented in Spriter
    public var length:Int;
    public var width:Int;
	
	public function new(fast:Fast=null) 
	{
		
		if(fast != null){
			length = fast.has.length ? Std.parseInt(fast.att.length) : 200;
			width = fast.has.width ? Std.parseInt(fast.att.width) : 10;
		}
		
		super(fast);
	}
	
	override public function copy ():TimelineKey
	{
		var	copy:TimelineKey = new BoneTimelineKey();
		return clone (copy);
	}

	override public function clone (clone:TimelineKey):TimelineKey
	{
		super.clone(clone);
		
		var	c:BoneTimelineKey = cast clone;
		
		c.length = length;
		c.width = width;
		
		return c;
	}
	
	override public function paint(defaultPivots:PivotInfo):PivotInfo
    {
        #if SPRITER_DEBUG_BONE
		var drawLength:Float = length * info.scaleX;
	   //var drawHeight:Float = info.height*info.scaleY;
		var drawHeight:Float = width * info.scaleY;
		// paint debug bone representation 
		// e.g. line starting at x,y,at angle, 
		// of length drawLength, and height drawHeight
        #end
		return defaultPivots;
    }           

    override public function linearKey(keyB:TimelineKey,t:Float):Void
    {
        var keyBBone:BoneTimelineKey = cast keyB;
        linearSpatialInfo(info, keyBBone.info, info.spin, t);

        #if SPRITER_DEBUG_BONE
		length	= Std.int(linear(length, keyBBone.length, t));
		width	= Std.int(linear(width, keyBBone.width, t));
        #end
    }
}