/*
 * Everyone's Platformer
 * Created by Chris DeLeon for http://www.hobbygamedev.com/
 * Released under Creative Commons Attribution 3.0
 * For more information, see: http://creativecommons.org/licenses/by/3.0/
 * In summary: You are free to modify, build upon, or pull from this source,
 * provided that you provide an attribution credit along the lines of:
 * "Everyone's Platformer" Engine Code and Design by Chris DeLeon
 * or
 * Based on "Everyone's Platformer" Engine Code and Design by Chris DeLeon
 */

// This class is used as the basis for objects in the world which have a position and may
// collide with the player. Item and Enemy are the main two classes built atop this one.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.errors.IllegalOperationError;
  import flash.geom.Point;
  
  public class PlayerTouchableThing
  {
    protected var _pos:Point = new Point(); // position
    protected var _subType:int; // type is the extending class (Item, Enemy), subType is the kind
    protected var _readyToBeRemoved:Boolean; // for safe "removal" mid-iteration (by doing it after)
    
    public function PlayerTouchableThing() {
    }
    public function setup(x:int,y:int,subType:int): void {
      _pos.x = x;
      _pos.y = y;
      _subType = subType;
      _readyToBeRemoved = false;
    }
    
    // this class can be overridden for cases like jumping on enemies to destroy them
    // return true if player should bounce after jumping on this
    public function jumpedOnByPlayer(p1:Player): Boolean {
    
      // by default, jumping on top of something is the same as hitting it any other way
      // ex. collecting an item can happen from any direction.
      touchedPlayer(p1);
      
      return false; // in default implementation, do not bounce upward from the top-down collision
    }
    
    ////// "ABSTRACT" FUNCTIONS / TO BE OVERRIDDEN BY SUBCLASSES //////
    
    public function touchedPlayer(p1:Player): void {
      throw new IllegalOperationError("Abstract method, should only be called overridden on subclass.");
    }
    
    public function moveAndDraw(p1:Player,quadTree:QuadTree,toBuffer:BitmapData): void {
      throw new IllegalOperationError("Abstract method, should only be called overridden on subclass.");
    }
    
    ////// GETTERS AND SETTERS //////
    
    public function get readyToBeRemoved(): Boolean {
      return _readyToBeRemoved;
    }
    
    public function set readyToBeRemoved(newVal:Boolean): void {
      _readyToBeRemoved = newVal;
    }

    public function offsetPos(byX:Number,byY:Number): void {
      _pos.x += byX;
      _pos.y += byY;
    }
    
    public function get pos(): Point {
      return _pos;
    }
    
    public function set pos(newPos:Point): void {
      _pos = newPos.clone();
    }
    
    public function get subType(): int {
      return _subType;
    }
    
    public function set subType(newSubType:int): void {
      _subType = newSubType;
    }
  }
}