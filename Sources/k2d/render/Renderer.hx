package k2d.render;

import kha.graphics2.GraphicsExtension;
import kha.math.Vector2;
import k2d.resources.Image;
import k2d.resources.Texture;
import k2d.resources.Video;
import k2d.resources.Font;
import k2d.math.FastFloat;
import k2d.math.Vec2Pool;
import k2d.math.Point;
import k2d.math.Matrix;
import k2d.utils.Color;

class Renderer implements IRenderer {
	static public var helperRenderer:Renderer = new Renderer();

	public var g2:kha.graphics2.Graphics;
    public var g4:kha.graphics4.Graphics;
	private var _g2Cache:kha.graphics2.Graphics;
    private var _g4Cache:kha.graphics4.Graphics;
	
    public var color(get, set):Int;
    private var _color:Int = Color.WHITE;

    public var alpha(get, set):Float;
    private var _alpha:Float = 1;

    public var font(get, set):Font;
    private var _font:Font;

    public var fontSize(get, set):Int;
    private var _fontSize:Int = 1;

    private var _emptyMatrix:Matrix = Matrix.identity();
    public var matrix(get, set):Matrix;

	private var _swtTemp:FastFloat;
	private var _shtTemp:FastFloat;
	private var _dwTemp:FastFloat;
	private var _dhTemp:FastFloat;

    public function new(){}

    private static function _pointsToVec2(points:Array<Point>) : Array<Vector2> {
        var vecs:Array<Vector2> = [];
        for(p in points){
            vecs.push(Vec2Pool.getFromPoint(p));
        }

        return vecs;
    }

	public function beginTexture(img:Image) {
		_g2Cache = g2;
		_g4Cache = g4;
		g2 = img.g2;
		g4 = img.g4;
		g2.begin(false);
	}

	public function endTexture() {
		g2.end();
		g2 = _g2Cache;
		g4 = _g4Cache;
		_g2Cache = null;
		_g4Cache = null;
	}

    public function begin(clear: Bool = true) {
        g2.begin(clear);
    }

    public function end() {
        g2.end();
    }

    public function reset() {
        color = 0xffffff;
        alpha = 1;
        matrix = _emptyMatrix;
    }

	public function applyTransform(transform:k2d.math.MatrixTransform) {
		color = transform.tint;
		alpha = transform.alpha;
		matrix = transform.world;
	}

    public inline function drawLine(x1:Float, y1:Float, x2:Float, y2:Float, ?strength:Float) : Void {
		g2.drawLine(x1, y1, x2, y2, strength);
	}

    public inline function drawImage(img:Image, x:FastFloat, y:FastFloat) : Void {
		g2.drawImage(img, x, y);
	}

	public inline function drawTexture(texture:Texture, x:FastFloat, y:FastFloat) : Void {
		if(texture.rotated){
			g2.pushTransformation(kha.math.FastMatrix3.translation(-texture.width*texture.pivot.x, -texture.height*texture.pivot.y));
			g2.rotate(-0.5*Math.PI, x, y);
		} //todo rotated texture (better check in frame)

		if(texture.trimmed){
			g2.drawSubImage(texture.image, x, y, texture.frame.x-texture.trim.x, texture.frame.y-texture.trim.y, texture.trim.width+texture.trim.x, texture.trim.height+texture.trim.y);
		}else{
			g2.drawSubImage(texture.image, x, y, texture.frame.x, texture.frame.y, texture.frame.width, texture.frame.height);
		}

		if(texture.rotated){
			g2.popTransformation();
		}
	}

	public inline function drawSubImage(img: Image, x: FastFloat, y: FastFloat, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat): Void {
		g2.drawSubImage(img, x, y, sx, sy, sw, sh);
	}

	public inline function drawSubTexture(texture: Texture, x: FastFloat, y: FastFloat, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat): Void {
		if(texture.trimmed){
			_swtTemp = texture.trim.width+texture.trim.x-sx;
			_shtTemp = texture.trim.height+texture.trim.y-sy;
			g2.drawSubImage(texture.image, x, y, texture.frame.x-texture.trim.x + sx, texture.frame.y-texture.trim.y + sy, sw < _swtTemp ? sw : _swtTemp, sh < _shtTemp ? sh : _shtTemp);
		}else{
			_swtTemp = texture.frame.width-sx;
			_shtTemp = texture.frame.height-sy;
			g2.drawSubImage(texture.image, x, y, texture.frame.x + sx, texture.frame.y + sy, sw > _swtTemp ? _swtTemp : sw, sh > _shtTemp ? _shtTemp : sh);
		}
	}

	public inline function drawScaledImage(img: Image, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		g2.drawScaledImage(img, dx, dy, dw, dh);
	}

	public inline function drawScaledTexture(texture: Texture, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		if(texture.trimmed){
			g2.drawScaledSubImage(
				texture.image, 
				texture.frame.x-texture.trim.x, 
				texture.frame.y-texture.trim.y, 
				texture.trim.width+texture.trim.x, 
				texture.trim.height+texture.trim.y, 
				dx, 
				dy, 
				dw - texture.trim.x, 
				dh - texture.trim.y
			);
		}else{
			g2.drawScaledSubImage(texture.image, texture.frame.x, texture.frame.y, texture.frame.width, texture.frame.height, texture.frame.x + dx, texture.frame.y + dy, dw, dh);
		}
	}

