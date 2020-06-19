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

// "LevChunk" refers to a level unit, storing a position and referencing a LevChunkPrefab.
// (In turn, the LevChunkPrefab knows which graphic and collision data go to a given type.)
// Whether or not a level unit is flipped is stored within LevChunk, as is the globally
// positioned bounding box.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  
  // Note: doesn't use all features of PlayerTouchableThing. (Ex. does not handle removal.)
  public class LevChunk extends PlayerTouchableThing
  {
    private var _mirror:Boolean;
    
    public function LevChunk(x:int,y:int,subType:int,toMirror:Boolean=false) {
      setup(x,y,subType);
      var fromPrefab:LevChunkPrefab = LevChunkPrefab.CollisionPrefab[subType];
      _mirror = toMirror;
    }
    
    ////// COLLISIONS //////
    
    // does the passed in piece (Player, Enemy...) collide with this level chunk?
    public static function collisionsOnly(into:*, chunk:*): void {
      into.offsetPos(-chunk.pos.x,-chunk.pos.y); // move colliding object into level chunk's coord space
      if(chunk.mirror) { // flip collision detection across the vertical axis
        into.offsetPos(-2.0*into.pos.x,0.0);
      }
      into.updateCollision(); // this changes its bounding box to the transformed space

      var levArray:Array = LevChunkPrefab.CollisionPrefab[chunk.subType].collOverlaps(into.collisionRect);

      for each(var lev:Piece in levArray) {
        into.handleCollisionWithPiece(lev); // let the character determine how to deal with  collision
      }

      if(chunk.mirror) { // unflip collision detection across the vertical axis
        into.offsetPos(-2.0*into.pos.x,0.0);
      }
      into.offsetPos(chunk.pos.x,chunk.pos.y); // move colliding object back to global coord space
      into.updateCollision(); // leave the collision data in global coordinates
    }

    // checks for collision against the common c.drawRect bounding box (often leftover from drawing)
    // currently used by Items to perform their collision hack that places non-floating ones on ground
    public function overlapsDrawRect(): Boolean {
      var bumps:Boolean = false;
      
      c.drawRect.x -= _pos.x;
      c.drawRect.y -= _pos.y;

      var levArray:Array = LevChunkPrefab.CollisionPrefab[subType].collOverlaps(c.drawRect);

      for each(var lev:Piece in levArray) {
        if(lev.intersects(c.drawRect)) {
          bumps=true;
          break;
        }
      }

      c.drawRect.x += _pos.x;
      c.drawRect.y += _pos.y;
      
      return bumps;
    }
    
    ////// RENDERING //////

    public function draw(toBuffer:BitmapData): void {
      c.centerBitmapOfPosOntoBuffer(c.bitmapForType(c.STARTCOORD_TYPE_LEVCHUNK,_subType),_pos,
                                    toBuffer,false,_mirror);
    }
    
    ////// GETTERS AND SETTERS //////

    // rather than fitting the bounding rect to the prefab's collision data, we're using the bitmap
    // this serves 2 purposes: (1) avoid pop-in as it enters the screen edge (2) avoids being
    // invisible if it's accidentally edited/cleared in Piece Edit mode to have no collision data
    public function get boundingRect(): Rectangle {
      var myBMP:Bitmap = c.bitmapForType(c.STARTCOORD_TYPE_LEVCHUNK,subType);
      return (new Rectangle(_pos.x-myBMP.width/2,_pos.y-myBMP.height/2,myBMP.width,myBMP.height));
    }

    public function get mirror(): Boolean {
      return _mirror;
    }
    public function set mirror(newMirror:Boolean): void {
      _mirror = newMirror;
    }
  }
}