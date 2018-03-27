package gecko;

import gecko.components.draw.DrawComponent;
import gecko.utils.Event;
import gecko.components.Component;
import gecko.components.ComponentClass;

using Lambda;

//todo toString for debug
//todo serialize && unserialize to save and load from text

//@:poolAmount(100)
    @:expose
class Entity implements IEntity {
    public var id:Int = Gecko.getUniqueID();

    public var isRoot(get, never):Bool;
    private var _isRoot:Bool = false;

    public var enabled:Bool = true;

    public var name(get, set):String;
    private var _name:String = "";

    public var scene(get, set):Scene;
    private var _scene:Scene;

    public var depth(get, set):Int;
    private var _depth:Int = 0;

    private var _tags:Map<String, Bool> = new Map<String, Bool>();

    public var transform:Transform;
    public var renderer:DrawComponent = null;

    private var _components:Map<String,Component> = new Map();
    private var _componentsList:Array<Component> = [];

    public var onComponentAdded:Event<Entity->Component->Void>;
    public var onComponentRemoved:Event<Entity->Component->Void>;
    public var onAddedToScene:Event<Entity->Scene->Void>;
    public var onRemovedFromScene:Event<Entity->Scene->Void>;
    public var onDepthChanged:Event<Entity->Void>;

    public function new() {
        transform = new Transform(this);

        onComponentAdded = Event.create();
        onComponentRemoved = Event.create();
        onAddedToScene = Event.create();
        onRemovedFromScene = Event.create();
        onDepthChanged = Event.create();
    }

    public function beforeDestroy(){
        if(scene != null){
            scene.removeEntity(this);
        }

        transform._reset();

        for(name in _components.keys()){
            var component = _components.get(name);
            _removeComponent(component);
            component.destroy();
        }

        for(tag in _tags.keys()){
            _tags.remove(tag);
        }

        _isRoot = false;

        onComponentAdded.clear();
        onComponentRemoved.clear();
        onAddedToScene.clear();
        onRemovedFromScene.clear();
        onDepthChanged.clear();
    }


    public inline function addTag(tag:String) {
        _tags.set(tag, true);
    }

    public inline function removeTag(tag:String) {
        _tags.remove(tag);
    }

    public inline function hasTag(tag:String) : Bool {
        return _tags.exists(tag);
    }

    public function removeAllTags() {
        for(t in _tags.keys()){
            _tags.remove(t);
        }
    }

    public function addComponent<T:Component>(component:T) : T {
        component.entity = this;

        if(Std.is(component, DrawComponent)){
            if(renderer != null){
                removeComponent(renderer.__type__);
            }
            renderer = cast component;
        }

        _components.set(component.__typeName__, component);
        _componentsList.push(component);

        onComponentAdded.emit(this, component);

        return cast component;
    }

    public function removeComponent<T:Component>(componentClass:ComponentClass) : T {
        var c:T = cast _components.get(componentClass.__componentName__);
        if(c != null){
            _removeComponent(c);
            return c;
        }
        return null;
    }

    private function _removeComponent(c:Component){
        _components.remove(c.__typeName__);
        _componentsList.remove(c);

        if(renderer != null && c.__type__ == renderer.__type__){
            renderer = null;
        }

        c.entity = null;
        onComponentRemoved.emit(this, c);
    }

    public function removeAllComponents() {
        for(c in _components){
            removeComponent(c.__type__);
        }
    }

    public inline function getAllComponents() : Array<Component> {
        return _componentsList;
    }

    public inline function getComponent<T:Component>(componentClass:ComponentClass) : T {
        #if js
        return cast untyped _components.h[componentClass.__componentName__];
        #else
        return cast _components[componentClass.__componentName__];
        #end
    }

    public inline function hasComponent(name:String) : Bool {
        #if js
        return untyped _components.h.hasOwnProperty(name);
        #else
        return _components.exists(name);
        #end
    }

    inline public function toString() : String {
        return 'Entity: id -> ${id}, components -> ${_componentsList.map(function(c){ return c.name; })}';
    }

    inline function get_name():String {
        return _name == "" ? __typeName__ : _name;
    }

    inline function set_name(value:String):String {
        return this._name = value;
    }

    inline function get_scene():Scene {
        return _scene;
    }

    function set_scene(value:Scene):Scene {
        if(value == _scene)return _scene;

        var s = _scene;
        _scene = value;

        if(s != null){
            onRemovedFromScene.emit(this, s);
        }

        if(_scene != null){
            onAddedToScene.emit(this, _scene);
        }

        return _scene;
    }

    inline function get_depth():Int {
        return _depth;
    }

    function set_depth(value:Int):Int {
        if(value == _depth)return _depth;
        _depth = value;
        onDepthChanged.emit(this);
        return _depth;
    }

    inline function get_isRoot():Bool {
        return _isRoot;
    }
}