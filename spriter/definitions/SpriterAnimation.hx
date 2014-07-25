package spriter.definitions;
import haxe.xml.Fast;
import spriter.definitions.SpriterAnimation.LoopType;
import spriter.definitions.SpriterAnimation.MetaDispatch;
import spriter.interfaces.IScml;
import spriter.library.AbstractLibrary;

/**
 * ...
 * @author Loudo
 */
enum LoopType
{
    LOOPING;
    NO_LOOPING;
}

enum MetaDispatch
{
	ONCE;
	ONCE_PER_LOOP;
	ALWAYS;
}
 
class SpriterAnimation
{
	/*
	 * SCML definitions
	 */
	public var id:Int;
	public var name:String;
    public var length:Int;
    public var loopType:LoopType;
    public var mainlineKeys:Array<MainlineKey>;
    public var timelines:Array<SpriterTimeline>;
	public var taglines:Array<TaglineKey>;
	public var varlines:Array<VarlineKey>;
	public var metaDispatch:MetaDispatch = ONCE_PER_LOOP;
	
	/*
	 * Custom definitions
	 * 
	 */
	var loop:Int = 0;
	public var points:Array<SpatialInfo>;
	public var boxes:Array<String>;
	
	public function new(fast:Fast) 
	{
		mainlineKeys = new Array<MainlineKey>();
		timelines = new Array<SpriterTimeline>();
		
		
		id = Std.parseInt(fast.att.id);
		name = fast.att.name;
		length = Std.parseInt(fast.att.length);
		//loopType = fast.has.looping ? Type.createEnum(LoopType, fast.att.looping.toUpperCase()) : LOOPING;
		if (fast.has.looping) {
			if (fast.att.looping == "true") {
				loopType = LOOPING;
			}else {
				loopType = NO_LOOPING;
			}
		}else {
			loopType = LOOPING;
		}
		
		for (mk in fast.node.mainline.nodes.key)
		{
			mainlineKeys.push(new MainlineKey(mk));
		}
		
		for (t in fast.nodes.timeline)
		{
			timelines.push(new SpriterTimeline(t));
		}
		if (fast.hasNode.meta)
		{
			fast = fast.node.meta;
			if (fast.hasNode.tagline)
			{
				taglines = [];
				for (tag in fast.node.tagline.nodes.key)
				{
					taglines.push(new TaglineKey(tag));
				}
			}
			if (fast.hasNode.varline)
			{
				varlines = [];
				for (currVar in fast.node.varline.nodes.key)
				{
					varlines.push(new VarlineKey(currVar));
				}
			}
			
		}
	}
	
	public function setCurrentTime(newTime:Int, library:AbstractLibrary, root:IScml):Void
    {
		var currentTime:Int;
		var tempLoop:Int;
		switch(loopType)
        {
			case LOOPING:
				tempLoop = loop;
				loop = Std.int(newTime / length);
				currentTime = newTime % length;
				//update
				updateCharacter(mainlineKeyFromTime(currentTime), currentTime, library, root);
				if (metaDispatch == ONCE_PER_LOOP && tempLoop != loop) {
					resetMetaDispatch();
				}
				//callback only at the first loop and once
				if (loop == 1 && tempLoop < 1)
					root.onEndAnim();
				
			case NO_LOOPING:
				currentTime = Std.int(Math.min(newTime, length));
				//update
				updateCharacter(mainlineKeyFromTime(currentTime), currentTime, library, root);
				//callback
				if (currentTime == length)
					root.onEndAnim();
        }
    }

