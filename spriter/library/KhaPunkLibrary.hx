package spriter.library;

import spriter.definitions.PivotInfo;
import spriter.definitions.SpatialInfo;
import spriter.util.Point;
import spriter.util.SpriterUtil;

class KhaPunkLibrary extends spriter.library.AbstractLibrary {
	public function new( basepath : String, scene : com.khapunk.Scene ) {
		super(basepath);

		scene.addGraphic(graphics);
	}

	//override public function getFile( name : String ) : Dynamic {
		//return kha.Loader.the.getImage(_basePath + name);
	//}

	override public function clear() {
		graphics.removeAll();
	}

	private function getPivotsRelativeToCenter( info : SpatialInfo, pivots : PivotInfo, width : Float, height : Float ) : Point {
		var x : Float = (pivots.pivotX - 0.5) * width * info.scaleX;
		var y : Float = (0.5 - pivots.pivotY) * height * info.scaleY;
		return new spriter.util.Point(x, y);
	}

	/*
	override public function compute(info:SpatialInfo, pivots:PivotInfo, width:Float, height:Float):SpatialInfo
	{
		var degreesUnder360 = SpriterUtil.under360(info.angle);
		var rad = SpriterUtil.toRadians(degreesUnder360);
		var s = Math.sin(rad);
		var c = Math.cos(rad);

		var pivotX =  info.x;
		var pivotY =  info.y;

		var preX = info.x - pivots.pivotX * width * info.scaleX + 0.5 * width * info.scaleX;
		var preY = info.y + (1 - pivots.pivotY) * height * info.scaleY - 0.5 * height * info.scaleY;

		var x2 = (preX - pivotX) * c - (preY - pivotY) * s + pivotX;
        var y2 = (preX - pivotX) * s + (preY - pivotY) * c + pivotY;

		return new SpatialInfo(x2, -y2, degreesUnder360, info.scaleX, info.scaleY, info.a, info.spin);
	}
*/

	override public function addGraphic( name : String, info : SpatialInfo, pivots : PivotInfo ) {
		var texture = kha.Loader.the.getImage('${_basePath}/${name});
		var image = new com.khapunk.graphics.PunkImage(texture);

		var spatialResult : SpatialInfo = compute(info, pivots, texture.width, texture.height);
		var relativePivots = getPivotsRelativeToCenter(info, pivots, texture.width, texture.height);

		//image.originX = texture.width * 0.5;
		//image.originY = texture.height * 0.5;
		image.originX = 0;
		image.originY = 0;
		//image.originX = relativePivots.x;
		//image.originY = relativePivots.y;
		image.x = spatialResult.x;
		image.y = spatialResult.y;
		image.angle = SpriterUtil.fixRotation(spatialResult.angle);
		image.scaleX = spatialResult.scaleX;
		image.scaleY = spatialResult.scaleY;
		image.alpha = spatialResult.a;

		graphics.add(image);
	}

	var graphics = new com.khapunk.graphics.Graphiclist();
}
