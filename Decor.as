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

// "Decor" is dedicated to decoration elements in the world during gameplay
// Decoration elements include non-collision, non-moving pieces of the world,
// such as bushes, decorative trees, and clouds. Decorations may be in the
// background (behind the player) or foreground (in front of the player)
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  
  public class Decor
  {
    private var _pos:Point = new Point();
    private var _type:int;
    private var _mirror:Boolean
    
    public function Decor(x:int,y:int,type:int,toMirror:Boolean=false) {
      _pos.x = x;
      _pos.y = y;
      _type = type;
      _mirror = toMirror;
    }

    public function myBitmap(): Bitmap {
      return c.bitmapForType(c.STARTCOORD_TYPE_DECOR,_type);
    }
    
    public function draw(toBuffer:BitmapData): void {
      c.centerBitmapOfPosOntoBuffer(myBitmap(),_pos,toBuffer,false,_mirror);
    }

    // used to sort background elements into a quad tree at level start
    public function get boundingRect(): Rectangle {
      var myBMP:Bitmap = myBitmap();
      return (new Rectangle(_pos.x-myBMP.width/2,_pos.y-myBMP.height/2,myBMP.width,myBMP.height));
    }
  }
}