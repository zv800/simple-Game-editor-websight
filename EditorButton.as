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

// This class is used to track position, graphics, state, and functionality of editor buttons.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.geom.ColorTransform;
  import flash.geom.Point;
  
  public class EditorButton
  {
    protected var _pos:Point = new Point();
    protected var _category:int;
    protected var _subType:int;
    
    public function EditorButton(x:int,y:int,category:int,subType:int) {
      _pos.x = x;
      _pos.y = y;
      _category = category;
      _subType = subType;
    }
    
    // functionality for each category/subType pairing
    public function handleClick(game:FlashPlatformer): void {
      switch(_category) {
        case c.EDITOR_BUTTON_TYPE_GENERAL:
          switch(_subType) {
            case c.EDITOR_BUTTON_NEW:
              if(c.levelEditor == c.EDITOR_LEVEL) {
                c.levXML = <level/>; // clear level
                game.readLevel();
              } else if(c.levelEditor == c.EDITOR_PIECE) {
                c.collisionRects = new Array(0);
              }
              return;
            case c.EDITOR_BUTTON_LOAD:
              if(c.levelEditor == c.EDITOR_LEVEL) {
                game.loadCustom();
              } else if(c.levelEditor == c.EDITOR_PIECE) {
                game.loadCustomColl();
              }
              return;
            case c.EDITOR_BUTTON_PLAY:
              if(c.levelEditor == c.EDITOR_LEVEL) {
                game.toPlay(true);
              }
              return;
            case c.EDITOR_BUTTON_SAVE:
              if(c.levelEditor == c.EDITOR_LEVEL) {
                game.saveLevel();
                c.releaseEditorControls();
              } else if(c.levelEditor == c.EDITOR_PIECE) {
                game.saveCollChunks();
              }
              return;
            case c.EDITOR_BUTTON_HELP:
              if(c.editButtonLockedIn) {
                c.editButtonLockedIn = false;
              } else {
                c.editButtonLockedIn = true;
              }
              return;
            case c.EDITOR_BUTTON_GRID:
              c.gridSnap = !c.gridSnap;
              return;
          }
          break;
        case c.EDITOR_BUTTON_TYPE_PLAYERSTART:
          game.stampOrActivate(_category,_subType);
          return;
        case c.EDITOR_BUTTON_TYPE_ENEMY:
          game.stampOrActivate(_category,_subType);
          return;
        case c.EDITOR_BUTTON_TYPE_ITEM:
          game.stampOrActivate(_category,_subType);
          return;
        case c.EDITOR_BUTTON_TYPE_CHUNK:
          if(c.levelEditor == c.EDITOR_PIECE) {
            c.setEditingChunkType(_subType); 
          } else {
            game.stampOrActivate(_category,_subType);
          }
          return;
        case c.EDITOR_BUTTON_TYPE_DECORTOGGLE:
          switch(_subType) {
            case c.EDITOR_TOP_BUTTON_DECOR:
              game.flipDecorMode();
              return;
            case c.EDITOR_TOP_BUTTON_SET:
              c.themeNum++;
              if(c.themeNum >= c.themeFolders.length) {
                c.themeNum=0;
              }
              game.loadAllCurrentThemeArt(); // load graphics for this themeNum
              return;
            case c.EDITOR_TOP_BUTTON_EDIT:
              if(c.levelEditor == c.EDITOR_PIECE) {
                c.levelEditor = c.EDITOR_LEVEL;
                c.setEditingChunkType(-1);
                game.readLevel(); // restore level
              } else {
                game.saveLevel(true); // don't export to file, just update XML
                c.levelEditor = c.EDITOR_PIECE;
                c.setEditingChunkType(0);
              }
              return;
          }
          break;
        case c.EDITOR_BUTTON_TYPE_DECOR:
          game.stampOrActivate(_category,_subType);
          return;
      }
    }
    
    ////// DISPLAY //////

    public function draw(toBuffer:BitmapData): void {
      drawButBack(_pos,toBuffer);
      if((c.editButtonLockedIn && c.editorButtonMousedOver == this) ||
         (c.editButtonLockedIn == false && c.drawRect.contains(c.mx_pregrid,c.my_pregrid)) ) {
        c.editorButtonMousedOver = this;
        c.fitBitmapOfPosOntoBuffer(c.selectBMP,_pos,toBuffer,1.0,true);
      }
      c.fitBitmapOfPosOntoBuffer(buttonBitmap(),_pos,toBuffer,1.0,true,true);
    }

    private function buttonBitmap(): Bitmap {
      switch(_category) {
        case c.EDITOR_BUTTON_TYPE_GENERAL:
          switch(_subType) {
            case c.EDITOR_BUTTON_NEW:
              return c.newBMP;
            case c.EDITOR_BUTTON_LOAD:
              return c.loadBMP;
            case c.EDITOR_BUTTON_PLAY:
              return c.playBMP;
            case c.EDITOR_BUTTON_SAVE:
              return c.saveBMP;
            case c.EDITOR_BUTTON_HELP:
              return c.helpBMP;
            case c.EDITOR_BUTTON_GRID:
              return c.gridBMP;
          }
          break;
        case c.EDITOR_BUTTON_TYPE_PLAYERSTART:
          return c.playerStartBMP;
        case c.EDITOR_BUTTON_TYPE_ENEMY:
          return c.bitmapForType(c.STARTCOORD_TYPE_ENEMY,_subType);
        case c.EDITOR_BUTTON_TYPE_ITEM:
          return c.bitmapForType(c.STARTCOORD_TYPE_ITEM,_subType);
        case c.EDITOR_BUTTON_TYPE_CHUNK:
          return c.bitmapForType(c.STARTCOORD_TYPE_LEVCHUNK,_subType);
        case c.EDITOR_BUTTON_TYPE_DECORTOGGLE:
          switch(_subType) {
            case c.EDITOR_TOP_BUTTON_DECOR:
              return c.decorBMP;
            case c.EDITOR_TOP_BUTTON_SET:
              return c.diffSetBMP;
            case c.EDITOR_TOP_BUTTON_EDIT:
              if(c.levelEditor == c.EDITOR_PIECE) {
                return c.pieceBackBMP;
              } else {
                return c.pieceEditBMP;
              }
          }
          break;
        case c.EDITOR_BUTTON_TYPE_DECOR:
          return c.bitmapForType(c.STARTCOORD_TYPE_DECOR,_subType);
      }
      return null;
    }
    
    // color coding button by functional grouping
    private function drawButBack(atPos:Point,toBuffer:BitmapData): void {
      var tempCT: ColorTransform = new ColorTransform;
      var low: Number = 0.4;
      var colorCat:int = _category;
      
      // in piece editor, highlight the save/load buttons with a special color to differentiate them
      if(_category == c.EDITOR_BUTTON_TYPE_GENERAL && c.levelEditor == c.EDITOR_PIECE) {
        if(_subType == c.EDITOR_BUTTON_LOAD || _subType == c.EDITOR_BUTTON_SAVE) {
          // enemies/items don't show in piece editor anyhow
          // I'm just setting it to enemy's color category so they stand out
          colorCat = c.EDITOR_BUTTON_TYPE_ENEMY;
        }
      }
      
      switch(colorCat) {
        case c.EDITOR_BUTTON_TYPE_GENERAL:
          tempCT.redMultiplier = 1.0;
          tempCT.greenMultiplier = low;
          tempCT.blueMultiplier = low;
          break;
        case c.EDITOR_BUTTON_TYPE_PLAYERSTART:
          tempCT.redMultiplier = 1.0;
          tempCT.greenMultiplier = 1.0;
          tempCT.blueMultiplier = low;
          break;
        case c.EDITOR_BUTTON_TYPE_ENEMY:
          tempCT.redMultiplier = low;
          tempCT.greenMultiplier = 1.0;
          tempCT.blueMultiplier = low;
          break;
        case c.EDITOR_BUTTON_TYPE_ITEM:
          tempCT.redMultiplier = low;
          tempCT.greenMultiplier = 1.0;
          tempCT.blueMultiplier = 1.0;
          break;
        case c.EDITOR_BUTTON_TYPE_CHUNK:
          tempCT.redMultiplier = 1.0;
          tempCT.greenMultiplier = 1.0;
          tempCT.blueMultiplier = 1.0;
          break;
        case c.EDITOR_BUTTON_TYPE_DECORTOGGLE:
          tempCT.redMultiplier = 1.0;
          tempCT.greenMultiplier = low;
          tempCT.blueMultiplier = 1.0;
          break;
        case c.EDITOR_BUTTON_TYPE_DECOR:
          tempCT.redMultiplier = low;
          tempCT.greenMultiplier = low;
          tempCT.blueMultiplier = 1.0;
          break;
      }
      c.centerBitmapOfPosOntoBuffer(c.butbackBMP,atPos,toBuffer,true,false,false,0.0,1.0,tempCT);
    }
    
    ////// SUPPORT FUNCTIONS //////
    
    // returns true if an EditorButton is a particular category & subType
    
    public function matches(category:int,subType:int): Boolean {
      return (_category == category && _subType == subType);
    }
    
    ////// GETTERS AND SETTERS //////
    
    public function get category(): int {
      return _category;
    }
    
    public function get subType(): int {
      return _subType;
    }
  }
}