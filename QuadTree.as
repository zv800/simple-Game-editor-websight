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

// Straightforward implementation of a Quad Tree to recursively divide the space.
// Used to optimize object-to-level collisions, and also to optimize drawing routines.
// This enables much larger levels without a performance hit due to collision calculations
// comparing each moving thing to every level piece, or wasteful off-screen drawing routines.
// Each of the following gets their own unique quadtree:
// (1) Background Decorations - used only for draw culling
// (2) Level Chunks (Collidable objects in the player/enemy layer) - used for collision checks
// (3) Foreground Decorations - used only for draw culling
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  
  public class QuadTree extends Rectangle
  {
    public static var chunkList:Array = null;
    public static var decorListBG:Array = null;
    public static var decorListFG:Array = null;

    private var _quad:Array = null;
    private var _listAtLayer:Array = null;

    public function QuadTree(l:Number,t:Number,r:Number,b:Number, worldChunks:Array) {
      var cx:Number = (l+r)*0.5; // center x
      var cy:Number = (t+b)*0.5; // center y
      
      this.x = l;
      this.y = t;
      this.width = r-l;
      this.height = b-t;
      
      _listAtLayer = worldChunks.filter(overlappingQuad);
      
      // min size keeps it from infinitely recursing if too many brushes overlap, or come together
      // in such a small space that further optimization may not warrant the associated overhead
      if(_listAtLayer.length <= c.QUADTREE_MAX_ELEMENTS || this.width < c.QUADTREE_MIN_WIDTH) {
        _quad = null; // indicates that this is a leaf node, end of a particular line's depth
        return;
      }
      _quad = new Array(4);
      _quad[0] = new QuadTree(l,t,cx,cy,_listAtLayer); // top left
      _quad[1] = new QuadTree(cx,t,r,cy,_listAtLayer); // top right
      _quad[2] = new QuadTree(l,cy,cx,b,_listAtLayer); // bottom left
      _quad[3] = new QuadTree(cx,cy,r,b,_listAtLayer); // bottom right
    }
    
    // helper function for the constructor; returns a list of which rectangles overlap this quadrant
    private function overlappingQuad(element:*, index:int, arr:Array): Boolean {
      return this.intersects(element.boundingRect);
    }

    // collects a list of which quad tree rectangles overlap the rectangle passed in
    public function collOverlaps(thisRect:Rectangle): Array {
      var overlaps:Array = new Array(0);
      
      if(_quad == null) { // leaf node (dead end)
        // check whether the rectangles in this layer overlap the one passed in
        for each(var chunk:* in _listAtLayer) {
          if(thisRect.intersects(chunk.boundingRect)) {
            overlaps.push(chunk);
          }
        }
        return overlaps;
      } else { // branch (divided entry)
        for(var i:int=0; i<4; i++) {
          if(_quad[i].intersects(thisRect)) { // is the rectangle in this quadrant?
            var fromRet:Array = _quad[i].collOverlaps(thisRect); // recurse..
            for each(chunk in fromRet) {
              overlaps.push(chunk); // add to the growing list
            }
          }
        }
        return overlaps;
      }
    }

    // since collOverlaps can contain redundant references, this function trims out reundancies
    // (doing so can help avoid checking collisions multiple times against the same element per frame)
    public function uniqueCollOverlaps(thisRect:Rectangle): Array {
      var overlapping:Array = collOverlaps(thisRect);
      overlapping = overlapping.filter(function(e:*, i:int, a:Array): Boolean {return a.indexOf(e) == i;});
      return overlapping;
    }
    
    // useful to check whether a point, for example the mouse, is over the collision area
    public function pointOverlaps(thisPt:Point): Array {
      var tempRect:Rectangle = new Rectangle(thisPt.x,thisPt.y,1,1);
      return collOverlaps(tempRect);
    }
    
    // garbage collection (i.e. automatic memory management) should not need groups explcitily
    // set to null, but sometimes that can break down with larger structures. I'm doing this as
    // an attempt to be proactive, manually setting all children to null.
    public function explicitNullChildren(): void {
      _listAtLayer = null;
      if(_quad != null) {
        for(var i:int=0;i < 4;i++) {
          if(_quad[i]!=null) {
            ((QuadTree)(_quad[i])).explicitNullChildren();
            _quad[i] = null;
          }
        }
        _quad = null;
      }
    }

  }
}