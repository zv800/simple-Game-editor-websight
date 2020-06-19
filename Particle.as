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

// A single particle. See ParticleSet for the more interesting stuff: managing all Particles.
// Note that these effects are purely decorative, and have no impact on the world or characters.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  
  public class Particle
  {
    private var _timeAlive:Number, _initialTA:Number; // current and initial lifetime, in cycles
    public var type:int; // which variety of particle
    public var px:Number, py:Number; // position x, y
    public var ang:Number; // angle
    public var sz:Number; // size
    private var _xv:Number, _yv:Number; // velocity x, y components
    private var _grav:Number; // gravity for this particle
    private var _omega:Number; // rate of rotation

    // no constructor necessary, values are all primatives and will be set before used
    public function Particle() {
    }
    
    // doesn't really "spawn" anything (in the memory sense), but fills in the data for this particle
    public function spawnAt(nx:Number,ny:Number,ntype:int): void {
      var rang:Number = Math.random()*Math.PI*2.0;
      var power:Number = Math.random()*ParticleSet.randForce+ParticleSet.minForce;
      px = nx;
      py = ny;
      type = ntype;
      _xv = power*Math.cos(rang);
      _yv = power*Math.sin(rang);
      _grav = ParticleSet.pGrav;
      ang = rang;
      sz = 1.0;
      _omega = Math.random()*0.6-0.3;
      _initialTA = _timeAlive = Math.random()*ParticleSet.randLife+ParticleSet.minLife;
    }
    
    // copies another particle's value onto this one
    public function cloneFrom(other:Particle): void {
      _timeAlive = other._timeAlive;
      _initialTA = other._initialTA;
      px = other.px;
      py = other.py;
      ang = other.ang;
      type = other.type;
      sz = other.sz;
      _xv = other._xv;
      _yv = other._yv;
      _grav = other._grav;
      _omega = other._omega;
    }
    
    // returns true when the particle is ready to be removed
    public function move(): Boolean {
      sz = _timeAlive/_initialTA;
      ang += _omega;
      _yv += _grav;
      px += _xv;
      py += _yv;
      return (_timeAlive--<0);
    }
  }
}