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

// A manager for a list of Particle Effects. It spawns groups, moves all of them, iterates
// through drawing all particles, and can clear the entire set. Also handles individual removal.
// Note that these effects are purely decorative, and have no impact on the world or characters.
// Also be aware of the MAX_PARTICLES constant in c.as - that's the limit on simultaneous partilces.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.Point;
  
  public class ParticleSet
  {
    private var _allParticles:Array = new Array();
    private var _pfxImg:Array = new Array();
    private var _numberAlive:int;
    private var _tmpPt:Point = new Point();

    // public to simplify reaching these values from within spawning particles
    public static var minForce:Number;
    public static var randForce:Number;
    public static var minLife:Number;
    public static var randLife:Number;
    public static var pGrav:Number;

    public function ParticleSet() {
      // using a fixed number of particles, to avoid on-the-fly allocation/deallocation for pfx
      for(var i:int=0; i<c.MAX_PARTICLES; i++) {
        _allParticles.push(new Particle());
      }

      // connect bitmaps to their corresponding indexes for quick lookup
      _pfxImg[c.PFX_TYPE_BIGFIRE] = c.fireBigBMP;
      _pfxImg[c.PFX_TYPE_TINYFIRE] = c.fireTinyBMP;
      _pfxImg[c.PFX_TYPE_PRANGY_ARMOR] = c.prangyArmorBMP;
      _pfxImg[c.PFX_TYPE_PRANGY_SHIRT] = c.prangyShirtBMP;
      _pfxImg[c.PFX_TYPE_PRANGY_SKIN] = c.prangySkinBMP;
      _pfxImg[c.PFX_TYPE_SMOKE] = c.smokeBMP;
      _pfxImg[c.PFX_TYPE_SPARK] = c.sparkBMP;

      clearAll();
    }

    // create some number of particles of a given type (ex. purpose: "8 smoke particles")
    // the particles are each positioned randomly within the common c.drawRect boundaries
    public function spawnSet(amt:int,ofType:int): void {
      var lastOne:int = _numberAlive + amt;
      if(lastOne >= c.MAX_PARTICLES) {
        lastOne = c.MAX_PARTICLES-1;
      }
      
      if(ofType != c.PFX_TYPE_SMOKE && ofType != c.PFX_TYPE_SPARK) {
        pGrav = c.GRAV/2;
      } else {
        pGrav = -c.GRAV/4;
      }

      switch(ofType) {
        case c.PFX_TYPE_BIGFIRE: minForce = 8.0; randForce = 3.5; 
                                 minLife = 11; randLife = 15; break;
        case c.PFX_TYPE_TINYFIRE: minForce = 10.0; randForce = 5.0; 
                                  minLife = 9; randLife = 10;  break;
        case c.PFX_TYPE_PRANGY_ARMOR: minForce = 10.0; randForce = 5.0; 
                                      minLife = 11; randLife = 15;  break;
        case c.PFX_TYPE_PRANGY_SHIRT: minForce = 6.0; randForce = 2.0; 
                                      minLife = 8; randLife = 10;  break;
        case c.PFX_TYPE_PRANGY_SKIN: minForce = 4.0; randForce = 1.0; 
                                     minLife = 6; randLife = 7;  break;
        case c.PFX_TYPE_SMOKE: minForce = 3.0; randForce = 3.0; 
                               minLife = 8; randLife = 7; break;
        case c.PFX_TYPE_SPARK: minForce = 4.0; randForce = 4.0; 
                               minLife = 3; randLife = 3;  break;

      }
      for(var i:int=_numberAlive; i<lastOne; i++) {
        _tmpPt.x = c.drawRect.x+Math.random()*c.drawRect.width;
        _tmpPt.y = c.drawRect.y+Math.random()*c.drawRect.height;
        _allParticles[i].spawnAt(_tmpPt.x,_tmpPt.y,ofType);
      }
      _numberAlive = lastOne;
    }
    
    // resets all particles. Important to do between levels
    public function clearAll(): void {
      _numberAlive = 0; // no need to wipe state of particles. this is all we need.
    }
    
    public function moveAndDraw(toBuffer:BitmapData): void {
      c.drawRect.width = 2;
      c.drawRect.height = 2;

      for(var i:int=0; i<_numberAlive; i++) {
        var particle:Particle = _allParticles[i];
        if(particle.move()) { // when particle is ready to be removed, returns true
          _numberAlive--; // decrease number of particles by 1
          if(_numberAlive >= 0) {
            _allParticles[i].cloneFrom(_allParticles[_numberAlive]); // copy the cut off end over it
            i--; // decrease counter by 1 to avoid skipping the one freshly copied over this spot
          }
          continue; // restart loop, in case the newly copied one also needs to be culled
        }
          
        // set position for graphic
        _tmpPt.x = particle.px;
        _tmpPt.y = particle.py;
        
        // draw it
        c.centerBitmapOfPosOntoBuffer(_pfxImg[particle.type],_tmpPt,toBuffer,false,false,false,
                                      particle.ang,particle.sz);
      }
    }
  }
}