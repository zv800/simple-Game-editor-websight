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

// "LevChunkPrefab" contains a list of Piece rectangles, which together form the collision data
// for a given level graphic piece. For example, one LevChunkPrefab corresponds to the "stairs"
// piece, providing an Array of rectangles defining the collision area to use for stairs.
// The "Piece Edit" button in the editor allows collision information to be saved, loaded, and
// edited. Note that edits for a collision set affect collision for all graphics across all themes,
// and thus this is a type of editing that should only happen very early in a project, or when
// a fresh set of art theme graphics is created.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  
  public class LevChunkPrefab extends Rectangle
  {
    public static var CollisionPrefab:Array;
    
    private var _pieceList:Array = new Array();

    public function LevChunkPrefab(levParts:Array) {
      _pieceList = levParts;
      fixBoundaries();
    }
    
    ////// COLLISION //////
    
    // returns whether the rectangle passed in overlaps a collision rectangle piece of this prefab
    public function collOverlaps(thisRect:Rectangle): Array {
      var toRet:Array = new Array(0);

      if(thisRect.intersects(this)) {
        for each(var lev:Piece in _pieceList) {
          if(thisRect.intersects(lev)) {
            toRet.push(lev);
          }
        }
      }
      return toRet;
    }
    
    // used to test a mouse instead of a rectangle
    public function pointOverlaps(ptX:Number,ptY:Number): Boolean {
      var tempRect:Rectangle = new Rectangle(ptX-2,ptY-2,5,5);
      return ((collOverlaps(tempRect)).length>0);
    }
    
    ////// PIECE EDITOR MODE //////
    
    // populate this prefab's collision pieces, based on the editor's visible set
    public function replaceWithEditorSet(): void {
      _pieceList = new Array(0);
      for each(var lev:Piece in c.collisionRects) {
        _pieceList.push(new Piece(lev.x,lev.y,lev.width,lev.height))
      }
      fixBoundaries();
    }
    
    // populate the editor's visible set of collision pieces, based on this prefab
    public function copyIntoGlobalSetForEditor(): void {
      c.collisionRects = new Array(0);
      for each(var lev:Piece in _pieceList) {
        c.collisionRects.push(new Piece(lev.x,lev.y,lev.width,lev.height))
      }
    }
    
    ////// SUPPORT FUNCTIONS //////
    
    // iterates through all pieces in prefab, fitting prefab's bounding box tightly around them
    private function fixBoundaries(): void {
      var l:Number = Number.MAX_VALUE;
      var r:Number = Number.MIN_VALUE;
      var t:Number = Number.MAX_VALUE;
      var b:Number = Number.MIN_VALUE;
      for each(var lev:Piece in _pieceList) {
        if(l>lev.x) {
          l=lev.x;
        }
        if(r<lev.x+lev.width) {
          r=lev.x+lev.width;
        }
        if(t>lev.y) {
          t=lev.y;
        }
        if(b<lev.y+lev.height) {
          b=lev.y+lev.height;
        }
      }
      x=l;
      y=t;
      width=r-l;
      height=b-t;
    }
    
    ////// GETTER //////
    
    public function get pieceList(): Array {
      return _pieceList;
    }
  }
}