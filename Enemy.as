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

// "Enemy" describes any moving object in the world that the player can interact with.
// Several different patterns of common enemy AI are included:
//     -ENEMY_TYPE_MINE: Chase player when within a certain range, explode on contact.
//     -ENEMY_TYPE_BAT: Attach to ceiling, occasionally swoop down then return to ceiling.
//     -ENEMY_TYPE_DRAGON: "Sine wave" pattern, moving through walls/floors, left to right.
//     -ENEMY_TYPE_ICE: Hooks to ceiling, drops down when player is close enough.
//     -ENEMY_TYPE_RAM: Bounces off walls. Always maintains speed, always moves at 45 degree angle.
//     -ENEMY_TYPE_SEAHORSE: Hovers, periodically moving in short bursts.
//     -ENEMY_TYPE_SNAKE: Moves along ground, periodically flying up until hitting a ceiling.
//     -ENEMY_TYPE_SKULL: Chases player constantly but slowly, going through any obstacles.
//     -ENEMY_TYPE_SPRING: Sits still, periodically jumps.
//     -ENEMY_TYPE_WATER: Bounces vertically in place.
// There are a ton of ways that this code could be reorganized or refactored - to use a common
// collision functionality as the player (it's similar, though modified here in places), done as
// subclasses rather than switch-case enumeration (would help for less basic behaviors), etc.
// I erred in favor of this approach since it's (a) fast to do (b) puts them all in one place for
// easy comparison or mixing (and c) I assume that you will likely want to change or remove these 
// example enemies, anyhow, based on the sort of game that you would like to make.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  
  public class Enemy extends PlayerTouchableThing // gets position etc. from PlayerTouchableThing
  {
    private var _vel:Point; // x and y speed
    private var _animHold:int; // how many cycles left before advancing animation frame?
    private var _animFrame:int; // current animation frame
    private var _stateHold:int; // how many cycles left before re-evaluating AI/behavior state
    private var _stateTracker:int; // index corresponding to whether it's flying, sitting, etc.
    private var _graphicRotation:Number; // visual angle, which may or may not correlate to movement angle
    
    private var _collisionBox:Rectangle = new Rectangle();
    private var _collisionSideT:Rectangle = new Rectangle();
    private var _collisionSideR:Rectangle = new Rectangle();
    private var _collisionSideL:Rectangle = new Rectangle();
    private var _collisionSideB:Rectangle = new Rectangle();
    private var _leftBumper:Boolean;
    private var _rightBumper:Boolean;
    private var _topBumper:Boolean;
    private var _bottomBumper:Boolean;
    
    public function Enemy(x:int,y:int,subType:int) {
      _vel = new Point();
      setup(x,y,subType);
      
      _stateTracker = 0;
      _graphicRotation = 0.0;

      resetBumpers();

      _animFrame = 0;
      _animHold = int(c.ANIM_FRAME_HOLD*Math.random());
      
      switch(subType) {
        case c.ENEMY_TYPE_MINE: break;
        case c.ENEMY_TYPE_BAT:
          _stateTracker = c.ENEMY_STATE_FLYING;
          _vel.x = c.ENEMY_SPEED_BAT_X;
          if(Math.random() < 0.5) {
            _vel.x = -_vel.x;
          }
          _vel.y = c.ENEMY_SPEED_BAT_DIVE;
          break;
        case c.ENEMY_TYPE_DRAGON:
          _vel.x = c.ENEMY_SPEED_DRAGON;
          _stateTracker = _pos.y; // used to keep its vertical baseline
          break;
        case c.ENEMY_TYPE_ICE: 
          _vel.x = _vel.y = 0.0;
          _stateTracker = c.ENEMY_STATE_SURFACE;
          break;
        case c.ENEMY_TYPE_RAM: _vel.x = _vel.y = c.ENEMY_SPEED_RAM; break;
        case c.ENEMY_TYPE_SEAHORSE:
          _stateTracker = c.ENEMY_STATE_SURFACE;
          break;
        case c.ENEMY_TYPE_SNAKE: 
          _stateTracker = c.ENEMY_STATE_FLYING;
          break;
        case c.ENEMY_TYPE_SKULL: break;
        case c.ENEMY_TYPE_SPRING:
          _vel.x = _vel.y = 0.0;
          _stateTracker = c.ENEMY_STATE_FLYING;
          break;
        case c.ENEMY_TYPE_WATER:
          _vel.y = c.ENEMY_SPEED_WATER;
          break;
      }
      
      var bmp:Bitmap = c.bitmapForType(c.STARTCOORD_TYPE_ENEMY,_subType);
      
      _collisionBox.width = bmp.width;
      _collisionBox.height = bmp.height;
      
      if(_subType == c.ENEMY_TYPE_BAT) {
        _collisionBox.width /= 3; // make bat much narrower than its wingspan
      }
      
      _collisionSideB.width = _collisionSideT.width = _collisionBox.width/2;
      _collisionSideT.height = c.ENEMY_JUMP_FORCE+5;
      _collisionSideB.height = c.MAX_FALL_SPEED+5;
      _collisionSideR.width = _collisionSideL.width = _collisionBox.width/2;
      _collisionSideR.height = _collisionSideL.height = 
                              bmp.height-_collisionSideT.height-_collisionSideB.height;
    }
    
    ////// MOVEMENT //////
    
    private function moveByType(p1:Player,quadTree:QuadTree): void {
      _pos.x += _vel.x;
      _pos.y += _vel.y;
      
      _collisionBox.x = _pos.x-_collisionBox.width/2;
      _collisionBox.y = _pos.y-_collisionBox.height/2;
      if(wallCollidingType()) { // bounces off walls
        levelCollisions(quadTree);
      } else if(wrappingType()) { // wraps around level boundaries
        if(_pos.x > c.levelRight) {
          _pos.x = c.levelLeft;
        }
        if(_pos.x < c.levelLeft) {
          _pos.x = c.levelRight;
        }
        if(_pos.y > c.levelBottom) {
          _pos.y = c.levelTop;
        }
        if(_pos.y < c.levelTop) {
          _pos.y = c.levelBottom;
        }
      } else { // bounces off level boundaries
        if(_pos.x > c.levelRight) {
          _vel.x = -Math.abs(_vel.x);
        }
        if(_pos.x < c.levelLeft) {
          _vel.x = Math.abs(_vel.x);
        }
        if(_pos.y > c.levelBottom) {
          _vel.y = -Math.abs(_vel.y);
        }
        if(_pos.y < c.levelTop) {
          _vel.y = Math.abs(_vel.y);
        }
      }

      if(_animHold-- < 0) {
        if(++_animFrame >= my_animFrameCount()) {
          _animFrame = 0;
        }
        _animHold = c.ANIM_FRAME_HOLD;
      }
      
      switch(_subType) {
        case c.ENEMY_TYPE_MINE:
          if(Point.distance(_pos,p1.pos) < c.ENEMY_ENGAGEMENT_RANGE_MINE) { // within chase distance
            _graphicRotation += 0.45; // spin aggressively
            _animFrame = my_animFrameCount(); // force to stay lit
            _vel.x = p1.pos.x-_pos.x;
            _vel.y = p1.pos.y-_pos.y;
            _vel.normalize(c.ENEMY_SPEED_MINE);
          } else {
            _graphicRotation += 0.015; // spin slowly
            _vel.x *= 0.8; // gradually slow down
            _vel.y *= 0.8;
          }
          break;
        case c.ENEMY_TYPE_BAT:
          if(_stateTracker == c.ENEMY_STATE_FLYING) {
            _vel.y -= c.GRAV;
            if(_vel.y < -c.ENEMY_JUMP_FORCE) {
              _vel.y = -c.ENEMY_JUMP_FORCE;
            }
            if(_bottomBumper) {
              _vel.y = -c.ENEMY_JUMP_FORCE;
            }
            if(_topBumper) {
              _vel.x = _vel.y = 0.0;
              _stateTracker = c.ENEMY_STATE_SURFACE;
              _stateHold = c.ENEMY_STATE_TIME_MIN_BAT+Math.random()*c.ENEMY_STATE_TIME_RAND_BAT;
              if(c.camera.intersects(_collisionBox)) {
                c.playSound(c.icefallSND);
              }
            }
          } else { // c.ENEMY_STATE_SURFACE
            _animFrame=my_animFrameCount(); // force into cling position
            _vel.x = 0.0;
            _vel.y = 0.0;
            if(_stateHold-- < 0) {
              if(c.camera.intersects(_collisionBox)) {
                c.playSound(c.soarSND);
              }
              _stateTracker = c.ENEMY_STATE_FLYING;
              _vel.x = c.ENEMY_SPEED_BAT_X;
              if(p1.pos.x < _pos.x) {
                _vel.x = -_vel.x;
              }
              _vel.y = c.ENEMY_SPEED_BAT_DIVE+Math.random()*c.ENEMY_SPEED_BAT_DIVE_RAND_EXTRA;
            }
          }
          break;
        case c.ENEMY_TYPE_DRAGON:
          _pos.y = _stateTracker+60.0*Math.sin(_pos.x/45.0);
          _vel.y = 0.0;
          break;
        case c.ENEMY_TYPE_ICE:
          if(_stateTracker == c.ENEMY_STATE_FLYING) {
            _vel.y += c.GRAV;
            if(_vel.y > c.MAX_FALL_SPEED) {
              _vel.y = c.MAX_FALL_SPEED;
            }
            if(_bottomBumper) {
              if(c.camera.intersects(_collisionBox)) {
                c.playSound(c.prangypopSND);
              }
              _readyToBeRemoved = true;
              c.setRectFromBitmap(c.icespikeBMP,_pos); // sets area particles will come out of
              c.pfx.spawnSet(7,c.PFX_TYPE_PRANGY_SKIN);
              c.pfx.spawnSet(3,c.PFX_TYPE_SMOKE);
            }
          } else { // c.ENEMY_STATE_SURFACE
            if(Math.abs(p1.pos.x-_pos.x) < c.ENEMY_ENGAGEMENT_RANGE_ICE_X && p1.pos.y > _pos.y &&
                p1.pos.y-_pos.y < c.ENEMY_ENGAGEMENT_RANGE_ICE_Y) {
                if(c.camera.intersects(_collisionBox)) {
                  c.playSound(c.icefallSND);
                }
                _stateTracker=c.ENEMY_STATE_FLYING;
                _vel.y = c.ENEMY_SPEED_ICE;
            }
          }
          break;
        case c.ENEMY_TYPE_RAM:
          // lock into 45 degree angle movements
          if(_bottomBumper) {
            _vel.y = -c.ENEMY_SPEED_RAM;
            _pos.y += _vel.y;
          } else if(_topBumper) {
            _vel.y = c.ENEMY_SPEED_RAM;
            _pos.y += _vel.y;
          }
          if(_rightBumper) {
            _vel.x = -c.ENEMY_SPEED_RAM;
            _pos.x += _vel.x;
          } else if(_leftBumper) {
            _vel.x = c.ENEMY_SPEED_RAM;
            _pos.x += _vel.x;
          }
          break;
        case c.ENEMY_TYPE_SEAHORSE:
          if(_stateTracker == c.ENEMY_STATE_FLYING) {
            _vel.x *= 0.9;
            _vel.y *= 0.9;
            if(_vel.length < 0.6) {
              _stateTracker = c.ENEMY_STATE_SURFACE;
              _stateHold = c.ENEMY_STATE_TIME_MIN_SEAHORSE+Math.random()*c.ENEMY_STATE_TIME_RAND_SEAHORSE;
            }
          } else { // c.ENEMY_STATE_SURFACE
            if(_stateHold-- < 0) {
              _stateTracker = c.ENEMY_STATE_FLYING;
              if(Math.random() < 0.3) {
                _vel.x = p1.pos.x-_pos.x;
                _vel.y = p1.pos.y-_pos.y;
              } else {
                _vel.x = Math.random()-0.5;
                _vel.y = Math.random()-0.5;
              }
              _vel.normalize(c.ENEMY_SPEED_SEAHORSE);
            }
          }
          break;
        case c.ENEMY_TYPE_SNAKE:
          if(_stateTracker == c.ENEMY_STATE_SURFACE) {
            _animFrame=my_animFrameCount(); // force into roll up position
            _graphicRotation += 0.3;
            
            if(Math.abs(_vel.x) < c.ENEMY_SPEED_SNAKE) {
              _vel.x = c.ENEMY_SPEED_SNAKE;
              if(Math.random() < 0.5) {
                _vel.x = -_vel.x;
              }
            }
            
            if(_bottomBumper) {
              if(_stateHold-- < 0) {
                _stateTracker = c.ENEMY_STATE_FLYING;
                if(c.camera.intersects(_collisionBox)) {
                  c.playSound(c.soarSND);
                }
              }
              _vel.y = 0.0;
            } else {
              _vel.y += c.GRAV;
              if(_vel.y > c.MAX_FALL_SPEED) {
                _vel.y = c.MAX_FALL_SPEED;
              }
            }
            
          } else { // c.ENEMY_STATE_FLYING
            _graphicRotation = 0.0;
            _vel.x = 0.0;
            _vel.y = -c.ENEMY_SPEED_SNAKE;

            if(_topBumper) {
              if(c.camera.intersects(_collisionBox)) {
                c.playSound(c.bouncingenemySND);
              }
              _stateTracker = c.ENEMY_STATE_SURFACE;
              _stateHold = c.ENEMY_STATE_TIME_MIN_SNAKE+Math.random()*c.ENEMY_STATE_TIME_RAND_SNAKE;
              _animFrame = 0;
            }
          }
          break;
        case c.ENEMY_TYPE_SKULL:
          _vel.x = p1.pos.x-_pos.x;
          _vel.y = p1.pos.y-_pos.y;
          _vel.normalize(c.ENEMY_SPEED_SKULL);
          break;
        case c.ENEMY_TYPE_SPRING:
          if(_stateTracker == c.ENEMY_STATE_FLYING) {
            if(_vel.y < -c.ENEMY_SPEED_SPRING_JUMP/2) {
              _animFrame = 2; // fully uncoiled
            } else {
              _animFrame = 1; // partly uncoiled
            }
            _vel.y += c.GRAV;
            if(_vel.y > c.MAX_FALL_SPEED) {
              _vel.y = c.MAX_FALL_SPEED;
            }
            if(_bottomBumper && _vel.y > 0) {
              _vel.x = _vel.y = 0.0;
              _stateTracker = c.ENEMY_STATE_SURFACE;
              _stateHold = c.ENEMY_STATE_TIME_MIN_SPRING+Math.random()*c.ENEMY_STATE_TIME_RAND_SPRING;
            }
          } else { // c.ENEMY_STATE_SURFACE
            _animFrame=0; // force into sit position
            _vel.x = 0.0;
            _vel.y = 0.0;
            if(_stateHold-- < 0) {
              _stateTracker = c.ENEMY_STATE_FLYING;
              _vel.x = c.ENEMY_SPEED_SPRING_X;
              if(p1.pos.x < _pos.x) {
                _vel.x = -_vel.x;
              }
              _vel.y = -(c.ENEMY_SPEED_SPRING_JUMP+Math.random()*c.ENEMY_SPEED_SPRING_JUMP_RAND_EXTRA);
              if(c.camera.intersects(_collisionBox)) {
                c.playSound(c.springSND);
              }
            }
          }
          break;
        case c.ENEMY_TYPE_WATER:
          _vel.y += c.GRAV;
          if(_vel.y > c.MAX_FALL_SPEED) {
            _vel.y = c.MAX_FALL_SPEED;
          }
          if(_bottomBumper) {
            _vel.y = -c.ENEMY_SPEED_WATER;
            if(c.camera.intersects(_collisionBox)) {
              c.playSound(c.bouncingenemySND);
            }
          } else if(_topBumper && _vel.y < 0.0) {
            _vel.y = 0.0;
          }
          break;
      }
    }
    
    ////// COLLISION WITH LEVEL //////

    public function handleCollisionWithPiece(lev:Piece): void {
      // need to recalc here in case collisions with other brushes this frame moved the body
      updateCollision();
      
      if(lev.intersects(_collisionSideT)) {
        _topBumper = true;
        _pos.y = lev.y+lev.height+_collisionBox.height/2;
        if(_vel.y < 0.0) {
          _vel.y = 0.0;
        }
      }
      if(lev.intersects(_collisionSideB)) {
        _bottomBumper = true;
        _pos.y = lev.y-_collisionBox.height/2+1;
        if(_vel.y > 0.0) {
          _vel.y = 0.0;
        }
      }
      if(lev.intersects(_collisionSideL)) {
        _leftBumper = true;
        _pos.x = lev.x+lev.width+_collisionBox.width/2;
        if(_vel.x < 0.0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
      if(lev.intersects(_collisionSideR)) {
        _rightBumper = true;
        _pos.x = lev.x-c.PLAYER_WIDTH/2;
        if(_vel.x > 0.0) {
          _vel.x = -c.LATERAL_BOUNCE*_vel.x;
        }
      }
    }
    
    private function levelCollisions(quadTree:QuadTree): void {
      resetBumpers();
      
      // check edges
      if(_pos.x + _collisionBox.width/2 > c.levelRight) {
        _pos.x = c.levelRight - _collisionBox.width/2;
        _vel.x = -Math.abs(_vel.x);
        _rightBumper = true;
      }
      if(_pos.x - _collisionBox.width/2 < c.levelLeft) {
        _pos.x = c.levelLeft + _collisionBox.width/2;
        _vel.x = Math.abs(_vel.x);
        _leftBumper = true;
      }
      if(_pos.y + _collisionBox.height/2 > c.levelBottom) {
        _pos.y = c.levelBottom - _collisionBox.height/2;
        _bottomBumper = true;
      }
      if(_pos.y - _collisionBox.height/2 < c.levelTop) {
        _pos.y = c.levelTop + _collisionBox.height/2;
        _topBumper = true;
      }
      
      var overlapping:Array = quadTree.uniqueCollOverlaps(_collisionBox);
      for each(var chunk:LevChunk in overlapping) {
        LevChunk.collisionsOnly(this,chunk);
      }
    }
    
    ////// COLLISION WITH PLAYER //////
    
    
    public override function jumpedOnByPlayer(p1:Player): Boolean {
      if(p1.isRecovering) { // go through enemies while in recovery
        return false;
      }
      
      // dole out points for the destroyable units
      switch(_subType) {
        case c.ENEMY_TYPE_BAT:
          p1.score += 550;
          break;
        case c.ENEMY_TYPE_RAM:
          p1.score += 350;
          break;
        case c.ENEMY_TYPE_SEAHORSE:
          p1.score += 450;
          break;
        case c.ENEMY_TYPE_SNAKE:
          p1.score += 150;
          break;
        case c.ENEMY_TYPE_SPRING:
          p1.score += 250;
          break;
      }

      switch(_subType) {
        // enemies that can be jumped on to be defeated:
        case c.ENEMY_TYPE_BAT:
        case c.ENEMY_TYPE_RAM:
        case c.ENEMY_TYPE_SEAHORSE:
        case c.ENEMY_TYPE_SNAKE:
        case c.ENEMY_TYPE_SPRING:
          _readyToBeRemoved = true;
          c.pfx.spawnSet(4,c.PFX_TYPE_SMOKE);
          c.pfx.spawnSet(3,c.PFX_TYPE_SPARK);
          c.playSound(c.prangypopSND);
          return true; // return true, give the player an upward bump
          
        // enemies that cannot be jumped on to be defeated:
        case c.ENEMY_TYPE_MINE:
          touchedPlayer(p1);
          return true; // returning true; mine can propel the player upward if jumped on
        case c.ENEMY_TYPE_SKULL:
        case c.ENEMY_TYPE_ICE:
        case c.ENEMY_TYPE_DRAGON:
        case c.ENEMY_TYPE_WATER:
        default:
          touchedPlayer(p1);
          return false; // no upward bump to player
      }
    }
    
    public override function touchedPlayer(p1:Player): void {
      if(p1.isRecovering == false) { // if the player recently took damage, give them a break

        if(_subType == c.ENEMY_TYPE_SPRING) {
          if(_stateTracker == c.ENEMY_STATE_SURFACE) {
            _stateHold=-1; // sleeping spring enemy jumps when bumped
          }
        }

        p1.pushAway(this); // throw the player back
        p1.health--; // decrease health
        c.setRectFromBitmap(c.stand_1_BMP,p1.pos); // sets area particles will come out of
        c.pfx.spawnSet(6,c.PFX_TYPE_SMOKE); // dust cloud
        p1.score -= 5; // slightly penalize score
      } else {
        return; // don't let a mine detonate while the player is recovering
      }
      
      if(_subType == c.ENEMY_TYPE_MINE) { // if mine, blow up
        if(c.camera.intersects(_collisionBox)) { // sound (if on screen)
          c.playSound(c.mineblastSND);
        }

        c.setRectFromBitmap(c.airmineBMP,_pos); // sets area that these next particles will come from
        c.pfx.spawnSet(35,c.PFX_TYPE_TINYFIRE);
        c.pfx.spawnSet(20,c.PFX_TYPE_BIGFIRE);
        c.pfx.spawnSet(10,c.PFX_TYPE_SMOKE);
        _readyToBeRemoved = true; // remove it
      }
    }
    
    ////// COLLISION SUPPORT FUNCTIONS //////
    
    public function resetBumpers(): void {
      _leftBumper = false;
      _rightBumper = false;
      _topBumper = false;
      _bottomBumper = false;
    }
    
    public function updateCollision(): void {
      _collisionBox.x = _pos.x-_collisionBox.width/2;
      _collisionBox.y = _pos.y-_collisionBox.height/2;
      _collisionSideB.x = _collisionSideT.x = _collisionBox.x + _collisionBox.width/4;
      _collisionSideL.x = _collisionBox.x;
      _collisionSideT.y = _collisionBox.y;
      _collisionSideB.y = _collisionBox.y+4*_collisionBox.height/5-1;
      _collisionSideR.y = _collisionSideL.y = _collisionSideT.y+_collisionSideT.height;
      _collisionSideR.x = _collisionBox.x+_collisionSideL.width;
    }
    
    ////// MISC SUPPORT FUNCTIONS //////
    
    private function wrappingType(): Boolean {
      return (_subType == c.ENEMY_TYPE_DRAGON);
    }

    private function wallCollidingType(): Boolean {
      return (_subType != c.ENEMY_TYPE_DRAGON && 
              _subType != c.ENEMY_TYPE_SKULL);
    }
    
    private function rotatingType(): Boolean {
      return (_subType == c.ENEMY_TYPE_WATER || _subType == c.ENEMY_TYPE_MINE);
    }
    
    // returns the number of frames that loop by time - positional/state frames don't count
    private function my_animFrameCount(): int {
      switch(_subType) {
        case c.ENEMY_TYPE_MINE: return 2;
        case c.ENEMY_TYPE_BAT: return 3;
        case c.ENEMY_TYPE_DRAGON: return 1;
        case c.ENEMY_TYPE_ICE: return 1;
        case c.ENEMY_TYPE_RAM: return 1;
        case c.ENEMY_TYPE_SEAHORSE: return 2;
        case c.ENEMY_TYPE_SNAKE: return 2;
        case c.ENEMY_TYPE_SKULL: return 2;
        case c.ENEMY_TYPE_SPRING:  return 1;
        case c.ENEMY_TYPE_WATER: return 2;
        default: return 1;
      }
    }
    
    ////// RENDERING //////

    public override function moveAndDraw(p1:Player,quadTree:QuadTree,toBuffer:BitmapData): void {
      c.centerBitmapOfPosOntoBuffer(
            c.bitmapForType(c.STARTCOORD_TYPE_ENEMY,_subType,_animFrame),_pos,
            toBuffer,false,_vel.x < 0,(rotatingType() && _vel.y > 0),_graphicRotation);
            
      // these next two calls are looking at c.drawRect as collision data - must come after draw!
      moveByType(p1,quadTree);
      p1.touchedCheck(this);
    }
    
    ////// GETTER //////

    public function get collisionRect(): Rectangle {
      return _collisionBox;
    }
  }
}