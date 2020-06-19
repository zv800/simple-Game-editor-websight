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

// When in the level editor, ObjStart entities are shown instead of enemies/items/levelChunks/etc.
// These bookmark the spawn locations and information for all pieces, so that the data is not
// lost when the editor is switched to Play/test mode. These contain the data which gets saved
// and loaded in a level map file when Save/Load are used in the Level editor mode.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  
  public class ObjStart
  {
    private var _pos:Point = new Point();
    private var _type:int;
    private var _subType:int;
    private var _mirror:Boolean; // only used for level chunks and decor
    private var _isBG:Boolean; // only used for decor
    
    public function ObjStart(x:int,y:int,type:int, subType:int=0, toMirror:Boolean=false, isInBG:Boolean=true) {
      _pos.x = x;
      _pos.y = y;
      _type = type;
      _subType = subType;
      _mirror = toMirror;
      _isBG = isInBG;
    }

    ////// RENDERING //////
    
    public function myBitmap(): Bitmap {
      return c.bitmapForType(_type,_subType);
    }
    
    public function draw(toBuffer:BitmapData, currentlyMousedOver:ObjStart=null): void {
      c.centerBitmapOfPosOntoBuffer(myBitmap(),_pos,toBuffer,false,_mirror);
      
      if(this==currentlyMousedOver) {
        c.fitBitmapOfPosOntoBuffer(c.selectBMP,_pos,toBuffer,1.3);
      }
    }
    
    ////// EDITOR INPUT SUPPORT FUNCTIONS //////
    
    // returns whether the bounding box or collision data is under the mouse, if the mouse is free
    public function nearMouse(updateRect:Boolean = false): Boolean {
      if(c.mouseBusy()) {
        return false;
      }
      if(updateRect) {
        c.setRectFromBitmap(myBitmap(),_pos);
      }
      if(_type==c.STARTCOORD_TYPE_LEVCHUNK) { // use exact collision
        return LevChunkPrefab.CollisionPrefab[_subType].pointOverlaps(c.cmx-_pos.x,c.cmy-_pos.y);
      } else { // use graphic bounding box
        return c.drawRect.contains(c.cmx,c.cmy);
      }
    }
    
    // handy for comparisons to narrow down which ObjStart is nearest to the mouse in the editor
    // this becomes important to distinguish which object is intended when multiple are overlapped
    public function distFromMouse(): Number {
      var dx:Number = c.cmx-_pos.x;
      var dy:Number = c.cmy-_pos.y;
      return Math.sqrt(dx*dx+dy*dy);
    }
    
    ////// GETTERS AND SETTERS //////
    
    public function get isBG(): Boolean {
      return _isBG;
    }
    public function set isBG(newBG:Boolean): void {
      _isBG = newBG;
    }
    public function get mirror(): Boolean {
      return _mirror;
    }
    public function set mirror(newMirror:Boolean): void {
      _mirror = newMirror;
    }
    public function get pos(): Point {
      return _pos;
    }
    public function set pos(newPos:Point): void {
      _pos = newPos.clone();
    }
    public function get type(): int {
      return _type;
    }
    public function set type(newType:int): void {
      _type = newType;
    }
    public function get subType(): int {
      return _subType;
    }
    public function set subType(newSubType:int): void {
      _subType = newSubType;
    }
  }
}