    public function updateCharacter(mainKey:MainlineKey, newTime:Int, library:AbstractLibrary, root:IScml):Void
    {
        var transformedBoneKeys:Array<SpatialInfo> = new Array<SpatialInfo>();
		var currentKey:SpatialTimelineKey;
		
		var	currentRef:Ref;
		var spatialInfo:SpatialInfo;
		var len:Int = mainKey.boneRefs.length;
        for (b in 0...len)
        {
            currentRef = mainKey.boneRefs[b];
			currentKey = cast keyFromRef(currentRef, newTime);
            if (currentRef.parent >= 0)
			{
                spatialInfo = transformedBoneKeys[currentRef.parent];
            }
			else 
			{
				spatialInfo = root.spriterSpatialInfo;
			}

            spatialInfo = currentKey.info.unmapFromParent(spatialInfo);
            transformedBoneKeys.push(spatialInfo);
        }

        //var objectKeys:Array<TimelineKey>;
		points = [];
		boxes = [];
		len = mainKey.objectRefs.length;
        for(o in 0...len)
        {
            currentRef = mainKey.objectRefs[o];
			currentKey = cast keyFromRef(currentRef,newTime);
			//trace(currentKey.info.a);
            if(currentRef.parent >= 0)
            {
                spatialInfo = transformedBoneKeys[currentRef.parent];
            }
            else
            {
                spatialInfo = root.spriterSpatialInfo;
            }
			
		    //currentKey.info = currentKey.info.unmapFromParent(parentInfo);//TOFIX and remove next line ?
			spatialInfo = currentKey.info.unmapFromParent(spatialInfo);
			var activePivots:PivotInfo;
			if (Std.is(currentKey, SpriteTimelineKey)) {
				var currentSpriteKey:SpriteTimelineKey = cast(currentKey, SpriteTimelineKey);
				activePivots = root.getPivots(currentSpriteKey.folder, currentSpriteKey.file);
				activePivots = currentKey.paint(activePivots.pivotX, activePivots.pivotY);
				//render from library
				var currentKeyName:String = root.getFileName(currentSpriteKey.folder, currentSpriteKey.file);
				if (currentKeyName != null) {//hidden object test (via mapping)
					library.addGraphic(root.spriterName, currentRef.timeline, currentRef.key, currentKeyName, spatialInfo, activePivots);
				}
			}else {
				activePivots = new PivotInfo();
				currentKey.paint(activePivots.pivotX, activePivots.pivotY);
				points.push(currentKey.info);
				//TODO pivotsBox
			}
			

            //objectKeys.push(currentKey);
        }

        //SCML REF : <expose objectKeys to api users to retrieve AND replace objectKeys>
		//(devnote :I'm not doing that, instead I add directly the element in the library (since libraries compute differently))
		
		/*len = objectKeys.length;
        for(k in 0...len)
        {            
            objectKeys[k].paint();
        }*/
		
		//following lines not in scml references yet
		
		if(taglines != null){
			for (tag in taglines) {
				if (tag.time == mainKey.time)
				{
					if (metaDispatch == ALWAYS)
					{
						trace("tag", tag.id);
					}else if (metaDispatch == ONCE_PER_LOOP && mainKey.time != tag.lastDispatched) {
						tag.lastDispatched = mainKey.time;
						trace("tag", tag.id);
					}else if (metaDispatch == ONCE && !tag.dispatched) {
						tag.lastDispatched = mainKey.time;
						trace("tag", tag.id);
					}
				}
			}
		}
    }

    public function mainlineKeyFromTime(time:Int):MainlineKey
    {
        var	currentMainKey:Int = 0;
		var len:Int = mainlineKeys.length;
		for (m in 0...len)
		{
			if(mainlineKeys[m].time <= time)
			{
				currentMainKey = m;
			}
			
			if(mainlineKeys[m].time >= time)
			{
				break;
			}
		}
		
		return mainlineKeys[currentMainKey];
    }	
   
    public function keyFromRef(ref:Ref, newTime:Int):TimelineKey
    {
        var timeline:SpriterTimeline = timelines[ref.timeline];
        var keyA:TimelineKey = timeline.keys[ref.key].copy();
        
        if(timeline.keys.length == 1 || keyA.curveType == INSTANT)
        {
			return keyA;
        }
        
        var nextKeyIndex:Int = ref.key + 1;
        
        if(nextKeyIndex >= timeline.keys.length)
        {
            if(loopType == LOOPING)
            {
                nextKeyIndex = 0; 
            }
            else
            {
                return keyA;
            }
        }
  
        var keyB:TimelineKey = timeline.keys[nextKeyIndex].copy();
        var keyBTime:Int = keyB.time;

        if(keyBTime < keyA.time)
        {
            keyBTime = keyBTime+length;
        }
		
        keyA.interpolate(keyB, keyBTime, newTime);
		return keyA;
    }
	/**
	 * Test if update needed between keys.
	 * TODO test if sometimes newTime never reach key.time.
	 * @param	ref
	 * @param	newTime
	 * @return  if newTime != keyTime and curveType == instant, so update doesn't needed
	 */
	public function needToUpdate(ref:Ref, newTime:Int):Bool
	{
		var timeline:SpriterTimeline = timelines[ref.timeline];
        var keyA:TimelineKey = timeline.keys[ref.key];
        
        if(timeline.keys.length == 1 || keyA.curveType == INSTANT)
        {
            if ( keyA.time != newTime) {
				return false;
			}
        }
		return true;
        
	}
	
	private function resetMetaDispatch():Void
	{
		if(taglines != null){
			for (tag in taglines) {
				tag.dispatched = false;
			}
		}
	}
	
}