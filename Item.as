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

// "Item" refers to a stationary collectible, including water drops, Prangy Arms (keys),
// and Prangy Bodies (Locked Doors).

package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  
  public class Item extends PlayerTouchableThing // gets position etc. from PlayerTouchableThing
  {
    private var _bounceOscillator:Point = new Point();
    private var _needsToFall:Boolean;

    public function Item(x:int,y:int,subType:int) {
      setup(x,y,subType);
      
      _needsToFall = (isFloatingItem() == false);
      
      // used for bouncing, floating items
      _bounceOscillator.x = Math.random()*Math.PI;
      _bounceOscillator.y = Math.random()*Math.PI;
    }
    
    ////// COLLISION //////
    
    public override function touchedPlayer(p1:Player): void {
      switch(_subType) {
        case c.ITEM_TYPE_DROP:
          c.playSound(c.waterdropSND);
          p1.score += 10;
          p1.health += 1;
          _readyToBeRemoved = true;
          c.setRectFromBitmap(c.waterdropBMP,_pos); // sets area particles will come out of
          c.pfx.spawnSet(17,c.PFX_TYPE_PRANGY_SKIN); // prangy's blue skin doubles as water effect
          return;
        case c.ITEM_TYPE_ARM:
          c.playSound(c.prangyarmSND);
          p1.score += 100;
          p1.keys++; // allows  the player past 1 prangy
          _readyToBeRemoved = true;
          c.setRectFromBitmap(c.prangyArmBMP,_pos); // sets area particles will come out of
          c.pfx.spawnSet(20,c.PFX_TYPE_PRANGY_SHIRT);
          return;
        case c.ITEM_TYPE_PRANGY:
          if(p1.keys > 0) { // have at least 1 arm to give this prangy?
            c.playSound(c.prangypopSND);
            p1.score += 500;
            p1.keys--;
            _readyToBeRemoved = true;
            c.setRectFromBitmap(c.prangyBMP,_pos); // sets area particles will come out of
            c.pfx.spawnSet(35,c.PFX_TYPE_PRANGY_SKIN);
            c.pfx.spawnSet(30,c.PFX_TYPE_PRANGY_SHIRT);
            c.pfx.spawnSet(20,c.PFX_TYPE_PRANGY_ARMOR);
            c.aliensToHeal--;
            if(c.aliensToHeal == 0) {
              c.playSound(c.winSND);
            }
          } else { // don't have an arm, so prangy won't allow player to pass
            c.playSound(c.prangyblockSND);
            p1.pushAway(this);
          }
          return;
      }
    }

    public override function moveAndDraw(p1:Player,quadTree:QuadTree,toBuffer:BitmapData): void {
      if(isFloatingItem()) {
        var wasX:Number = _pos.x;
        var wasY:Number = _pos.y;
        
        oscillate();
        c.centerBitmapOfPosOntoBuffer(c.bitmapForType(c.STARTCOORD_TYPE_ITEM,_subType),_pos,toBuffer);
        
        _pos.x = wasX; // undoing the oscillation, keeping it relative, in order to avoid drift
        _pos.y = wasY;
      } else {
        c.centerBitmapOfPosOntoBuffer(c.bitmapForType(c.STARTCOORD_TYPE_ITEM,_subType),_pos,toBuffer);
      }
      
      // these next two calls are looking at c.drawRect as collision data - must come after draw!
      p1.touchedCheck(this);
      
      // checks whether object needs to fall to ground level, and if so, does
      if(_needsToFall) {
        fakeFall(quadTree);
      }
    }

    ////// SUPPORT FUNCTIONS //////

    private function isFloatingItem(): Boolean {
      return (_subType == c.ITEM_TYPE_DROP);
    }
    
    private function oscillate(): void {
      if(isFloatingItem() == false) {
        return;
      }
      _bounceOscillator.x += Math.random()*0.03+0.05;
      _bounceOscillator.y += Math.random()*0.05+0.1;
      _pos.x += 1.5*Math.sin(_bounceOscillator.x);
      _pos.y += 2.0*Math.sin(_bounceOscillator.y);
    }
    
    // used to instantly move a non-floating item to ground level
    private function fakeFall(quadTree:QuadTree): void {
      const testingFallIncrement:Number = 1.5;
      while(_needsToFall) {
        if(c.drawRect.y+c.drawRect.height >= c.levelBottom) {
          _needsToFall = false; // ground has been found
          return;
        } else {
          var levArray:Array = quadTree.uniqueCollOverlaps(c.drawRect);
      
          for each(var chunk:LevChunk in levArray) {
            if(chunk.overlapsDrawRect()) {
              _needsToFall = false; // ground (object) found
              return;
            }
          }
        }
        c.drawRect.y += testingFallIncrement; // moving down the collision detection
        _pos.y += testingFallIncrement; // moving down the position at the same time
      }
    }
    
  }
}