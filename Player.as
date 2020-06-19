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

// Moves and draws the player character. Input is handled here, but caught in FlashPlatform.as
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Rectangle;
  import flash.geom.Point;
  import flash.media.Sound;
  
  public class Player
  {
    private var _onGround:Boolean;
    private var _pos:Point = new Point();
    private var _vel:Point = new Point();
    private var _jumpHold:int;
    private var _editorFlying:Boolean;

    private var _freshOffGround:int; // still allow jumping shortly after a fall
    private var _score:int;
    private var _health:int;
    private var _keys:int;
    private var _recovering:int;

    private var _animHold:int;
    private var _animFrame:int;
    private var _collisionBox:Rectangle = new Rectangle();
    private var _collisionSideT:Rectangle = new Rectangle();
    private var _collisionSideR:Rectangle = new Rectangle();
    private var _collisionSideL:Rectangle = new Rectangle();
    private var _collisionSideB:Rectangle = new Rectangle();
    
    public function Player() {
      _pos.x = 400;
      _pos.y = 700;

      _collisionBox.width = c.PLAYER_WIDTH;
      _collisionBox.height = c.PLAYER_HEIGHT;
      
      _collisionSideB.width = _collisionSideT.width = c.PLAYER_WIDTH/2;
      _collisionSideT.height = c.PLAYER_JUMP_FORCE+5;
      _collisionSideB.height = c.MAX_FALL_SPEED+5;
      _collisionSideR.width = _collisionSideL.width = c.PLAYER_WIDTH/2;
      _collisionSideR.height = _collisionSideL.height = c.PLAYER_HEIGHT-_collisionSideT.height-_collisionSideB.height;

      reset();
    }
    
        ////// MOVEMENT //////
    
    public function move(quadTree:QuadTree): void {
      if(c.levelEditor == c.EDITOR_PIECE) {
        _pos.x=0;
        _pos.y=0;
        return;
      }

      if(_vel.x < -c.PLAYER_RUN_MAX) {
        _vel.x = -c.PLAYER_RUN_MAX;
      }
      if(_vel.x > c.PLAYER_RUN_MAX) {
        _vel.x = c.PLAYER_RUN_MAX;
      }
      
      _pos.x += _vel.x;
      
      if(_onGround) {
        _vel.x *= c.PLAYER_RUN_DECAY;
      } else {
        _vel.x *= c.PLAYER_LATERAL_AIRSPEED_DECAY;
      }
      if(_pos.x < c.levelLeft+c.PLAYER_WIDTH/2) {
        _pos.x = c.levelLeft+c.PLAYER_WIDTH/2;
        if(_vel.x <= 0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
      if(_pos.x >= c.levelRight-c.PLAYER_WIDTH/2) {
        _pos.x = c.levelRight-c.PLAYER_WIDTH/2;
        if(_vel.x >= 0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
      
      if(_recovering > 0) {
        _recovering--;
      }

      if(_onGround == false) {
        _vel.y += c.GRAV;
        if(_vel.y > c.MAX_FALL_SPEED) {
          _vel.y = c.MAX_FALL_SPEED;
        }
      }
      _pos.y += _vel.y;
      
      var wasOnGround:Boolean = _onGround; // used to catch transition, for sound playing
      
      _onGround = false; // assume we're off the ground until we prove otherwise
      
      if(_pos.y < c.levelTop+c.PLAYER_HEIGHT/2) {
        _pos.y = c.levelTop+c.PLAYER_HEIGHT/2;
        if(_vel.y <= 0) {
          _vel.y = 0.0;
          _jumpHold = 0;
        }
      }
      if(_pos.y >= c.levelBottom-c.PLAYER_HEIGHT/2) {
        _pos.y = c.levelBottom-c.PLAYER_HEIGHT/2;
        if(_vel.y >= 0) {
          _vel.y = 0.0;
          _onGround = true;
        }
      } 
      
      _collisionBox.x = _pos.x-_collisionBox.width/2;
      _collisionBox.y = _pos.y-_collisionBox.height/2;
      
      if(quadTree != null) {
        var overlapping:Array = quadTree.uniqueCollOverlaps(_collisionBox);
        for each(var chunk:LevChunk in overlapping) {
          LevChunk.collisionsOnly(this,chunk);
        }
      }
      
      if(_freshOffGround > 0) {
        _freshOffGround--;
      }
      
      if(wasOnGround && _onGround == false) {
        if(_vel.y >= 0 && _vel.y < c.PLAYER_GROUND_HUG_FORCE) {
          _vel.y = c.PLAYER_GROUND_HUG_FORCE; // keeps the player tight against steps, downward hills
        }
        _freshOffGround = c.PLAYER_WALKS_OFF_EDGE_CAN_STILL_JUMP_CYCLES;
      }
      if(_onGround && wasOnGround == false && c.levelEditor == c.EDITOR_PLAY) {
        if(_freshOffGround == 0) { // check to avoid landing sound when running down shallow slope
          c.playSound(c.landSND);
        }
      }
    }
    
    ////// INPUT //////
    
    // allow flying in editor
    public function editorFloatInput(up:Boolean,left:Boolean,down:Boolean,right:Boolean): void {
      if(left) {
        _pos.x -= c.MAX_FALL_SPEED;
      }
      if(right) {
        _pos.x += c.MAX_FALL_SPEED;
      }

      if(up) {
        _pos.y -= c.MAX_FALL_SPEED;
      }
      if(down) {
        _pos.y += c.MAX_FALL_SPEED;
      }
      
      _editorFlying = up || down || left || right;
      
      if(_editorFlying) {
        _vel.y = -c.GRAV; // offset gravity
      }
    }
    
    public function input(jump:Boolean,left:Boolean,right:Boolean): void {
      if(jump) {
        if(_onGround || _freshOffGround > 0) {
          if(c.levelEditor == c.EDITOR_PLAY) {
            c.playSound(c.jumpSND);
          }
          _freshOffGround = 0; // disallow double jump
          _vel.y = -c.PLAYER_JUMP_FORCE;
          _onGround = false;
          _jumpHold = c.PLAYER_JUMP_HOLD;
        } else if(_jumpHold-- > 0) {
          _vel.y = -c.PLAYER_JUMP_FORCE;
        }
      } else if(!_onGround) {
        _jumpHold = 0;
      }
      
      if(_jumpHold < 0) {
        _jumpHold=0;
      }

      if(left && right) {
        // do nothing
      } else if(left) {
        _vel.x -= c.PLAYER_RUN_ACCEL;
      } else if(right) {
        _vel.x += c.PLAYER_RUN_ACCEL;
      }
      
      if(_animHold-- < 0) {
        if(++_animFrame >= c.PLAYER_FRAME_COUNT) {
          _animFrame = 0;
        }
        _animHold = c.ANIM_FRAME_HOLD;
      }
    }
    
    
    ////// RESET FUNCTIONS //////

    // this does not affect player placement (no respawn)
    public function reset(): void {
      _editorFlying = false;
      _vel.x = 0;
      _vel.y = 0;
      _onGround = false;
      _freshOffGround = 0;
      _jumpHold = 0;
      _recovering = 0;
      
      _animHold = 0;
      _animFrame = 0;
      
      _health = c.PLAYER_MAX_HEALTH;
      _keys = 0;
    }
    
    // happens at game start, and when player runs out of health
    public function resetScore(): void {
      _score = 0;
    }
    
    ////// COLLISIONS ////// 
    
    public function handleCollisionWithPiece(lev:Piece): void {
      if(_editorFlying) {
        return;
      }
      // need to recalc here in case collisions with other brushes this frame moved the body
      updateCollision();
      
      if(lev.intersects(_collisionSideT)) {
        _pos.y = lev.y+lev.height+c.PLAYER_HEIGHT/2;
        _jumpHold = 0;
        if(_vel.y < 0.0) {
          _vel.y = 0.0;
        }
      }
      if(lev.intersects(_collisionSideB)) {
        _pos.y = lev.y-c.PLAYER_HEIGHT/2+1;
        if(_vel.y > 0.0) {
          _vel.y = 0.0;
        }
        _onGround = true;
      }
      if(lev.intersects(_collisionSideL)) {
        _pos.x = lev.x+lev.width+c.PLAYER_WIDTH/2;
        if(_vel.x < 0.0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
      if(lev.intersects(_collisionSideR)) {
        _pos.x = lev.x-c.PLAYER_WIDTH/2;
        if(_vel.x > 0.0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
    }
    
    public function updateCollision(): void {
      _collisionBox.x = _pos.x-_collisionBox.width/2;
      _collisionBox.y = _pos.y-_collisionBox.height/2;
      _collisionSideB.x = _collisionSideT.x = _collisionBox.x + c.PLAYER_WIDTH/4;
      _collisionSideL.x = _collisionBox.x;
      _collisionSideT.y = _collisionBox.y;
      _collisionSideB.y = _collisionBox.y+_collisionBox.height-_collisionSideB.height;
      _collisionSideR.y = _collisionSideL.y = _collisionSideT.y+_collisionSideT.height;
      _collisionSideR.x = _collisionBox.x+_collisionSideL.width;
    }
    
    // shows collision box, handy for debugging collision-to-visual fit
    private function draw_collisionBox(toBuffer:BitmapData): void {
      c.drawRect.x = _collisionBox.x-c.camera.x;
      c.drawRect.y = _collisionBox.y-c.camera.y;
      c.drawRect.width = _collisionBox.width;
      c.drawRect.height = _collisionBox.height;

      c.drawRect.height=3;
      toBuffer.fillRect( c.drawRect, 0 );
      c.drawRect.y += c.PLAYER_HEIGHT;
      toBuffer.fillRect( c.drawRect, 0 );
      c.drawRect.y -= c.PLAYER_HEIGHT;
      c.drawRect.height = c.PLAYER_HEIGHT;
      c.drawRect.width = 3;
      toBuffer.fillRect( c.drawRect, 0 );
      c.drawRect.x += c.PLAYER_WIDTH;
      toBuffer.fillRect( c.drawRect, 0 );
    }
    
    // expects that Item/Enemy was drawn immediately prior (to set the common collision box)
    public function touchedCheck(element:*): Boolean {
      var touching:Boolean = (_collisionBox.intersects(c.drawRect));
      
      if(touching) {
        updateCollision();
        if(_collisionSideB.intersects(c.drawRect)) { // touching player's feet?
          if(_onGround || _freshOffGround>0) {
            touching = false; // prevents enemies from getting player through thin floor
          } else if(element.jumpedOnByPlayer(this)) {
            _vel.y = -c.PLAYER_JUMP_FORCE;
          }
        } else {
          element.touchedPlayer(this);
        }
      }

      return touching;
    }

    // included here since it's a functional aspect of collision handling
    public function pushAway(pushedBy:PlayerTouchableThing): void {
      if(c.levelEditor == c.EDITOR_PLAY) {
        c.playSound(c.hurtSND);
      }

      _vel.x = pos.x-pushedBy.pos.x;
      _vel.y = pos.y-pushedBy.pos.y;
      _vel.normalize(c.PLAYER_BUMP_THROW_FORCE);
      
      // enforce a minimum lateral throw value, to prevent the player from bouncing atop it
      if(Math.abs(_vel.x) < c.PLAYER_BUMP_THROW_LATERAL_MIN) {
        if(_vel.x < 0) {
          _vel.x = -c.PLAYER_BUMP_THROW_LATERAL_MIN;
        } else {
          _vel.x = c.PLAYER_BUMP_THROW_LATERAL_MIN;
        }
      }
    }
    
    ////// RENDERING //////

    public function draw(toBuffer:BitmapData): void {
      var useBitmap:Bitmap = c.stand_1_BMP;
      
      if(_recovering > 0) {
        if(_recovering%5 < 2) { // flicker while recovering from damage
          return;
        }
      }

      if(_onGround == false && _freshOffGround == 0) { // in air, and it's not just a tiny bump/step
        if(_vel.y < -c.PLAYER_ANIM_VERT_THRESHOLD) { // jumping up 
            useBitmap = c.riseBMP;
        } else if(_vel.y > c.PLAYER_ANIM_VERT_THRESHOLD) { // falling down
            useBitmap = c.fallBMP;
        } else { // "float"
            useBitmap = c.floatBMP;
        }
      } else if(Math.abs(_vel.x)<c.PLAYER_ANIM_STANDING_THRESHOLD) { // standing still
          useBitmap = (_animFrame%2 == 1 ? c.stand_1_BMP : c.stand_2_BMP);
      } else switch(_animFrame) { // walking
        case 0:
          useBitmap = c.run_1_BMP;
          break;
        case 1:
          useBitmap = c.run_2_BMP;
          break;
        case 2:
          useBitmap = c.run_3_BMP;
          break;
        case 3:
        default:
          useBitmap = c.run_4_BMP;
          break;
      }

      // outlines collision box. For debugging collision during development
      if(c.levelEditor == c.EDITOR_LEVEL) {
        toBuffer.lock();
        draw_collisionBox(toBuffer);
        toBuffer.unlock();
      }
      
      c.centerBitmapOfPosOntoBuffer(useBitmap,_pos,toBuffer,false,_vel.x<0);
    }

    ////// GETTERS AND SETTERS //////
    
    public function doneJumping(): Boolean {
      return _jumpHold == 0;
    }

    public function get score(): int {
      return _score;
    }
    
    public function set score(newVal:int): void {
      _score = newVal;
      if(_score < 0) {
        _score = 0;
      }
    }
    
    public function get health(): int {
      return _health;
    }
    
    public function set health(newVal:int): void {
      if(_health > newVal) { // losing health?
        if(_recovering > 0) {
          return;
        }
        _recovering = c.PLAYER_RECOVER_TIME;
      }
      _health = newVal;
      if(_health > c.PLAYER_MAX_HEALTH) {
        _health = c.PLAYER_MAX_HEALTH;
      }
      if(_health < 0) {
        _health = 0;
        // dead! Gets checked after all enemy collisions are handled...
      }
    }
    
    public function get keys(): int {
      return _keys;
    }
    
    public function set keys(newVal:int): void {
      _keys = newVal;
    }
    
    public function get isRecovering(): Boolean {
      return (_recovering > 0);
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
    
    public function get collisionRect(): Rectangle {
      return _collisionBox;
    }
  }
}