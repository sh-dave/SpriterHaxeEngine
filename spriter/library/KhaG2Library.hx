package spriter.library;

import spriter.definitions.PivotInfo;
import spriter.definitions.SpatialInfo;
import spriter.util.SpriterUtil;

/*
	(DK) TODO
		- assets/image provider
*/
class KhaG2Library extends spriter.library.AbstractLibrary {
	public function new( basepath : String ) {
		super(basepath);
	}

	override public function clear() {
		parts.splice(0, parts.length);
	}

	override public function addGraphic( name : String, info : SpatialInfo, pivots : PivotInfo ) {
		var graphic = '${_basePath}/${name}';
		var fixed = KhaTools.fixAssetId(graphic);

		if (!imageCache.exists(fixed)) {
			imageCache.set(fixed, Reflect.field(kha.Assets.images, fixed));
		}

		var image = imageCache.get(fixed);
		var spatialResult : SpatialInfo = compute(info, pivots, image.width, image.height);

		parts.push({
			x : spatialResult.x,
			y : spatialResult.y,
			angle : SpriterUtil.toRadians(SpriterUtil.fixRotation(spatialResult.angle)),
			originX : 0,
			originY : 0,
			image : image,
			scaleX : spatialResult.scaleX,
			scaleY : spatialResult.scaleY,
			alpha : spatialResult.a,
		});
	}

	// TODO (DK) crappy name
	public function renderimpl( g : kha.graphics2.Graphics ) {
		for (part in parts) {
			g.pushRotation(part.angle, part.x + part.originX, part.y + part.originY);
			g.pushOpacity(part.alpha);
			g.drawImage(part.image, part.x, part.y);
			g.popOpacity();
			g.popTransformation();
		}
	}

	var imageCache = new Map<String, kha.Image>();
	var parts = new Array<Part>();
}

private typedef Part = {
	var image : kha.Image;

	var x : Float;
	var y : Float;
	var angle : Float;
	var originX : Float;
	var originY : Float;
	var scaleX : Float;
	var scaleY : Float;
	var alpha : Float;
}
