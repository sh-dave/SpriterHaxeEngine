package spriter.library;

import spriter.definitions.PivotInfo;
import spriter.definitions.SpatialInfo;
import spriter.util.SpriterUtil;

class Rectangle {
	public var x : Float;
	public var y : Float;
	public var w : Float;
	public var h : Float;

	public function new( ?x = 0.0, ?y = 0.0, ?w = 0.0, ?h = 0.0 ) {
		this.x = x;
		this.y = y;
		this.w = w;
		this.h = h;
	}
}

typedef TextureAsset = {
	var image : kha.Image;
	var region : Rectangle;
}

typedef AssetProvider = {
	function getAsset( id : String ) : TextureAsset;
}

class KhaG2Library extends spriter.library.AbstractLibrary {
	public function new( assetProvider : AssetProvider ) {
		super(null);

		this.assetProvider = assetProvider;
	}

	override public function clear() {
		parts.splice(0, parts.length);
	}

	override public function addGraphic( name : String, info : SpatialInfo, pivots : PivotInfo ) {
		if (!textureAssetCache.exists(name)) {
			textureAssetCache.set(name, assetProvider.getAsset(name));
		}

		var asset = textureAssetCache.get(name);
		var spatialResult : SpatialInfo = compute(info, pivots, asset.region.w, asset.region.h);

		parts.push({
			asset : asset,
			x : spatialResult.x,
			y : spatialResult.y,
			angle : SpriterUtil.toRadians(SpriterUtil.fixRotation(spatialResult.angle)),
			originX : pivots.pivotX,
			originY : pivots.pivotY,
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
			g.drawScaledSubImage(
				part.asset.image,
				part.asset.region.x, part.asset.region.y, part.asset.region.w, part.asset.region.h,
				part.x + part.originX, part.y + part.originY, part.asset.region.w * part.scaleX, part.asset.region.h * part.scaleY
			);

			//g.drawImage(part.image, part.x, part.y);

			g.popOpacity();
			g.popTransformation();
		}
	}

	var assetProvider : AssetProvider;
	var textureAssetCache = new Map<String, TextureAsset>();
	var parts = new Array<Part>();
}

private typedef Part = {
	var asset : TextureAsset;

	var x : Float;
	var y : Float;
	var angle : Float;
	var originX : Float;
	var originY : Float;
	var scaleX : Float;
	var scaleY : Float;
	var alpha : Float;
}