	public inline function drawScaledSubImage(image: Image, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		g2.drawScaledSubImage(image, sx, sy, sw, sh, dx, dy, dw, dh);
	}

	public inline function drawScaledSubTexture(texture: Texture, sx: FastFloat, sy: FastFloat, sw: FastFloat, sh: FastFloat, dx: FastFloat, dy: FastFloat, dw: FastFloat, dh: FastFloat): Void {
		if(texture.trimmed){
			_swtTemp = texture.trim.width+texture.trim.x-sx;
			_swtTemp = sw < _swtTemp ? sw : _swtTemp;

			_shtTemp = texture.trim.height+texture.trim.y-sy;
			_shtTemp = sh < _shtTemp ? sh : _shtTemp;

			_dwTemp = dw-texture.trim.x;
			_dhTemp = dh-texture.trim.y;

			g2.drawScaledSubImage( //todo fix
				texture.image, 
				texture.frame.x - texture.trim.x + sx, 
				texture.frame.y - texture.trim.y + sy, 
				_swtTemp, 
				_shtTemp, 
				dx,
				dy,
				dw,
				dh
			);
		}else{
			g2.drawScaledSubImage(
				texture.image, 
				texture.frame.x + sx, 
				texture.frame.y + sy, 
				sw < texture.frame.width ? sw : texture.frame.width, 
				sh < texture.frame.height ? sh : texture.frame.height, 
				dx, 
				dy, 
				dw, 
				dh
			);
		}
	}

	public inline function drawVideo(video:Video, x:Float, y:Float, width:Float, height:Float) : Void {
		g2.drawVideo(video, x, y, width, height);
	}

    public inline function drawString(text:String, x:Float, y:Float) : Void {
		g2.drawString(text, x, y);
	}

    public inline function drawAlignedString(text:String, x:Float, y:Float, horAlign:HorizontalTextAlign, verAlign:VerticalTextAlign) : Void {
        GraphicsExtension.drawAlignedString(g2, text, x, y, horAlign, verAlign);
    }

    public inline function drawAlignedCharacters(text:Array<Int>, start:Int, end:Int, x:Float, y:Float, horAlign:HorizontalTextAlign, verAlign:VerticalTextAlign) : Void {
        GraphicsExtension.drawAlignedCharacters(g2, text, start, end, x, y, horAlign, verAlign);
    }

    public inline function drawRect(x:Float, y:Float, width:Float, height:Float, ?strength:Float) : Void {
		g2.drawRect(x, y, width, height, strength);
	}

    public inline function fillRect(x:Float, y:Float, width:Float, height:Float) : Void {
		g2.fillRect(x, y, width, height);
	}

    public inline function fillTriangle(x1:Float, y1:Float, x2:Float, y2:Float, x3:Float, y3:Float) : Void {
		g2.fillTriangle(x1, y1, x2, y2, x3, y3);
	}

    public inline function drawCircle(cx:Float, cy:Float, radius:Float, ?strength:Float, ?segments:Int) : Void {
		GraphicsExtension.drawCircle(g2, cx, cy, radius, strength, segments);
	}

    public inline function drawCubicBezier(x:Array<Float>, y:Array<Float>, ?segments:Int, ?strength:Float) : Void {
		GraphicsExtension.drawCubicBezier(g2, x, y, segments, strength);
	}

	public inline function drawCubicBezierPath(x:Array<Float>, y:Array<Float>, ?segments:Int, ?strength:Float) : Void {
		GraphicsExtension.drawCubicBezierPath(g2, x, y, segments, strength);
	}

	//todo change Vector2 for Point and use a pool of vector2 to pass to the drawPolygon.
	public inline function drawPolygon(x:Float, y:Float, vertices:Array<Point>, ?strength:Float) : Void {
        var _pointVerts = Renderer._pointsToVec2(vertices);
		GraphicsExtension.drawPolygon(g2, x, y, _pointVerts, strength);
        
        for(p in _pointVerts){ 
            Vec2Pool.put(p);
        }
	}

	public inline function fillCircle(cx:Float, cy:Float, radius:Float, ?segments:Int) : Void {
		GraphicsExtension.fillCircle(g2, cx, cy, radius, segments);
	}

	public inline function fillPolygon(x:Float, y:Float, vertices:Array<Point>) : Void {
        var _pointVerts = Renderer._pointsToVec2(vertices);
		GraphicsExtension.fillPolygon(g2, x, y, _pointVerts);

        for(p in _pointVerts){ 
            Vec2Pool.put(p);
        }
	}


    public function get_color() : Int {
		return _color;
	}

	public function set_color(value:Int) : Int {
		g2.color = value + 0xff000000;
		return _color = value;
	}

	public function get_alpha() : Float {
		return _alpha;
	}

	public function set_alpha(value:Float) : Float {
		g2.opacity = value;
		return _alpha = value;
    }

    public function get_matrix() : Matrix {
		return g2.transformation;
	}

	public function set_matrix(matrix:Matrix) : Matrix {
        g2.transformation.setFrom(matrix);
		return g2.transformation;
    }

    public function get_font() : Font {
		return _font;
	}

	public function set_font(value:Font) : Font {
		g2.font = value;
		return _font = value;
	}	

	public function get_fontSize() : Int {
		return _fontSize;
	}

	public function set_fontSize(value:Int) : Int {
		g2.fontSize = value;
		return _fontSize = value;
	}	
}