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

// This is the program's main source file. Code begins execution first in "FlashPlatform()"
// then "constantUpdate()" is called every game frame. Only code called by at least one of
// those locations will be executed, unless called from an input event like "clickRespond()"
// or "keyRespond()". Both editor and gameplay logic are handled within this file - keep an
// eye out for if-statements checking for EDITOR_PLAY, and EDITOR_LEVEL, EDITOR_PIECE.

package {
  // tip: keep imports alphabetized! This makes it easier to scan for what's already there
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.display.Loader;
  import flash.events.Event;
  import flash.events.IOErrorEvent;
  import flash.events.KeyboardEvent;
  import flash.events.MouseEvent;
  import flash.events.TimerEvent;
  import flash.filters.BitmapFilterQuality;
  import flash.filters.GlowFilter;
  import flash.geom.Matrix;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.media.Sound;
  import flash.media.SoundChannel;
  import flash.media.SoundTransform;
  import flash.net.FileReference;
  import flash.net.URLLoader;
  import flash.net.URLLoaderDataFormat;
  import flash.net.URLRequest;
  import flash.text.TextField;
  import flash.text.TextFormat;
  import flash.utils.ByteArray;
  import flash.utils.Timer; 
  
  // width and height of the swf's rendering layer bitmap
  // keep these in sync with GAME_WIDTH and GAME_HEIGHT in c.as
  // note: frameRate is not 99 - it's 30 (see _constantAction) - but setting it high here helps
  [SWF(width="650", height="450", frameRate="99", backgroundColor="#EEEEEE")]
  public class FlashPlatformer extends Sprite 
  {
    private var _p1:Player = new Player();
    private var _itemList:Array = new Array(0); // positions of all items in gameplay
    private var _enemyList:Array = new Array(0); // positions of all enemies in gameplay
    
    // optimized data structure for in-game access to...
    private var _collQuad:QuadTree = null; // level collision objects (stairs, ramps)
    private var _decorQuadBG:QuadTree = null; // decorations in the background
    private var _decorQuadFG:QuadTree = null; // decorations in the foreground
    
    private var _objStart:Array = new Array(0); // positions of all objects in editor, file format
    
    // editor buttons along the...
    private var _editorBottomBut:Array = new Array(0); // bottom of the screen
    private var _editorTopChunkBut:Array = new Array(0); // top of screen for collision placement
    private var _editorTopDecorBut:Array = new Array(0); // top of screen for decoration placement
    
    private var _constantAction:Timer; // timer used to drive continuous action
    private var _RenderBMPMem:Bitmap; // game's render bitmap
    private var _RenderBMP:BitmapData;  // data for game's render bitmap

    // tracks keyboard state for gameplay keys
    private var _keyboardHold_Jump:Boolean = false;
    private var _keyboardHold_L:Boolean = false;
    private var _keyboardHold_R:Boolean = false;

    // tracks state of keys used to fly through walls in level editing mode
    private var _keyboardHold_W:Boolean = false;
    private var _keyboardHold_A:Boolean = false;
    private var _keyboardHold_S:Boolean = false;
    private var _keyboardHold_D:Boolean = false;
 
    private var _lastThemeOpened:String = ""; // prevents reloading theme art already in memory
    private var _lastFilenameOpened:String = "lev1.map"; // so save defaults to name last loaded
    private var _fileLoader:URLLoader = null; // 
    private var _file:FileReference = new FileReference(); // level save
    private var _decorMode:Boolean = false;
    private var _loadingColl:Boolean = false;
    private var _loadingLevel:Boolean = false;
    private var _levelNotFound:Boolean = false;
    private var _firstLoadingStillNeedsInit:Boolean = true;
    
    private var _musicChannel:SoundChannel = null; // used to stop music after it starts
    private var _musicPlaying:Boolean = true;
    
    // Personal request from engine developer/designer Chris DeLeon:
    // Please leave this little function in! This allows me to find out where on the
    // internet games based on this engine are being played, and with what frequency.
    // As of 2005, multiple MochiBot trackers can be added to a single SWF, so even if you
    // want to add a MochiBot tracker of your own, please leave this one in, too. Thanks!!!
    public function MochTime(event:Event): void {
      MochiBot.track(this, "2c9ea14d");
    }
    
    // this code gets called first, when the program starts. It's initializes and loads everything.
    public function FlashPlatformer()
    {
      this.addEventListener(Event.ADDED_TO_STAGE, MochTime); // please leave this! See notes above.

      stage.addEventListener(MouseEvent.CLICK, clickRespond);
      stage.addEventListener(KeyboardEvent.KEY_DOWN, keyRespond);
      stage.addEventListener(KeyboardEvent.KEY_UP, keyLetGo);
      
      c.pfx = new ParticleSet();
      
      _RenderBMP = new BitmapData(stage.stageWidth,stage.stageHeight, false, 0xffffff);

      _RenderBMPMem = new Bitmap(_RenderBMP);
      _RenderBMPMem.x = 0;
      _RenderBMPMem.y = 0;
      addChild(_RenderBMPMem);
      
      // game border
      graphics.lineStyle(2.0,0x000000);
      graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
      
      var format:TextFormat = new TextFormat();
      format.font = "Verdana";
      format.color = 0xffffff;
      format.size = 10;
      format.bold = true;
      c.ingameText.defaultTextFormat = format;
      c.ingameText.y = -2;
      
      var glowFilterArray:Array = new Array();
      glowFilterArray.push(new GlowFilter(0x000000,1.0,2.0,2.0,6,BitmapFilterQuality.HIGH));
      c.ingameText.filters = glowFilterArray; // produces a black outline around the text

      c.ingameText.text = "";
      c.ingameText.selectable = false;
      c.ingameText.width = stage.stageWidth;
      addChild(c.ingameText);

      _constantAction = new Timer(1000/30);
      _constantAction.addEventListener(TimerEvent.TIMER, constantUpdate);
      _constantAction.start();
      
      startMusic();
      
      loadColl();
      
      // screen area. x and y will be updated to achieve scrolling.
      // it's a rectangle instead of a vector/point so that we can use rectangle intersection
      // to easily cull offscreen graphics.
      c.camera.x = 0;
      c.camera.y = 0;
      c.camera.width = width;
      c.camera.height = height;
      
      // playable world area. The mouse can be used to click/move/drop these in level editor mode.
      c.levelLeft = 0;
      c.levelTop = 0;
      c.levelRight = width;
      c.levelBottom = height;
      
      initEditorHUDButtons();
    }
    
    // this function is called dozens of times a second - it's the heart of the game
    public function constantUpdate(evt:TimerEvent): void {
      if(c.loadingImage != -1) {
        bitmapOverScreen(null);
        c.ingameText.text = "Loading theme art ("+c.loadingImage+"/"+c.THEME_ART_NUM+")...";
        return;
      } else if(_loadingColl) {
        bitmapOverScreen(null);
        c.ingameText.text = "Loading collision data...";
        return;
      } else if(_loadingLevel) {
        bitmapOverScreen(null);
        c.ingameText.text = "Loading level...";
        return;
      } else if(_firstLoadingStillNeedsInit) {
        _firstLoadingStillNeedsInit = false;
        updateQuadTrees();
        if(c.START_IN_EDITOR) {
          toEditor(); // default into editor environment
          
          // start on help screen
          c.editButtonLockedIn = true;
          for each(var tempBut:EditorButton in _editorBottomBut) {
            if(tempBut.matches(c.EDITOR_BUTTON_TYPE_GENERAL,c.EDITOR_BUTTON_HELP)) {
              c.editorButtonMousedOver = tempBut; // point to button for help/title screen
              break;
            }
          }
        } else {
          toPlay(true);
        }
      }

      if(c.levelEditor == c.EDITOR_PLAY) { // for gameplay
        if(c.aliensToHeal == 0) {
          if(c.totalAliensToHeal > 0) {
            if(c.ALLOW_EDITOR || c.levNum >= c.levNames.length) {
              bitmapOverScreen(c.gameWinBMP);
              c.ingameText.text = c.TEXT_FinalScore+c.zeroPad(_p1.score,6);
            } else {
              c.levNum++;
              loadLevel();
            }
            return;
          }
        }
      }

      if(c.editButtonLockedIn && c.editorButtonMousedOver.matches(c.EDITOR_BUTTON_TYPE_GENERAL,c.EDITOR_BUTTON_HELP)) {
        bitmapOverScreen(c.gameHelpBMP);
        c.ingameText.text = c.TEXT_InitialCredits;
        return;
      }

      c.moveCamera(_p1);
      
      drawBackground();
      
      c.updateMousePos(mouseX,mouseY,width,height);
      
      if(c.levelEditor != c.EDITOR_PLAY) {
        if(c.gridSnap) {
          c.drawGrid(_RenderBMP);
        }
        
        if (c.levelEditor == c.EDITOR_LEVEL) {
          if(c.movingObj != null) { // sliding a StartObj?
            c.movingObj.pos.x = c.cmx;
            c.movingObj.pos.y = c.cmy;
          }
          
          if(c.movingObj) {
            c.ingameText.text = c.TEXT_ClickReleaseHint;
          } else if(c.editorButtonMousedOver && c.editButtonLockedIn) { 
            c.ingameText.text = c.TEXT_StampHint;
          } else if(c.mouseOnEdgeX != c.EDGE_NOT || c.mouseOnEdgeY != c.EDGE_NOT) {
            c.ingameText.text = c.TEXT_ResizeWorldHint;
          } else if(getTypeNearMouse(c.STARTCOORD_TYPE_LEVCHUNK) != null) {
            c.ingameText.text = c.TEXT_MirrorHint;
          } else if(getTypeNearMouse(c.STARTCOORD_TYPE_DECOR) != null) {
            c.ingameText.text = c.TEXT_MirrorDepthHint;
          } else if(getObjStartNearMouse() != null) {
            c.ingameText.text = c.TEXT_MoveDeleteHint;
          } else {
            c.ingameText.text = c.TEXT_EditorMessage;
          }

          if(c.mouseBusy() && c.mouseEdgeDrag == false) {
            // don't allow edge dragging by mouse if object is currently being stamped
            c.mouseOnEdgeX = c.mouseOnEdgeY = c.EDGE_NOT;
          } else if(c.mouseEdgeDrag == false) {
            c.detectMouseoverEdge();
          } else {
            c.draggingWorldEdge();
          }
        } else if (c.levelEditor == c.EDITOR_PIECE) {
          if(c.movingPiece != null) { // sliding a Piece Editor collision rectangle?
            c.movingPiece.slideTo(c.camera.x+c.mx-c.ax_pregrid, c.camera.y+c.my-c.ay_pregrid);
          }

          if(c.movingPiece || c.editorBox) {
            c.ingameText.text = c.TEXT_ClickReleaseHint;
          } else {
            c.ingameText.text = c.TEXT_PieceEditorInfo;
          }
        }
      }
      
      if(_p1.health <= 0 && c.levelEditor == c.EDITOR_PLAY) {
        _p1.resetScore();
        c.playSound(c.loseSND);
        readLevel(); // reset level, player died
        return;
      }
      
      drawLevel();
      
      drawDecorationsLayer_BG();
      
      _p1.input(_keyboardHold_Jump,_keyboardHold_L,_keyboardHold_R);

      if(_p1.doneJumping()) { // prevents bunny hopping from holding it
        _keyboardHold_Jump = false;
      }
      
      // for flying through walls in editor, using WASD as arrows
      if(c.levelEditor == c.EDITOR_LEVEL) {
        _p1.editorFloatInput(_keyboardHold_W,_keyboardHold_A,_keyboardHold_S,_keyboardHold_D);
      }
      
      _p1.move(_collQuad);
      
      // collision must be done before player draw; it affects poses
      if(c.levelEditor == c.EDITOR_PLAY) { // in play, we use an optimized set
        var overlapping:Array = _collQuad.uniqueCollOverlaps(_p1.collisionRect);
        for each(var chunk:LevChunk in overlapping) {
          LevChunk.collisionsOnly(_p1,chunk);
        }
      } else if(c.levelEditor == c.EDITOR_LEVEL) { // in editor, pick LevChunks from current obj data
        for each(obj in _objStart) {
          if(obj.type == c.STARTCOORD_TYPE_LEVCHUNK && obj != c.movingObj) {
            LevChunk.collisionsOnly(_p1,obj);
          }
        }
      }

      if(c.levelEditor != c.EDITOR_PIECE) {
        _p1.draw(_RenderBMP); // draw before level chunks, so player goes "behind" foreground rails etc.
      }
      
      if(c.levelEditor != c.EDITOR_PLAY) {
        if(c.levelEditor == c.EDITOR_LEVEL) {
          var mousedOver:ObjStart = getObjStartNearMouse();
          for each(var obj:ObjStart in _objStart) {
            if(obj.type != c.STARTCOORD_TYPE_DECOR) { // decor drawn elsewhere in FG/BG
              obj.draw(_RenderBMP,mousedOver);
            }
          }
        }
      } else { // not in level editor. Show real objects instead of start coords
        for each(var item:Item in _itemList) {
          item.moveAndDraw(_p1,_collQuad,_RenderBMP);
        }
        _itemList = _itemList.filter(removeAnyReadyForRemoval);
        
        for each(var enemy:Enemy in _enemyList) {
          enemy.moveAndDraw(_p1,_collQuad,_RenderBMP);
        }
        _enemyList = _enemyList.filter(removeAnyReadyForRemoval);

        c.pfx.moveAndDraw(_RenderBMP);
        
        var onScreen:Array = _collQuad.uniqueCollOverlaps(c.camera);
        for each(chunk in onScreen) {
          chunk.draw(_RenderBMP);
        }
      }

      drawDecorationsLayer_FG();
      
      if(c.levelEditor == c.EDITOR_LEVEL) {
        drawEdges(); // show edges so that they can be picked up and moved
        drawEdgeDragging(); // show resize bar if mouse is near world edge
      }
      
      if(c.editorBox != null) {
        if(c.levelEditor != c.EDITOR_PIECE) {
          c.editorBox = null;
        } else {
          c.enforceEditorBoxMinCollThickness();
          c.drawEditorBox(_RenderBMP);
        }
      }
      
      if(c.levelEditor == c.EDITOR_PLAY) { // for gameplay
        if(c.totalAliensToHeal == 0) {
          c.ingameText.text = c.TEXT_DesignErrorNeedPrangy+"\n"+c.TEXT_EditorKey;
        } else if(c.totalArmsForHealing < c.totalAliensToHeal) { 
          c.ingameText.text = c.TEXT_DesignErrorNeedPrangyArm+"\n"+c.TEXT_EditorKey;
        } else if(c.hasPlayerStart == false) {
          c.ingameText.text = c.TEXT_DesignErrorNeedPlayerStart+"\n"+c.TEXT_EditorKey;
        } else {
          if(c.ALLOW_EDITOR == false && _p1.score == 0) {
            c.ingameText.text = c.TEXT_InitialCredits + "\n" + c.TEXT_AudioKeys;
          } else {
            c.ingameText.text = (c.ALLOW_EDITOR ? (c.TEXT_EditorKey+"\n") : "")+
                                c.TEXT_AudioKeys+"\n"+
                                c.TEXT_Score + c.zeroPad(_p1.score,6)+"\n";
          }
        }

        drawHealthHUD();
        drawKeysHUD();
      } else { // for editor
        drawAndUpdateEditorHUD();
      }

      if(_levelNotFound) {
        c.ingameText.text = "Level data not found.";
      }
      if(c.debugText) { // allows c.debugText to be set from anywhere to expose values
        c.ingameText.text = c.debugText;
      }
    }
    
    public function clickRespond(event:MouseEvent): void
    {
      if(c.levelEditor == c.EDITOR_PLAY) { // not in editor mode?
        if(c.aliensToHeal == 0 && c.totalAliensToHeal > 0) { // on win screen
          if(c.ALLOW_EDITOR) {
            toEditor();
          } else {
            if(c.levNum >= c.levNames.length-1) {
              c.levNum=0;
              c.levelEditor = c.EDITOR_PLAY;
              loadLevel();
            } else  {
              toPlay(true);
            }
          }
        }
        return;
      }
      
      if(c.nearAnyEdges()) { // mouse near a border?
        c.mouseEdgeDrag = !c.mouseEdgeDrag; // (toggle) pick up and drag edges
        return;
      }
      
      if(c.levelEditor == c.EDITOR_LEVEL) {
        if(c.movingObj == null) { // mouse near an object?
          c.movingObj = getObjStartNearMouse(); // select it
          if(c.movingObj != null) {
            return;
          }
        } else {
          c.releaseMovingObj();
        }
        if(c.editorButtonMousedOver != null) {
          c.editorButtonMousedOver.handleClick(this);
          return;
        }
      } else if(c.levelEditor == c.EDITOR_PIECE) {
        if(c.editorButtonMousedOver != null) {
          c.editorButtonMousedOver.handleClick(this);
          return;
        }
        if(c.editorBox != null) {
          // collision part must stay within boundaries of this prefab's graphic
          c.editorBox.x += c.camera.x;
          c.editorBox.y += c.camera.y;
          var cutRect:Rectangle = trimPieceCollisionToBitmapBoundaries(c.editorBox);
          if(cutRect.width != 0 && cutRect.height != 0) {
            c.collisionRects.push(new Piece(cutRect.x,cutRect.y,cutRect.width,cutRect.height));
          }
          c.editorBox = null;
        } else if(c.movingPiece == null) {
          for each(var piece:Piece in c.collisionRects) {
            if(piece.contains(c.cmx_pregrid,c.cmy_pregrid)) {
              c.movingPiece = piece;
              c.ax = c.ax_pregrid = c.cmx - piece.x;
              c.ay = c.ay_pregrid = c.cmy - piece.y;
              break;
            }
          }
          if(c.movingPiece == null) {
            c.editorBox = new Rectangle(c.mx,c.my,0,0);
            c.ax = c.ax_pregrid = c.editorBox.x;
            c.ay = c.ay_pregrid = c.editorBox.y;
          }
        } else {
          // collision part must stay within boundaries of this prefab's graphic
          cutRect = trimPieceCollisionToBitmapBoundaries(c.movingPiece);
          if(cutRect.width != 0 && cutRect.height != 0) {
            c.movingPiece.x = cutRect.x;
            c.movingPiece.y = cutRect.y;
            c.movingPiece.width = cutRect.width;
            c.movingPiece.height = cutRect.height;
          } else { // delete the piece, it didn't fit within the bitmap's space
              c.collisionRects.splice(c.collisionRects.indexOf(c.movingPiece),1);
          }
        
          c.movingPiece = null;
        }
      }
    }
    
    ////// KEYBOARD INPUT FUNCTIONS //////

    public function keyRespond(event:KeyboardEvent): void
    {
      switch(event.keyCode) {
        // gameplay character control
        case KeyCode.K_LEFT:
          _keyboardHold_L = true;
          break;
        case KeyCode.K_UP:
        case KeyCode.K_SPACE:
          _keyboardHold_Jump = true;
          break;
        case KeyCode.K_RIGHT:
          _keyboardHold_R = true;
          break;

        // level editor
        case KeyCode.K_W:
          _keyboardHold_W = true;
          break;
        case KeyCode.K_A:
          _keyboardHold_A = true;
          break;
        case KeyCode.K_S:
          _keyboardHold_S = true;
          break;
        case KeyCode.K_D:
          _keyboardHold_D = true;
          break;
          
        case KeyCode.K_M:
          _musicPlaying = !_musicPlaying;
          if(_musicPlaying) {
            startMusic();
          } else {
            stopMusic();
          }
          break;
        case KeyCode.K_N:
          c.toggleSound();
          break;
        
        case KeyCode.K_DEL: // remove currently moved/selected block
        case KeyCode.K_DEL_MAC:
          if(c.levelEditor == c.EDITOR_PIECE) {
            if(c.movingPiece != null) {
              c.collisionRects.splice(c.collisionRects.indexOf(c.movingPiece),1);
              c.movingPiece = null;
            } else {
              for each(var piece:Piece in c.collisionRects) {
                if(piece.contains(c.cmx_pregrid,c.cmy_pregrid)) {
                  c.collisionRects.splice(c.collisionRects.indexOf(piece),1);
                  break;
                }
              }
            }
            deleteObjStartNearMouse();
          } else if(c.levelEditor == c.EDITOR_LEVEL) {
            deleteObjStartNearMouse();
          }
          break;
        case KeyCode.K_F:
          mirrorPrefabOrDecorNearMouse();
          break;
        case KeyCode.K_G:
          switchDecorDrawOrderNearMouse();
          break;
        case KeyCode.K_TAB: // toggle level editor
          if(c.levelEditor == c.EDITOR_LEVEL) {
            toPlay(false);
          } else if(c.levelEditor == c.EDITOR_PLAY && c.ALLOW_EDITOR) {
            toEditor(); // use straightforward unoptimized collision detection while in editor
            // acceptable since nothing else moves, helpful since brushes get new positions freq.
          }
          break;
        case KeyCode.K_ESC: // release editor step/stamping
          c.releaseEditorControls();
          break;
      }
    }

    // adding this new function to clear key states when released
    public function keyLetGo(event:KeyboardEvent): void
    {
      switch(event.keyCode) {
        case KeyCode.K_LEFT:
          _keyboardHold_L = false;
          break;
        case KeyCode.K_UP:
        case KeyCode.K_SPACE:
          _keyboardHold_Jump = false;
          break;
        case KeyCode.K_RIGHT:
          _keyboardHold_R = false;
          break;

        // level editor
        case KeyCode.K_W:
          _keyboardHold_W = false;
          break;
        case KeyCode.K_A:
          _keyboardHold_A = false;
          break;
        case KeyCode.K_S:
          _keyboardHold_S = false;
          break;
        case KeyCode.K_D:
          _keyboardHold_D = false;
          break;
      }
    }
    
    ////// SUPPORT FUNCTIONS //////
    
    private function startMusic(): void {
      _musicChannel = c.music.play(0,int.MAX_VALUE, new SoundTransform(0.35));
      _musicPlaying = true;
    }
    private function stopMusic(): void {
      _musicChannel.stop();
      _musicPlaying = false;
    }
    
    ////// FILE LOADING - LEVEL ///////

    public function loadLevel(): void {
      if(c.levNum >= c.levNames.length) {
        return;
      }
      _levelNotFound = false;
      _loadingLevel = true;
      _fileLoader = new URLLoader();
      _fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
      _fileLoader.addEventListener(Event.COMPLETE, importXML);
      _fileLoader.addEventListener(IOErrorEvent.IO_ERROR, levelLoadFailed);
      if(c.levNum == 0 || c.ALLOW_EDITOR) {
        _p1.resetScore();
      }
      _lastFilenameOpened = c.levNames[c.levNum]+".map";
      _fileLoader.load(new URLRequest(_lastFilenameOpened));
    }
    
    public function levelLoadFailed(event:IOErrorEvent): void {
      _levelNotFound = true;
      importXML(null); // press onward loading empty data, so that the game isn't frozen
    }
    
    public function importXML(e:Event): void {
      _fileLoader.removeEventListener( Event.COMPLETE, importXML );
      decompressData(e.target.data);
    }
    
    public function loadCustom(): void {
      _file.addEventListener( Event.SELECT, xmlFileSelect ) ;
      _file.browse();
    }
    
    private function xmlFileSelect( evt:Event ): void {
      _file.removeEventListener ( Event.SELECT, xmlFileSelect );
      _file.addEventListener( Event.COMPLETE, xmlDataLoaded );
      _file.load();
    }
    
    private function xmlDataLoaded( evt:Event ): void {
      _lastFilenameOpened = _file.name;
      _file.removeEventListener( Event.COMPLETE, xmlDataLoaded );
      decompressData(_file.data);
    }

    private function decompressData( data:* ): void {
      ByteArray(data).uncompress();
      c.levXML = new XML(data);
      readLevel();
    }

    public function readLevel(resetPlayer:Boolean = true): void {
      c.collisionRects = new Array(0);
      _objStart = new Array(0);
      _itemList = new Array(0);
      _enemyList = new Array(0);
      QuadTree.chunkList = new Array(0);
      QuadTree.decorListBG = new Array(0);
      QuadTree.decorListFG = new Array(0);
      
      c.pfx.clearAll();
      
      var xmlChildren:XMLList = c.levXML.children();
      
      c.themeNum = c.levXML.@artSet;
      
      c.levelLeft = c.levXML.@minX;
      c.levelTop = c.levXML.@minY;
      c.levelRight = c.levXML.@maxX;
      c.levelBottom = c.levXML.@maxY;
      c.enforceMinWorldSize();
      
      for each (var child:XML in xmlChildren) {
        if(child.name() == "objStart") {
          _objStart.push(new ObjStart(child.@x,child.@y,child.@type,child.@subType,child.@mirror == 1,child.@isBG == 1));
        }
      }
      
      c.hasPlayerStart = false; // assume false until it's found in the level's data
      
      for each(var obj:ObjStart in _objStart) { // fill in the in-game lists from ObjStart data
        switch(obj.type) {
          case c.STARTCOORD_TYPE_PLAYER:
            if(resetPlayer) {
              _p1.pos = obj.pos;
            }
            c.hasPlayerStart = true;
            break;
          case c.STARTCOORD_TYPE_ENEMY:
            _enemyList.push(new Enemy(obj.pos.x, obj.pos.y, obj.subType));
            break;
          case c.STARTCOORD_TYPE_ITEM:
            _itemList.push(new Item(obj.pos.x, obj.pos.y, obj.subType));
            break;
          case c.STARTCOORD_TYPE_LEVCHUNK:
            QuadTree.chunkList.push(new LevChunk(obj.pos.x, obj.pos.y, obj.subType, obj.mirror));
            break;
          case c.STARTCOORD_TYPE_DECOR:
            if(obj.isBG) {
              QuadTree.decorListBG.push(new Decor(obj.pos.x, obj.pos.y, obj.subType, obj.mirror));
            } else {
              QuadTree.decorListFG.push(new Decor(obj.pos.x, obj.pos.y, obj.subType, obj.mirror));
            }
            break;
        }
      }
      
      _p1.reset();
      _decorMode = false;
      c.aliensToHeal = (_itemList.filter(prangyList)).length;
      c.totalAliensToHeal = c.aliensToHeal;
      c.totalArmsForHealing = (_itemList.filter(armList)).length;
      loadAllCurrentThemeArt(); // begin loading graphic assets for this level's theme
      _loadingLevel = false; // mark that loading for the level has completed
      if(c.levelEditor == c.EDITOR_PIECE) {
        c.refreshEditingChunk();
      }
    }
    
    public function saveLevel(skipExport:Boolean = false): void {
      var ba:ByteArray = new ByteArray();
      
      c.levXML = <level/>;
      
      c.levXML.@artSet = c.themeNum;
      c.levXML.@minX = c.levelLeft;
      c.levXML.@minY = c.levelTop;
      c.levXML.@maxX = c.levelRight;
      c.levXML.@maxY = c.levelBottom;
      
      var pc:XML = new XML();
      
      for each(var obj:ObjStart in _objStart) {
        pc = <objStart/>;
        pc.@x = int(obj.pos.x);
        pc.@y = int(obj.pos.y);
        pc.@type = obj.type;
        pc.@subType = obj.subType;
        if(obj.type == c.STARTCOORD_TYPE_LEVCHUNK || obj.type == c.STARTCOORD_TYPE_DECOR) {
          pc.@mirror = (obj.mirror ? "1" : "0");
        }
        if(obj.type == c.STARTCOORD_TYPE_DECOR) {
          pc.@isBG = (obj.isBG ? "1" : "0");
        }
        c.levXML.appendChild(pc);
      }
      
      if(skipExport == false) {
        ba.writeUTFBytes(c.levXML);
        
        // XML has tons of redundancy, so it compresses nicely (down to ~1/8 the size, in this case)
        // Commenting out this next line exports human readable XML. Handy to debug changes.
        ba.compress();
        // if the corresponding uncompress is also commented (for levXML,not the same as chunkXML!)
        // the game will also be able to load the plaintext XML files.
        
        _file.save(ba,_lastFilenameOpened);
      }
    }
    
    ////// FILE LOADING - LEVEL PIECE COLLISION SPECIFICATIONS //////
    
    public function loadColl(): void {
      _loadingColl = true;
      _fileLoader = new URLLoader();
      _fileLoader.dataFormat = URLLoaderDataFormat.BINARY;
      _fileLoader.addEventListener(Event.COMPLETE, importColl);
      _fileLoader.load(new URLRequest("coll.dat"));
    }
    
    public function loadCustomColl(): void {
      _file.addEventListener( Event.SELECT, collFileSelect ) ;
      _file.browse();
    }
    
    private function collFileSelect( evt:Event ): void {
      _file.removeEventListener ( Event.SELECT, collFileSelect );
      _file.addEventListener( Event.COMPLETE, collDataLoaded );
      _file.load();
    }
    
    private function collDataLoaded( evt:Event ): void {
      _file.removeEventListener( Event.COMPLETE, collDataLoaded );
      decompressColl(_file.data);
    }
    
    public function importColl(e:Event): void {
      _fileLoader.removeEventListener( Event.COMPLETE, importColl );
      decompressColl(e.target.data);
    }
    
    private function decompressColl( data:* ): void {
      ByteArray(data).uncompress();
      c.chunkXML = new XML(data);
      readColl();
    }
    
    public function readColl(): void {
      var idxCounted:int = 0;
      c.collisionRects = new Array(0);

      var collChildren:XMLList = c.chunkXML.children();
      
      LevChunkPrefab.CollisionPrefab = new Array(0);
      
      for each (var child:XML in collChildren) {
        var tempList:Array = new Array(0);
        var chunkChildren:XMLList = child.children();
        for each (var grandchild:XML in chunkChildren) {
          tempList.push(new Piece(grandchild.@x,grandchild.@y,
                                  grandchild.@w,grandchild.@h));
        }
        LevChunkPrefab.CollisionPrefab.push(new LevChunkPrefab(tempList));
        idxCounted++;
      }
      
      // if more lev chunks have been declared, this will replicate the last one loaded until
      // all are accounted from in memory - prevents crashing, and enables saving the full set
      while(idxCounted<c.LEVCHUNK_TYPE_NUMTYPES) {
        LevChunkPrefab.CollisionPrefab.push(new LevChunkPrefab(tempList));
        idxCounted++;
      }

      loadLevel();
      _loadingColl = false;
    }
    
    public function saveCollChunks(skipExport:Boolean = false): void {
      var ba:ByteArray = new ByteArray();

      if(c.editingChunkType != -1) { // save currently edited type into memory
        LevChunkPrefab.CollisionPrefab[c.editingChunkType].replaceWithEditorSet();
      }
      
      c.chunkXML = <collChunks/>;
      
      var chunk:XML = new XML();
      var pc:XML = new XML();
      
      for(var i:int=0; i<LevChunkPrefab.CollisionPrefab.length; i++) {
        chunk = <c/>;
        for each(var piece:Piece in LevChunkPrefab.CollisionPrefab[i].pieceList) {
          pc = <p/>;
          pc.@x = int(piece.x);
          pc.@y = int(piece.y);
          pc.@w = int(piece.width);
          pc.@h = int(piece.height);
          chunk.appendChild(pc);
        }
        c.chunkXML.appendChild(chunk);
      }

      if(skipExport == false) {
        ba.writeUTFBytes(c.chunkXML);
        ba.compress();
        _file.save(ba,"coll.dat");
      }
    }
    
    ////// FILE LOADING - THEME ART AND REBUILD QUADTREES ///////
    
    public function loadAllCurrentThemeArt(): void {
      if(_lastThemeOpened != c.themeFolders[c.themeNum]) {
        _lastThemeOpened = c.themeFolders[c.themeNum];
        c.loadingImage = 0; // start at the top
        downloadImage(); // calls all images in order until each has been accounted for
      } else {
        c.loadingImage = -1;
        updateQuadTrees();
      }
    }
    
    private function downloadImage(): void {
      c.imageLoader = new Loader();
      c.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, doneLoad);
      c.themeArt[c.loadingImage] = null;
      c.imageLoader.load(new URLRequest("themeart/"+_lastThemeOpened+"/"+c.themeImageName[c.loadingImage]));
    }
    
    public function doneLoad(e:Event): void {
      _fileLoader.removeEventListener( Event.COMPLETE, doneLoad );
      c.themeArt[c.loadingImage] = new Bitmap(e.target.content.bitmapData);
      if(c.loadingImage < c.THEME_ART_NUM-1) { // more bitmaps to load?
        c.loadingImage++;
        downloadImage();
      } else {
        c.loadingImage = -1;
        updateQuadTrees();
      }
    }

    private function updateQuadTrees(): void {
      if(c.loadingImage != -1 || _loadingColl || _loadingLevel) {
        return; // insufficient data to update quad trees, return
      }
      
      // create QuadTrees only after images load - dimensions are needed for this
      if(c.levelEditor == c.EDITOR_PLAY) {
        if(_collQuad) {
          _collQuad.explicitNullChildren();
        }
        _collQuad = new QuadTree(c.levelLeft,c.levelTop,
                              c.levelRight,c.levelBottom, QuadTree.chunkList);

        if(_decorQuadBG) {
          _decorQuadBG.explicitNullChildren();
        }
        _decorQuadBG = new QuadTree(c.levelLeft,c.levelTop,
                                  c.levelRight,c.levelBottom, QuadTree.decorListBG);

        if(_decorQuadFG) {
          _decorQuadFG.explicitNullChildren();
        }
        _decorQuadFG = new QuadTree(c.levelLeft,c.levelTop,
                                  c.levelRight,c.levelBottom, QuadTree.decorListFG);
      }
    }
    
    /////// IN-GAME HUD ///////
    
    private function drawHealthHUD(): void { // water droplets for health, display in top right
      var HUDpt:Point = new Point();
      HUDpt.y = c.waterdropBMP.height/2+10;
      for(var i:int=0; i<_p1.health; i++) { // display health drops
        HUDpt.x = width-(c.waterdropBMP.width/2+10+i*c.waterdropBMP.width);
        c.centerBitmapOfPosOntoBuffer(c.waterdropBMP,HUDpt,_RenderBMP,true);
      }
    }
    
    private function drawKeysHUD(): void { // prangy arms show at top of screen, act as keys
      var HUDpt:Point = new Point();
      HUDpt.y = c.prangyArmBMP.height/2+10;
      for(var i:int=0; i<_p1.keys; i++) { // display prangy arms ("keys")
        HUDpt.x = (width-_p1.keys*c.prangyArmBMP.width)/2+
                  c.prangyArmBMP.width/2+i*c.prangyArmBMP.width;
        c.centerBitmapOfPosOntoBuffer(c.prangyArmBMP,HUDpt,_RenderBMP,true);
      }
    }
    
    private function drawAndUpdateEditorHUD(): void {
      if(c.editButtonLockedIn == false) {
        c.editorButtonMousedOver = null;
      }
      
      var HUDpt: Point = new Point(c.mx,c.my);

      if(c.editButtonLockedIn) { // draw piece currently being stamped
        c.centerBitmapOfPosOntoBuffer(c.bitmapForType(c.editorButtonMousedOver.category,c.editorButtonMousedOver.subType),HUDpt,_RenderBMP,true);
      }

      // is the mouse currently busy, and not because it's hovering over an unselected button?
      if(c.mouseBusy() && (c.editorButtonMousedOver == null || c.editButtonLockedIn)) {
        return; // then don't draw the buttons, it would get in the way of the current action
      }
      
      var tempBut:EditorButton;
      
      for each(tempBut in _editorBottomBut) {
        if(c.levelEditor == c.EDITOR_PIECE) {
          if(tempBut.subType == c.EDITOR_BUTTON_PLAY) {
            continue; // skip the play button when in the Piece Edit mode
          }
          if(tempBut.category != c.EDITOR_BUTTON_TYPE_GENERAL) {
            break; // hide character/item buttons from the editor in Piece Collision Edit mode
          }
        }
        tempBut.draw(_RenderBMP);
      }
      
      if(_decorMode) { // decorative level pieces
        for each(tempBut in _editorTopDecorBut) {
          tempBut.draw(_RenderBMP);
        }
      } else { // collidable level pieces
        for each(tempBut in _editorTopChunkBut) {
          if(c.levelEditor == c.EDITOR_LEVEL || // hide the decor toggle when in piece editor mode
                   tempBut.matches(c.EDITOR_BUTTON_TYPE_DECORTOGGLE,c.EDITOR_TOP_BUTTON_DECOR) == false) {
            tempBut.draw(_RenderBMP);
          }
        }
      }
    }
    
    /////// PREPARING EDITOR BUTTONS //////
    
    public function initEditorHUDButtons(): void {
      var idx:int = 0;
      var xpos:Number = c.ICON_MARGIN_FROM_EDGE+c.butbackBMP.width/2;
      var ypos:Number = c.GAME_HEIGHT-c.butbackBMP.height/2-c.ICON_MARGIN_FROM_EDGE;

      for(idx=0; idx<c.EDITOR_GENERAL_TYPES; idx++) {
        _editorBottomBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_GENERAL,idx));
        xpos += c.butbackBMP.width;
      }

      _editorBottomBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_PLAYERSTART,0));
      xpos += c.butbackBMP.width;

      for(idx=0; idx<c.ENEMY_TYPE_NUMTYPES; idx++) {
        _editorBottomBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_ENEMY,idx));
        xpos += c.butbackBMP.width;
      }

      for(idx=0; idx<c.ITEM_TYPE_NUMTYPES; idx++) {
        _editorBottomBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_ITEM,idx));
        xpos += c.butbackBMP.width;
      }

      xpos = c.GAME_WIDTH-c.ICON_MARGIN_FROM_EDGE+c.butbackBMP.width/2-
                c.butbackBMP.width*(c.LEVCHUNK_TYPE_NUMTYPES+c.EDITOR_TOP_BUTTON_TYPES);
      ypos = c.butbackBMP.height/2+c.ICON_MARGIN_FROM_EDGE;

      for(idx=0; idx<c.LEVCHUNK_TYPE_NUMTYPES; idx++) {
        _editorTopChunkBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_CHUNK,idx));
        xpos += c.butbackBMP.width;
      }
      
      for(idx=0; idx<c.EDITOR_DECORTOGGLE_NUMTYPES; idx++) {
        _editorTopChunkBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_DECORTOGGLE,idx));
        xpos += c.butbackBMP.width;
      }

      xpos = c.GAME_WIDTH-c.ICON_MARGIN_FROM_EDGE+c.butbackBMP.width/2-
                c.butbackBMP.width*(c.DECOR_TYPE_NUMTYPES+1);

      for(idx=0; idx<c.DECOR_TYPE_NUMTYPES; idx++) {
        _editorTopDecorBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_DECOR,idx));
        xpos += c.butbackBMP.width;
      }

      _editorTopDecorBut.push(new EditorButton(xpos,ypos,c.EDITOR_BUTTON_TYPE_DECORTOGGLE,c.EDITOR_TOP_BUTTON_DECOR));
    }
    
    /////// BACKGROUND, EDGE, AND FOREGROUND RENDERING //////
    
    public function drawBackground(): void {
      if(c.levelEditor == c.EDITOR_PIECE) {
        // background
        c.drawRect.x=0;
        c.drawRect.y=0;
        c.drawRect.width=width;
        c.drawRect.height=height;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, c.PIECE_EDITOR_BACKGROUND_COLOR);
        _RenderBMP.unlock();
        
        var useBMP:Bitmap = c.bitmapForType(c.STARTCOORD_TYPE_LEVCHUNK,c.editingChunkType);
        
        // bitmap dimensions (area where collision data can be added)
        c.drawRect.x=-c.camera.x-useBMP.width/2+1;
        c.drawRect.y=-c.camera.y-useBMP.height/2+1;
        c.drawRect.width=useBMP.width-2;
        c.drawRect.height=useBMP.height-2;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, c.PIECE_EDITOR_AREA_COLOR);
        _RenderBMP.unlock();

        // the bitmap for this decoration
        c.centerBitmapOfPosOntoBuffer(useBMP,new Point(0,0),_RenderBMP);
      } else {
        c.centerBitmapOfPosOntoBuffer(c.themeArt[c.THEME_ART_BG],new Point(width/2-1,height/2-2),_RenderBMP,true);
      }
    }
    
    // expects c.drawRect.x and c.drawRect.width to already be set
    public function drawWorldTopAndBottomEdges(): void {
      if(c.camera.y < c.levelTop) { // top side of world on screen
        c.drawRect.y=0;
        c.drawRect.height=c.BORDER_THICKNESS;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
        _RenderBMP.unlock();
        
      } else if(c.camera.y+_RenderBMPMem.height > c.levelBottom) { // bottom side of world on screen
        c.drawRect.y = c.levelBottom-c.camera.y-2;
        c.drawRect.height=c.BORDER_THICKNESS;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
        _RenderBMP.unlock();        
      }
    }
    
    public function drawEdges(): void {
      c.drawRect.x=c.levelLeft-c.camera.x;
      c.drawRect.y=c.levelTop-c.camera.y;
      c.drawRect.width=c.BORDER_THICKNESS;
      c.drawRect.height=c.levelBottom-c.levelTop;
      _RenderBMP.lock();
      _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
      _RenderBMP.unlock();
      
      c.drawRect.width=c.levelRight-c.levelLeft;
      c.drawRect.height=c.BORDER_THICKNESS;
      _RenderBMP.lock();
      _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
      _RenderBMP.unlock();

      c.drawRect.x=c.levelRight-c.camera.x;
      c.drawRect.y=c.levelTop-c.camera.y;
      c.drawRect.width=c.BORDER_THICKNESS;
      c.drawRect.height=c.levelBottom-c.levelTop;
      _RenderBMP.lock();
      _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
      _RenderBMP.unlock();
      
      c.drawRect.x=c.levelLeft-c.camera.x;
      c.drawRect.y=c.levelBottom-c.camera.y;
      c.drawRect.width=c.levelRight-c.levelLeft;
      c.drawRect.height=c.BORDER_THICKNESS;
      _RenderBMP.lock();
      _RenderBMP.fillRect( c.drawRect, c.BORDER_COLOR);
      _RenderBMP.unlock();

      return;
    }
    
    public function drawEdgeDragging(): void {
      if(c.mouseOnEdgeX != c.EDGE_NOT) {
        c.drawRect.x=c.mx_pregrid-20;
        c.drawRect.y=c.my_pregrid-5;
        c.drawRect.width=40;
        c.drawRect.height=10;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, (c.mouseEdgeDrag ? 0xff9900 : 0x0099ff));
        _RenderBMP.unlock();
      }
      if(c.mouseOnEdgeY != c.EDGE_NOT) {
        c.drawRect.x=c.mx_pregrid-5;
        c.drawRect.y=c.my_pregrid-20;
        c.drawRect.width=10;
        c.drawRect.height=40;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, (c.mouseEdgeDrag ? 0xff9900 : 0x0099ff));
        _RenderBMP.unlock();
      }
    }
    
    public function drawDecorationsLayer_BG(): void {
      if(c.levelEditor == c.EDITOR_PLAY) {
        var drawDecor:Array = _decorQuadBG.uniqueCollOverlaps(c.camera);
        for each(var decorPiece:Decor in drawDecor) {
          decorPiece.draw(_RenderBMP);
        }
      } else if(c.levelEditor == c.EDITOR_LEVEL) {
        var BGList:Array = _objStart.filter(DecorObjStart_BG_Only);
        var mousedOver:ObjStart = getObjStartNearMouse();
        for each(var decorObj:ObjStart in BGList) {
          decorObj.draw(_RenderBMP,mousedOver);
        }
      }
    }
    
    public function drawDecorationsLayer_FG(): void {
      if(c.levelEditor == c.EDITOR_PLAY) {
        var drawDecor:Array = _decorQuadFG.uniqueCollOverlaps(c.camera);
        for each(var decorPiece:Decor in drawDecor) {
          decorPiece.draw(_RenderBMP);
        }
      } else if(c.levelEditor == c.EDITOR_LEVEL) {
        var FGList:Array = _objStart.filter(DecorObjStart_FG_Only);
        var mousedOver:ObjStart = getObjStartNearMouse();
        for each(var decorObj:ObjStart in FGList) {
          decorObj.draw(_RenderBMP,mousedOver);
        }
      }
    }
    
    /////// LEVEL DRAW //////
    
    public function drawLevel(): void {
      var matrix:Matrix = new Matrix(); 
      matrix.translate(-c.camera.x,-c.camera.y);
      
      _RenderBMP.lock();      
      if(c.levelEditor == c.EDITOR_PIECE) {
        for each(var piece:Piece in c.collisionRects) {
          piece.draw(_RenderBMP);
        }
      }
      _RenderBMP.unlock();
    }
    
    /////// FULL SCREEN IMAGE/MENU DRAW //////

    // clear the screen except for a bitmap (generally a full screen image)
    private function bitmapOverScreen(usingBitmap:Bitmap): void {
        // fill it corner to corner with white
        c.drawRect.x = 0;
        c.drawRect.y = 0;
        c.drawRect.width = _RenderBMPMem.width;
        c.drawRect.height = _RenderBMPMem.height;
        _RenderBMP.lock();
        _RenderBMP.fillRect( c.drawRect, 0xffffffff );
        _RenderBMP.unlock();

        // clear the text buffer
        c.ingameText.text = "";
        
        var BMPpt:Point = new Point(width/2-1,height/2-1); // center of screen
        // place the image in the center of the screen
        c.centerBitmapOfPosOntoBuffer(usingBitmap,BMPpt,_RenderBMP,true);
    }
    
    /////// SWITCH BETWEEN GAME/EDITOR //////
    
    public function toPlay(resetPlayer:Boolean): void {
      c.levelEditor = c.EDITOR_PLAY;
      c.releaseEditorControls();
      saveLevel(true); // don't export to file, just update XML
      readLevel(resetPlayer);
    }
    
    private function toEditor(): void {
      c.levelEditor = c.EDITOR_LEVEL;
      c.releaseEditorControls();
      if(_collQuad) {
        _collQuad.explicitNullChildren();
        _collQuad = null;
      }
    }
    
    /////// PIECE EDITOR //////

    public function flipDecorMode(): void {
      _decorMode = !_decorMode;
    }
    
    private function trimPieceCollisionToBitmapBoundaries(fromThis:Rectangle): Rectangle {
      var cutRect:Rectangle = new Rectangle(fromThis.x,fromThis.y,
                                            fromThis.width,fromThis.height);
      var myBMP:Bitmap = c.bitmapForType(c.STARTCOORD_TYPE_LEVCHUNK,c.editingChunkType);
      var bmpRect:Rectangle = new Rectangle(-myBMP.width/2,-myBMP.height/2,myBMP.width,myBMP.height);
      return cutRect.intersection(bmpRect);
    }
    
    ///// ARRAY FILTERS //////

    private function removeAnyReadyForRemoval(element:*, index:int, arr:Array): Boolean {
      return (element.readyToBeRemoved == false);
    }
    private function prangyList(element:*, index:int, arr:Array): Boolean {
      return (element.subType == c.ITEM_TYPE_PRANGY);
    }
    private function armList(element:*, index:int, arr:Array): Boolean {
      return (element.subType == c.ITEM_TYPE_ARM);
    }
    
    private function DecorObjStart_BG_Only(element:*, index:int, arr:Array): Boolean {
      return (element.type == c.STARTCOORD_TYPE_DECOR && element.isBG);
    }
    private function DecorObjStart_FG_Only(element:*, index:int, arr:Array): Boolean {
      return (element.type == c.STARTCOORD_TYPE_DECOR && element.isBG == false);
    }
    
    // used to remove all player starts before adding a new one, ensuring only 1 player start
    public function removePlayerStart(element:*, index:int, arr:Array): Boolean {
      return element.type != c.STARTCOORD_TYPE_PLAYER;
    }

    /////// MOUSE/EDITOR INPUT HELPERS ///////
    
    private function getObjStartNearMouse(): ObjStart {
      var nearestObj:ObjStart = null;
      var nearestObjFromMouse:Number = Number.MAX_VALUE;

      var foundDecor:ObjStart = null;
      var nearestDecorFromMouse:Number = Number.MAX_VALUE;
      
      if(c.mouseBusy() || c.mouseOnEdgeX != c.EDGE_NOT || c.mouseOnEdgeY != c.EDGE_NOT) {
        return null;
      }
      
      for each(var obj:ObjStart in _objStart) {
        if(obj.nearMouse(true)) {
          if(obj.type == c.STARTCOORD_TYPE_DECOR) { // huge and least specific. lower priority
            if(obj.distFromMouse() < nearestDecorFromMouse) {
              foundDecor = obj;
              nearestDecorFromMouse = obj.distFromMouse();
            }
          } else {
            if(obj.distFromMouse() < nearestObjFromMouse) {
              nearestObj = obj;
              nearestObjFromMouse = obj.distFromMouse();
            }
          }
        }
      }
      if(nearestObj == null) {
        return foundDecor; // only return decor if smaller object didn't come back from search
      } else {
        return nearestObj;
      }
    }
    
    private function getTypeNearMouse(ofType:int): ObjStart {
      if(c.mouseBusy()) {
        return null;
      }
    
      var obj:ObjStart = getObjStartNearMouse();
      if(obj != null && obj.type == ofType) {
        return obj;
      }
      return null;
    }

    private function mirrorPrefabOrDecorNearMouse(): void {
      var obj:ObjStart = getTypeNearMouse(c.STARTCOORD_TYPE_LEVCHUNK);
      if(obj != null) {
        obj.mirror = !(obj.mirror);
      } else {
        obj = getTypeNearMouse(c.STARTCOORD_TYPE_DECOR);
        if(obj != null) {
          obj.mirror = !(obj.mirror);
        }
      }
    }

    private function switchDecorDrawOrderNearMouse(): void {
      var obj:ObjStart = getTypeNearMouse(c.STARTCOORD_TYPE_DECOR);
      if(obj != null) {
        obj.isBG = !(obj.isBG);
      }
    }
    
    public function deleteObjStartNearMouse(): void {
      var obj:ObjStart = getObjStartNearMouse();
      if(obj != null) {
        _objStart.splice(_objStart.indexOf(obj),1);
      }
    }
    
    // used by EditorButtons to stamp a current object into the world, or lock in a functionality
    public function stampOrActivate(category:int,subType:int): void {
      if(c.editButtonLockedIn) {
        if(category != c.STARTCOORD_TYPE_DECOR) {
          deleteObjStartNearMouse(); // if placing a gameplay (non-decor) piece, clear room first
        }
        if(category == c.STARTCOORD_TYPE_PLAYER) { // only 1 player start in the world...
          _objStart = _objStart.filter(removePlayerStart); // so remove any other one(s)
        }

        _objStart.push(new ObjStart(c.cmx,c.cmy,category,subType));
      } else {
        c.editButtonLockedIn = true;
      }
    }

  }
}
