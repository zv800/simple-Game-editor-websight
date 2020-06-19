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

// Piece is mostly just a Rectangle, but with a specialized draw function that changes
// color based on mouseover or selection state. Pieces are used to visually depict the collision
// data of LevChunkPrefab entries (ex. individual steps as collision data for a stairs graphic).
package {
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.geom.Rectangle;
  import flash.media.Sound;
  
  public class Piece extends Rectangle
  {
    public function Piece(x:int,y:int,wid:int,hei:int) {
      this.x = x;
      this.y = y;
      this.width = wid;
      this.height = hei;
    }
    
    public function draw(toBuffer:BitmapData): void {
      if(c.camera.intersects(this)) { // no quad tree data when in editor mode
        // offset by for screen scroll for printing to bitmap
        this.x -= c.camera.x;
        this.y -= c.camera.y;

        if(this == c.movingPiece) { // is this piece the one currently being moved?
          toBuffer.fillRect( this, c.PIECE_COLOR_SELECTED ); // color to indicate movement
        } else if(this.contains(c.mx_pregrid,c.my_pregrid) && // mouse over
                  c.movingPiece == null && c.editorBox == null &&  // nothing selected/moving
                  c.editorButtonMousedOver == null) { // not over a button
          toBuffer.fillRect( this, c.PIECE_COLOR_MOUSEOVER ); // highlighted
        } else {
          toBuffer.fillRect( this, c.PIECE_COLOR ); // not highlighted
        }
        
        // undo offset
        this.x += c.camera.x;
        this.y += c.camera.y;
      }
    }
    
    // used when moving pieces in the editor
    public function slideTo(nx:int,ny:int):void {
      this.x = nx;
      this.y = ny;
    }
  }
}