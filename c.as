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

// "c", the file/class name, stands for two things: Constant and Common
// Any constant, global function, or structure which needs to be reached from all over the
// program is declared static within this class. This includes image and sound file embeds.
package {
  import flash.display.Bitmap;
  import flash.display.BitmapData;
  import flash.display.Sprite;
  import flash.display.Loader;
  import flash.geom.Matrix;
  import flash.geom.ColorTransform;
  import flash.geom.Point;
  import flash.geom.Rectangle;
  import flash.media.Sound;
  import flash.text.TextField;

  public class c { // constants and common
    // defined here for (a) access everywhere and (b) use in defining other constants
    public static const GAME_WIDTH:int = 650;
    public static const GAME_HEIGHT:int = 450;
    
    public static const ALLOW_EDITOR:Boolean = true; // set false when your custom game is finished
    public static const START_IN_EDITOR:Boolean = (true && ALLOW_EDITOR);
    
    // automatic level loading only functions when ALLOW_EDITOR is set to false
    public static var levNum:int = 0; // which level is currently active (0 means 1st level)
    // changing the levNames list determines which levels are loaded, in which order,
    // if ALLOW_EDITOR==false. The ".map" extension will automatically be appended.
    public static const levNames:Array = new Array("lev1","lev2","lev3");

    // this assigns the following themeart subdirectories to 
    // each folder should contain identical file names, for all per-theme art
    public static const themeFolders:Array = new Array("snowy","woods","dungeon");
    public static var themeNum:int = 0; // which graphic set to use. See themeFolders above

    public static const THEME_ART_BG:int = 0;
    public static const THEME_ART_PIECE_2x2:int = 1;
    public static const THEME_ART_PIECE_2x4:int = 2;
    public static const THEME_ART_PIECE_4x1:int = 3;
    public static const THEME_ART_PIECE_4x2:int = 4;
    public static const THEME_ART_PIECE_8_1_STAIRS:int = 5;
    public static const THEME_ART_PIECE_LEDGE:int = 6;
    public static const THEME_ART_PIECE_LUMPY:int = 7;
    public static const THEME_ART_PIECE_POLE:int = 8;
    public static const THEME_ART_DECOR_BUSH:int = 9;
    public static const THEME_ART_DECOR_CLOUD:int = 10;
    public static const THEME_ART_DECOR_TREE:int = 11;
    public static const THEME_ART_DECOR_VINES:int = 12;
    public static const THEME_ART_DECOR_BIG_TILE:int = 13;
    public static const THEME_ART_NUM:int = 14;
    // themeImageName[] must be listed in the same order as the enumerations above
    public static var themeImageName:Array = new
              Array("bg.jpg",
                    "pieces/2x2_crate.png",
                    "pieces/2x4_pillar.png",
                    "pieces/4x1_platform.png",
                    "pieces/4x2_ramp.png",
                    "pieces/8_1x1_stairs.png",
                    "pieces/lip_ledge.png",
                    "pieces/small_lumpyland.png",
                    "pieces/thin_pole.png",
                    "decorations/decor_ground_wide.png",
                    "decorations/decor_floating_med.png",
                    "decorations/decor_ground_tall_narrow.png",
                    "decorations/decor_wall_tall.png",
                    "decorations/decor_big_tiling.png"
                    );

    // gameplay constants
    public static const GRAV:Number = 0.8;
    public static const CAMERA_CHASE_POWER:Number = 0.35; // small values make camera floaty

    public static const PLAYER_JUMP_FORCE:Number = 9.4;
    public static const PLAYER_JUMP_HOLD:int = 8; // how many frames jump button can be held for boost
    public static const PLAYER_RUN_ACCEL:Number = 1.5;
    public static const PLAYER_RUN_MAX:Number = 6.0;
    public static const PLAYER_RUN_DECAY:Number = 0.73;
    public static const PLAYER_LATERAL_AIRSPEED_DECAY:Number = 0.93;
    public static const PLAYER_BUMP_THROW_FORCE:Number = 10.0;
    public static const PLAYER_BUMP_THROW_LATERAL_MIN:Number = 5.0;
    public static const PLAYER_MAX_HEALTH:int = 8;
    public static const PLAYER_RECOVER_TIME:int = 27;
    public static const PLAYER_WALKS_OFF_EDGE_CAN_STILL_JUMP_CYCLES:int = 6;
    public static const PLAYER_GROUND_HUG_FORCE:Number = 6.0;
    
    public static const PLAYER_WIDTH:Number = 40;
    public static const PLAYER_HEIGHT:Number = 75;

    public static const ENEMY_JUMP_FORCE:Number = PLAYER_JUMP_FORCE;
    
    public static const MAX_FALL_SPEED:Number = PLAYER_HEIGHT/4;
    public static const LATERAL_BOUNCE:Number = 0.25;

    // quad tree
    public static const QUADTREE_MAX_ELEMENTS:int = 4;
    public static const QUADTREE_MIN_WIDTH:int = 30;
    // the limits above prevent it from recursing indefinitely when many layers overlap
    // or appear in a tiny space together.

    // animation
    public static const ANIM_FRAME_HOLD:Number = 3;
    public static const PLAYER_FRAME_COUNT:Number = 4;
    public static const PLAYER_ANIM_VERT_THRESHOLD:Number = 5.2;
    public static const PLAYER_ANIM_STANDING_THRESHOLD:Number = 1.2;

    // particle effects
    public static var pfx:ParticleSet;
    public static const MAX_PARTICLES:int = 150;
    
    // global variables, commonly shared/re-used structures
    public static var camera:Rectangle = new Rectangle();
    public static var offsetMatrix:Matrix = new Matrix();
    public static var drawRect:Rectangle = new Rectangle();

    // Levels are saved and loaded as compressed XML
    public static var levXML:XML = new XML();
    // Collision data for level/world pieces is also saved and loaded as compressed XML
    public static var chunkXML:XML = new XML();
    
    // these next few variables check a level in the editor for completedness
    public static var hasPlayerStart:Boolean;
    public static var totalArmsForHealing:int;
    public static var totalAliensToHeal:int;
    public static var aliensToHeal:int; // this is also used in play, to measure progress
    
    // left/top/right/bottom works better than a Rect here
    // so that we can change each more easily in the editor
    // without adjusting the coordinates of other things.
    public static var levelLeft:Number;
    public static var levelTop:Number;
    public static var levelRight:Number;
    public static var levelBottom:Number;
    
    // visual style
    public static const PIECE_COLOR:uint = 0xff0000;
    public static const PIECE_COLOR_MOUSEOVER:uint = 0x00ff00;
    public static const PIECE_COLOR_SELECTED:uint = 0x00ffff;
    public static const PIECE_EDITOR_BACKGROUND_COLOR:uint = 0xbbbbbb;
    public static const PIECE_EDITOR_AREA_COLOR:uint = 0xeeeeee;
    public static const BORDER_COLOR:uint = 0xff0000;
    public static const BORDER_THICKNESS:int = 4;
    public static const GRID_COLOR:uint = 0xcccccc;
    public static const ICON_MARGIN_FROM_EDGE:int = 5;
    
    public static var ingameText:TextField = new TextField();
    public static var debugText:String = null; // if filled, forced to appear as ingameText
    
    // text strings
    public static const TEXT_EditorMessage:String = "Arrow keys to move, WASD to fly, mouse to edit\nPress TAB to play from current position\nPress M to switch music on/off";
    public static const TEXT_AudioKeys:String = "M: Music / N: Sound";
    public static const TEXT_EditorKey:String = "Press TAB for Editor";
    public static const TEXT_StampHint:String = ">> Press ESCAPE to stop stamping <<";
    public static const TEXT_ClickReleaseHint:String = "Click to put down selection";
    public static const TEXT_ResizeWorldHint:String = "Click to move world edge";
    public static const TEXT_MoveDeleteHint:String = "Click on to move\nPress Delete to remove";
    public static const TEXT_MirrorHint:String = "Press F to flip\n"+TEXT_MoveDeleteHint;
    public static const TEXT_MirrorDepthHint:String = TEXT_MirrorHint+"\nPress G to toggle FG/BG layer";
    public static const TEXT_PieceEditorInfo:String = "Save/Load on this screen for new coll.dat\nCollision data is NOT part of map data\nAll art themes share collision data\nDelete key removes highlighted\nClick on any shape to move\nClick empty space to create new part";
    public static const TEXT_InitialCredits:String = "Game Engine by z2ck100 | Music by BPOD freemusicarchive.org/music/BOPD/"; //main credits --64325234562963445328756932489562957893452934563248568347523675834652363875236578324658753246534987563244579656547562784684395678w3456278782352346975263475632478652837465832652345723485623854698572345632478568234593
    public static const TEXT_Score:String = "Score: ";
    public static const TEXT_FinalScore:String = "End Score: ";
    public static const TEXT_DesignErrorNeedPrangy:String = "LEVEL DESIGN ERROR: Add at least 1 Prangy and 1 Prangy Arm for level to be winnable!";
    public static const TEXT_DesignErrorNeedPrangyArm:String = "LEVEL DESIGN ERROR: Add at least 1 Prangy Arm per Prangy for level to be winnable!";
    public static const TEXT_DesignErrorNeedPlayerStart:String = "LEVEL DESIGN ERROR: The level needs a Player Start position.";

    // editor modes (EDITOR_PLAY means gameplay - i.e. testing, not in editor)
    public static var levelEditor:int;
    public static const EDITOR_PLAY:int = 0;
    public static const EDITOR_LEVEL:int = 1;
    public static const EDITOR_PIECE:int = 2;

    // objects temporarily held by or being drawn by the mouse tool in the editor
    public static var editorBox:Rectangle = null;
    public static var movingPiece:Piece = null;
    public static var movingObj:ObjStart = null;
    public static var editingChunkType:int = -1;
    public static var collisionRects:Array = null; // used for Prefab brushwork
    
    // development mouse coordinate storage
    public static var editorButtonMousedOver:EditorButton = null;
    public static var mx:int = 0, my:int = 0; // mouse x/y position (screen space)
    public static var mx_pregrid:int = 0, my_pregrid:int = 0; // before grid snap
    public static var cmx:int = 0, cmy:int = 0; // mouse+camera x/y (world space)
    public static var cmx_pregrid:int = 0, cmy_pregrid:int = 0; // mouse+camera x/y without snap    
    public static var ax:int = 0, ay:int = 0; // anchor x/y, keeps clicked relative position
    public static var ax_pregrid:int = 0, ay_pregrid:int = 0; // keep anchor on grid
    
    // Hack note: The way that editor buttons are hooked up is a terrible mess. Edit with care.
    public static const NO_EDITOR_BUTTON_HIGHLIGHTED:int = -1;
    public static const EDITOR_BUTTON_NEW:int = 0;
    public static const EDITOR_BUTTON_LOAD:int = 1;
    public static const EDITOR_BUTTON_PLAY:int = 2;
    public static const EDITOR_BUTTON_SAVE:int = 3;
    public static const EDITOR_BUTTON_HELP:int = 4;
    public static const EDITOR_BUTTON_GRID:int = 5;
    public static const EDITOR_GENERAL_TYPES:int = 6;

    public static const EDITOR_BUTTON_START:int = 0;
    
    public static const EDITOR_TOP_BUTTON_DECOR:int = 0;
    public static const EDITOR_TOP_BUTTON_SET:int = 1;
    public static const EDITOR_TOP_BUTTON_EDIT:int = 2;
    public static const EDITOR_TOP_BUTTON_TYPES:int = 3;

    public static const EDITOR_DECORTOGGLE_DECOR:int = 0;
    public static const EDITOR_DECORTOGGLE_SET:int = 1;
    public static const EDITOR_DECORTOGGLE_EDIT:int = 2;
    public static const EDITOR_DECORTOGGLE_NUMTYPES:int = 3;

    public static const EDITOR_DECOR_BUTTONS:int = DECOR_TYPE_NUMTYPES+1; // +1 for button to exit out of decor mode
    
    // note: - borrowing the matching STARTCOORD category indexes, to avoid conversions
    public static const EDITOR_BUTTON_TYPE_PLAYERSTART:int = STARTCOORD_TYPE_PLAYER;
    public static const EDITOR_BUTTON_TYPE_ENEMY:int = STARTCOORD_TYPE_ENEMY;
    public static const EDITOR_BUTTON_TYPE_ITEM:int = STARTCOORD_TYPE_ITEM;
    public static const EDITOR_BUTTON_TYPE_CHUNK:int = STARTCOORD_TYPE_LEVCHUNK;
    public static const EDITOR_BUTTON_TYPE_DECOR:int = STARTCOORD_TYPE_DECOR;
    public static const EDITOR_BUTTON_TYPE_GENERAL:int = 5;
    public static const EDITOR_BUTTON_TYPE_DECORTOGGLE:int = 6;
    
    public static var editButtonLockedIn:Boolean = false;
    public static var editButtonLockedCat:int = -1;
    public static var editButtonLockedType:int = -1;

    // ObjStart types
    public static const STARTCOORD_TYPE_PLAYER:int = 0;
    public static const STARTCOORD_TYPE_ENEMY:int = 1;
    public static const STARTCOORD_TYPE_ITEM:int = 2;
    public static const STARTCOORD_TYPE_LEVCHUNK:int = 3;
    public static const STARTCOORD_TYPE_DECOR:int = 4;
    
    // editor grid
    public static var gridSnap:Boolean = true;
    public static const WALL_TOO_SMALL:int = 8; // collision pieces won't get smaller
    public static const GRID_SPACING:int = WALL_TOO_SMALL*2;
    public static const GRID_VIS_SPACING:int = GRID_SPACING*2;
    // make the world at least as big as the screen, and also fit to the grid
    // unlike most of this file, these are private; they're only needed by functions within c.as
    private static const MIN_WORLD_VISGRID_UNITS_WIDTH:int = (1+GAME_WIDTH/GRID_VIS_SPACING);
    private static const MIN_WORLD_VISGRID_UNITS_HEIGHT:int = (1+GAME_HEIGHT/GRID_VIS_SPACING);
    private static const MIN_WORLD_WIDTH:int = MIN_WORLD_VISGRID_UNITS_WIDTH*GRID_VIS_SPACING;
    private static const MIN_WORLD_HEIGHT:int = MIN_WORLD_VISGRID_UNITS_HEIGHT*GRID_VIS_SPACING;

    // enemy types
    public static const ENEMY_TYPE_MINE:int = 0;
    public static const ENEMY_TYPE_BAT:int = 1;
    public static const ENEMY_TYPE_DRAGON:int = 2;
    public static const ENEMY_TYPE_ICE:int = 3;
    public static const ENEMY_TYPE_RAM:int = 4;
    public static const ENEMY_TYPE_SEAHORSE:int = 5;
    public static const ENEMY_TYPE_SNAKE:int = 6;
    public static const ENEMY_TYPE_SKULL:int = 7;
    public static const ENEMY_TYPE_SPRING:int = 8;
    public static const ENEMY_TYPE_WATER:int = 9;
    public static const ENEMY_TYPE_NUMTYPES:int = 10;
    
    // enemy tuning variables
    public static const ENEMY_SPEED_MINE:Number = 3.8;
    public static const ENEMY_SPEED_BAT_X:Number = 5.0;
    public static const ENEMY_SPEED_BAT_DIVE:Number = 18.0;
    public static const ENEMY_SPEED_BAT_DIVE_RAND_EXTRA:Number = 8.0;
    public static const ENEMY_SPEED_DRAGON:Number = 3.0;
    public static const ENEMY_SPEED_ICE:Number = 4.0;
    public static const ENEMY_SPEED_RAM:Number = 3.5;
    public static const ENEMY_SPEED_SEAHORSE:Number = 7.0;
    public static const ENEMY_SPEED_SNAKE:Number = 6.0;
    public static const ENEMY_SPEED_SKULL:Number = 0.5;
    public static const ENEMY_SPEED_SPRING_X:Number = 6.0;
    public static const ENEMY_SPEED_SPRING_JUMP:Number = 13.0;
    public static const ENEMY_SPEED_SPRING_JUMP_RAND_EXTRA:Number = 6.0;
    public static const ENEMY_SPEED_WATER:Number = 17.0;
    
    // enemy awareness ranges
    public static const ENEMY_ENGAGEMENT_RANGE_ICE_X:Number = 80.0;
    public static const ENEMY_ENGAGEMENT_RANGE_ICE_Y:Number = 200.0;
    public static const ENEMY_ENGAGEMENT_RANGE_MINE:Number = 150.0;
    
    // how long certain enemies hold a state before jumping/flying/moving/et
    public static const ENEMY_STATE_TIME_MIN_BAT:int = 40;
    public static const ENEMY_STATE_TIME_RAND_BAT:int = 70;
    public static const ENEMY_STATE_TIME_MIN_SEAHORSE:int = 20;
    public static const ENEMY_STATE_TIME_RAND_SEAHORSE:int = 30;
    public static const ENEMY_STATE_TIME_MIN_SNAKE:int = 100;
    public static const ENEMY_STATE_TIME_RAND_SNAKE:int = 60;
    public static const ENEMY_STATE_TIME_MIN_SPRING:int = 30;
    public static const ENEMY_STATE_TIME_RAND_SPRING:int = 20;
    
    // used to keep track of what an enemy is doing. Meaning varies by enemy.
    public static const ENEMY_STATE_SURFACE:int = 0;
    public static const ENEMY_STATE_FLYING:int = 1;

    // different types of items.
    public static const ITEM_TYPE_DROP:int = 0; // health and points
    public static const ITEM_TYPE_ARM:int = 1; // these work as keys. bring to:
    public static const ITEM_TYPE_PRANGY:int = 2; // these guys need arms.
    public static const ITEM_TYPE_NUMTYPES:int = 3;

    // different types of level chunks
    public static const LEVCHUNK_TYPE_2x2_CRATE:int = 0;
    public static const LEVCHUNK_TYPE_2x4_PILLAR:int = 1;
    public static const LEVCHUNK_TYPE_4x1_PLATFORM:int = 2;
    public static const LEVCHUNK_TYPE_4x2_RAMP:int = 3;
    public static const LEVCHUNK_TYPE_8_1_STAIRS:int = 4;
    public static const LEVCHUNK_TYPE_LIP_LEDGE:int = 5;
    public static const LEVCHUNK_TYPE_SMALL_LUMPYLAND:int = 6;
    public static const LEVCHUNK_TYPE_THIN_POLE:int = 7;
    public static const LEVCHUNK_TYPE_NUMTYPES:int = 8;
    
    // different types of non-collision level decorations
    public static const DECOR_TYPE_GROUND_WIDE:int = 0;
    public static const DECOR_TYPE_FLOATING_MED:int = 1;
    public static const DECOR_TYPE_GROUND_TALL:int = 2;
    public static const DECOR_TYPE_WALL_TALL:int = 3;
    public static const DECOR_TYPE_BIG_TILE:int = 4;
    public static const DECOR_TYPE_NUMTYPES:int = 5;

    // particle effects types
    public static const PFX_TYPE_BIGFIRE:int = 0;
    public static const PFX_TYPE_TINYFIRE:int = 1;
    public static const PFX_TYPE_PRANGY_ARMOR:int = 2;
    public static const PFX_TYPE_PRANGY_SHIRT:int = 3;
    public static const PFX_TYPE_PRANGY_SKIN:int = 4;
    public static const PFX_TYPE_SMOKE:int = 5;
    public static const PFX_TYPE_SPARK:int = 6;

    // edge dragging in the editor to change the world size
    public static const EDGE_MIN:int = -1;
    public static const EDGE_NOT:int = 0;
    public static const EDGE_MAX:int = 1;
    public static var mouseOnEdgeX:int = EDGE_NOT, mouseOnEdgeY:int = EDGE_NOT;
    public static var mouseEdgeDrag:Boolean = false;
    public static const EDGE_DIST_DRAG:int = 20;
    public static const CHUNK_SIZE_MIN:int = EDGE_DIST_DRAG*2;
    
    ////// EDITOR INPUT //////
    
    public static function updateMousePos(mouseX:int, mouseY:int,
                                          width:int, height:int): void
    {
      mx = mouseX;
      my = mouseY;
      if(mx < 0) {
        mx = 0;
      }
      if(mx >= width) {
        mx = width-1;
      }
      if(my < 0) {
        my = 0;
      }
      if(my >= height) {
        my = height-1;
      }
      mx_pregrid = mx; // "_pregrid" means without grid snap applied
      my_pregrid = my;

      cmx_pregrid = mx_pregrid + camera.x;
      cmy_pregrid = my_pregrid + camera.y;
      
      if(gridSnap) {
        mx = toGrid_X(mx); // mx value reflects the closest grid position, if grid is on
        my = toGrid_Y(my);
        
        if(editorBox != null) {
          ax = toGrid_X(ax_pregrid);
          ay = toGrid_Y(ay_pregrid);
        }
      }
      
      cmx = mx + camera.x; // cmx = "Camera mx", i.e. accounting for camera offset
      cmy = my + camera.y;
    }
    
    // reset editor input state
    public static function releaseEditorControls(): void
    {
      editButtonLockedIn = false;
      editorBox = null;
      movingPiece = null;
      movingObj = null;
      mouseEdgeDrag = false;
      mouseOnEdgeX = mouseOnEdgeY = EDGE_NOT;
      if(levelEditor != EDITOR_PIECE) {
        editingChunkType = -1;
      }
    }
    
    ////// EDITOR SUPPORT FUNCTIONS //////
    
    // which piece is being inspected in Piece Edit has changed; copy/load its info into editor
    public static function refreshEditingChunk(): void {
      if(editingChunkType==-1) {
        return;
      }
      var usingPrefab:LevChunkPrefab = LevChunkPrefab.CollisionPrefab[editingChunkType];
      levelLeft = usingPrefab.x;
      levelTop = usingPrefab.y;
      levelRight = usingPrefab.x+usingPrefab.width;
      levelBottom = usingPrefab.y+usingPrefab.height;
      usingPrefab.copyIntoGlobalSetForEditor();
    }
    
    // movingObj is a collision rectangle within a collision prefab for a graphic
    public static function releaseMovingObj(): void {
      if(movingObj != null) {
        movingObj = null;
      }
    }
    
    // switching which prefab is being worked on in Piece Edit
    public static function setEditingChunkType(newType:int): void {
      if(editingChunkType != -1) { // save currently edited type into memory
        LevChunkPrefab.CollisionPrefab[editingChunkType].replaceWithEditorSet();
      }
      releaseEditorControls();

      editingChunkType = newType;

      refreshEditingChunk();
    }

    // editorBox is a collision rectangle that is currently being placed in Piece Editor
    public static function enforceEditorBoxMinCollThickness(): void {
      var dx:int = mx-ax;
      var dy:int = my-ay;
      
      if(dx > 0) {
        editorBox.x = ax;
        editorBox.width = dx;
      } else {
        editorBox.x = mx;
        editorBox.width = -dx;
      }
  
      if(dy > 0) {
        editorBox.y = ay;
        editorBox.height = dy;
      } else {
        editorBox.y = my;
        editorBox.height = -dy;
      }
      
      if(editorBox.width < WALL_TOO_SMALL) {
        editorBox.width = WALL_TOO_SMALL;
      }
      if(editorBox.height < WALL_TOO_SMALL) {
        editorBox.height = WALL_TOO_SMALL;
      }
    }
    
    // see note about enforceEditorBoxMinCollThickness about what editorBox is
    public static function drawEditorBox(toBuffer:BitmapData): void {
      toBuffer.lock();
      toBuffer.fillRect( editorBox, 0xff0000ff );
      toBuffer.unlock();
    }
    
    ////// EDITOR GRID AND WORLD EDGES //////

    public static function drawGrid(toBuffer:BitmapData): void {
      toBuffer.lock();
      drawRect.width=1;
      drawRect.height=toBuffer.height;
      drawRect.y=0;
      for(var i:int=GRID_VIS_SPACING-(camera.x%GRID_VIS_SPACING);i<GAME_WIDTH;i+=GRID_VIS_SPACING) {
        drawRect.x=i;
        toBuffer.fillRect( drawRect, GRID_COLOR );
      }
      drawRect.width=toBuffer.width;
      drawRect.height=1;
      drawRect.x = 0;
      for(var ii:int=GRID_VIS_SPACING-(camera.y%GRID_VIS_SPACING);ii<GAME_HEIGHT;ii+=GRID_VIS_SPACING) {
        drawRect.y=ii;
        toBuffer.fillRect( drawRect, GRID_COLOR );
      }
      toBuffer.unlock();
    }
    
    // takes an arbitrary integer, returns the closest value on the grid (if grid is on)
    public static function toGrid_X(from:int):int {
      if(gridSnap==false) {
        return from;
      }
      from -= GRID_SPACING-(camera.x%GRID_SPACING)-GRID_SPACING/2;
      from /= GRID_SPACING;
      from *= GRID_SPACING;
      from += GRID_SPACING-(camera.x%GRID_SPACING);
      return from;
    }
    public static function toGrid_Y(from:int):int {
      if(gridSnap==false) {
        return from;
      }
      from -= GRID_SPACING-(camera.y%GRID_SPACING)-GRID_SPACING/2;
      from /= GRID_SPACING;
      from *= GRID_SPACING;
      from += GRID_SPACING-(camera.y%GRID_SPACING);
      return from;
    }

    // is mouse currently in a position to move either horizontal or vertical world edge?
    public static function nearAnyEdges():Boolean {
      return (mouseOnEdgeX != EDGE_NOT || mouseOnEdgeY != EDGE_NOT);
    }
    
    ////// EDITOR WORLD SIZE //////
    
    // when the mouse is near enough to the world boundaries, flags the resize indicator
    public static function detectMouseoverEdge(): void {
      mouseOnEdgeX = mouseOnEdgeY = EDGE_NOT;
      if(editorBox == null && movingPiece == null && movingObj==null) {
        if(cmy>levelTop && cmy<levelBottom) {
          if(Math.abs( cmx_pregrid-levelRight ) < EDGE_DIST_DRAG && cmx_pregrid >= levelRight) {
            mouseOnEdgeX = EDGE_MAX;
          } else if(Math.abs( cmx_pregrid-levelLeft ) < EDGE_DIST_DRAG && cmx_pregrid <= levelLeft) {
            mouseOnEdgeX = EDGE_MIN;
          }
        }
        if(cmx>levelLeft && cmx<levelRight) {
          if(Math.abs( cmy_pregrid-levelBottom ) < EDGE_DIST_DRAG && cmy_pregrid >= levelBottom) {
            mouseOnEdgeY = EDGE_MAX;
          } else if(Math.abs( cmy_pregrid-levelTop ) < EDGE_DIST_DRAG && cmy_pregrid <= levelTop) {
            mouseOnEdgeY = EDGE_MIN;
          }
        }
      }
    }
    
    public static function enforceMinWorldSize(): void {
      if(levelRight-levelLeft < MIN_WORLD_WIDTH) {
        levelRight = levelLeft + MIN_WORLD_WIDTH;
      }
      if(levelBottom-levelTop < MIN_WORLD_HEIGHT) {
        levelBottom = levelTop + MIN_WORLD_HEIGHT;
      }
    }

    // when the mouse is set to drag edges, update them according to the mouse position
    public static function draggingWorldEdge(): void {
      if(mouseOnEdgeX == EDGE_MIN) {
        levelLeft = cmx;
        if(levelRight-levelLeft < MIN_WORLD_WIDTH) {
          levelLeft = levelRight - MIN_WORLD_WIDTH;
        }
      } else if(mouseOnEdgeX == EDGE_MAX) {
        levelRight = cmx;
        if(levelRight-levelLeft < MIN_WORLD_WIDTH) {
          levelRight = levelLeft + MIN_WORLD_WIDTH;
        }
      }
      if(mouseOnEdgeY == EDGE_MIN) {
        levelTop = cmy;
        if(levelBottom-levelTop < MIN_WORLD_HEIGHT) {
          levelTop = levelBottom - MIN_WORLD_HEIGHT;
        }
      } else if(mouseOnEdgeY == EDGE_MAX) {
        levelBottom = cmy;
        if(levelBottom-levelTop < MIN_WORLD_HEIGHT) {
          levelBottom = levelTop + MIN_WORLD_HEIGHT;
        }
      }
    }
    
    ////// RENDERING //////
    
    // draws a bitmap centered on a particular point in the world
    public static function centerBitmapOfPosOntoBuffer(
                   bitmap:Bitmap, position:Point, toBuffer:BitmapData,
                   screenSpace:Boolean=false,flipX:Boolean=false,flipY:Boolean=false,
                   rotBy:Number=0.0, stretch:Number=1.0, ct:ColorTransform=null): void {
      if(bitmap==null) {
        return;
      }
      setRectFromBitmap(bitmap,position);
      if(screenSpace || camera.intersects(drawRect)) {
        toBuffer.lock();
        offsetMatrix.identity();

        if(flipX) {
          offsetMatrix.translate(-bitmap.width/2,0);
          offsetMatrix.scale(-1,1)
          offsetMatrix.translate(bitmap.width/2,0);
        }
        if(flipY) {
          offsetMatrix.translate(0,-bitmap.height/2);
          offsetMatrix.scale(1,-1)
          offsetMatrix.translate(0,bitmap.height/2);
        }
        
        offsetMatrix.translate(-bitmap.width/2,-bitmap.height/2);
        offsetMatrix.rotate((flipX ? -rotBy : rotBy));
        offsetMatrix.scale(stretch,stretch);

        if(screenSpace) {
          offsetMatrix.translate(position.x,position.y);
        } else {
          offsetMatrix.translate(position.x-camera.x,position.y-camera.y);
        }
        if(ct == null) {
          toBuffer.draw(bitmap,offsetMatrix);
        } else {
          toBuffer.draw(bitmap,offsetMatrix,ct);
        }
        toBuffer.unlock();
      }
    }

    // like the above function centerBitmapOfPosOntoBuffer, but fits the dimensions
    // to the last used drawRect - for example, for characters to get squished onto buttons
    public static function fitBitmapOfPosOntoBuffer(
                             bitmap:Bitmap,position:Point,toBuffer:BitmapData,
                             stretch:Number=1.0,screenSpace:Boolean=false,
                             preserveRatio:Boolean=false): void {
      if(bitmap==null) {
        return;
      }
      if(preserveRatio) {
        if(bitmap.width / bitmap.height < drawRect.width / drawRect.height) {
          drawRect.width = bitmap.width * drawRect.height / bitmap.height;
        } else {
          drawRect.height = bitmap.height * drawRect.width / bitmap.width;
        }
        drawRect.x = position.x-drawRect.width/2;
        drawRect.y = position.y-drawRect.height/2;
      }

      if(screenSpace || camera.intersects(drawRect)) {
        toBuffer.lock();
        offsetMatrix.identity();
        offsetMatrix.translate(-bitmap.width/2,-bitmap.height/2);
        offsetMatrix.scale(stretch*drawRect.width/bitmap.width,stretch*drawRect.height/bitmap.height);
        if(screenSpace) {
          offsetMatrix.translate(position.x,position.y);
        } else {
          offsetMatrix.translate(position.x-camera.x,position.y-camera.y)
        }
        toBuffer.draw(bitmap,offsetMatrix);
        toBuffer.unlock();
      }
    }
    
    public static function moveCamera(p1:Player): void {
      if((mouseOnEdgeX==EDGE_NOT || // don't let camera slide as wall moves
                mouseEdgeDrag==false)) {
        camera.x = (p1.pos.x-GAME_WIDTH/2)*CAMERA_CHASE_POWER+camera.x*(1.0-CAMERA_CHASE_POWER);
      }
      if((mouseOnEdgeY==EDGE_NOT || // don't let camera drop as floor drops
                mouseEdgeDrag==false)) {
        camera.y = (p1.pos.y-GAME_HEIGHT/2)*CAMERA_CHASE_POWER+camera.y*(1.0-CAMERA_CHASE_POWER);
      }
      if(levelEditor==EDITOR_PLAY) {
        if(camera.x<levelLeft) {
          camera.x = levelLeft;
        }
        if(camera.x+camera.width>levelRight) {
          camera.x = levelRight-camera.width;
        }
        if(camera.y<levelTop) {
          camera.y = levelTop;
        }
        if(camera.y+camera.height>levelBottom) {
          camera.y = levelBottom-camera.height;
        }
      }
    }
    
    ////// RENDERING SUPPORT FUNCTIONS //////
    
    // fills the common/shared drawRect data  structure with the bounds of a positioned image
    // is also handy for collision (which is often based on drawRect) with a bitmap
    public static function setRectFromBitmap(bitmap:Bitmap,position:Point): void {
      if(bitmap==null) {
        return;
      }
      drawRect.width = bitmap.width;
      drawRect.height = bitmap.height;
      drawRect.x = position.x-drawRect.width/2;
      drawRect.y = position.y-drawRect.height/2;
    }

    // allows bitmaps to be referenced via a set of indexes
    public static function bitmapForType(type:int,subType:int,animFrame:int=0): Bitmap {
      switch(type) {
        case STARTCOORD_TYPE_PLAYER:
          return stand_1_BMP;
        case STARTCOORD_TYPE_ENEMY:
          switch(subType) {
            case ENEMY_TYPE_MINE:
              switch(animFrame) {
                case 0:
                  return airmineBMP;
                case 1:
                default:
                  return airmine2BMP;
              }
            case ENEMY_TYPE_BAT: 
              switch(animFrame) {
                case 0:
                  return batty2BMP;
                case 1:
                  return batty3BMP;
                case 2:
                  return batty4BMP;
                case 3:
                  return battyBMP;
                default:
                  return batty2BMP;
              }
            case ENEMY_TYPE_DRAGON: return ghostdragonBMP;
            case ENEMY_TYPE_ICE: return icespikeBMP;
            case ENEMY_TYPE_RAM: return rambiteBMP;
            case ENEMY_TYPE_SEAHORSE:
              switch(animFrame) {
                case 0:
                  return seahorseBMP;
                case 1:
                default:
                  return seahorse2BMP;
              }
            case ENEMY_TYPE_SNAKE:
              switch(animFrame) {
                case 0:
                  return shocksnake2BMP;
                case 1:
                  return shocksnake3BMP;
                case 2:
                default:
                  return shocksnakeBMP;
              }
            case ENEMY_TYPE_SKULL:
              switch(animFrame) {
                case 0:
                  return skulleyeBMP;
                case 1:
                default:
                  return skulleye2BMP;
              }
            case ENEMY_TYPE_SPRING:
              switch(animFrame) {
                case 0:
                  return sleepyspringBMP;
                case 1:
                  return sleepyspring2BMP;
                case 2:
                default:
                  return sleepyspring3BMP;
              }
            case ENEMY_TYPE_WATER:
              switch(animFrame) {
                case 0:
                default:
                  return waterladyBMP;
                case 1:
                  return waterlady2BMP;
              }
          }
        case STARTCOORD_TYPE_ITEM:
          switch(subType) {
            case ITEM_TYPE_DROP: return waterdropBMP;
            case ITEM_TYPE_ARM: return prangyArmBMP;
            case ITEM_TYPE_PRANGY: default: return prangyBMP;
          }
        case STARTCOORD_TYPE_LEVCHUNK:
          switch(subType) {
            case LEVCHUNK_TYPE_2x2_CRATE: return themeArt[THEME_ART_PIECE_2x2];
            case LEVCHUNK_TYPE_2x4_PILLAR: return themeArt[THEME_ART_PIECE_2x4];
            case LEVCHUNK_TYPE_4x1_PLATFORM: return themeArt[THEME_ART_PIECE_4x1];
            case LEVCHUNK_TYPE_4x2_RAMP: return themeArt[THEME_ART_PIECE_4x2];
            case LEVCHUNK_TYPE_8_1_STAIRS: return themeArt[THEME_ART_PIECE_8_1_STAIRS];
            case LEVCHUNK_TYPE_LIP_LEDGE: return themeArt[THEME_ART_PIECE_LEDGE];
            case LEVCHUNK_TYPE_SMALL_LUMPYLAND: return themeArt[THEME_ART_PIECE_LUMPY];
            case LEVCHUNK_TYPE_THIN_POLE: default: return themeArt[THEME_ART_PIECE_POLE];
          }
        case STARTCOORD_TYPE_DECOR:
          switch(subType) {
            case DECOR_TYPE_GROUND_WIDE: return themeArt[THEME_ART_DECOR_BUSH];
            case DECOR_TYPE_FLOATING_MED: return themeArt[THEME_ART_DECOR_CLOUD];
            case DECOR_TYPE_GROUND_TALL: return themeArt[THEME_ART_DECOR_TREE];
            case DECOR_TYPE_WALL_TALL: return themeArt[THEME_ART_DECOR_VINES];
            case DECOR_TYPE_BIG_TILE: default: return themeArt[THEME_ART_DECOR_BIG_TILE];
          }
      }
      return null;
    }
    
    ////// INPUT //////

    // returns true if the mouse is currently in use
    public static function mouseBusy():Boolean {
      return (editorBox != null || movingPiece != null || movingObj != null || 
              mouseEdgeDrag || editButtonLockedIn || 
              editorButtonMousedOver != null);
    }

    ////// MISC SUPPORT FUNCTIONS //////
    
    // puts zeros in front of an integer - used for score display
    public static function zeroPad(val:int, chars:int):String {
      var toRet:String = ""+val;
      while(toRet.length < chars) {
        toRet = "0" + toRet;
      }
      return toRet;
    }
    
    ////// AUDIO //////
    
    private static var soundOn:Boolean = true;
    
    public static function toggleSound(): void {
      soundOn = !soundOn;
    }
    
    public static function playSound(soundRef:Sound): void {
      if(soundOn) {
        soundRef.play();
      }
    }
    
    ////// AUDIO EMBEDS //////
    
    // music/sound
    [Embed(source="music/BOPD_-_6605.mp3")]
    public static var musicClass:Class;
    public static var music:Sound = new musicClass() as Sound;
    
    [Embed(source="sounds/bouncingenemy.mp3")]
    public static var bouncingenemySound:Class;
    public static var bouncingenemySND:Sound = new bouncingenemySound() as Sound;

    [Embed(source="sounds/soar.mp3")]
    public static var soarSound:Class;
    public static var soarSND:Sound = new soarSound() as Sound;

    [Embed(source="sounds/icefall.mp3")]
    public static var icefallSound:Class;
    public static var icefallSND:Sound = new icefallSound() as Sound;

    [Embed(source="sounds/lose.mp3")]
    public static var loseSound:Class;
    public static var loseSND:Sound = new loseSound() as Sound;

    [Embed(source="sounds/mineblast.mp3")]
    public static var mineblastSound:Class;
    public static var mineblastSND:Sound = new mineblastSound() as Sound;

    [Embed(source="sounds/win.mp3")]
    public static var winSound:Class;
    public static var winSND:Sound = new winSound() as Sound;

    [Embed(source="sounds/hurt.mp3")]
    public static var hurtSound:Class;
    public static var hurtSND:Sound = new hurtSound() as Sound;

    [Embed(source="sounds/jump.mp3")]
    public static var jumpSound:Class;
    public static var jumpSND:Sound = new jumpSound() as Sound;

    [Embed(source="sounds/land.mp3")]
    public static var landSound:Class;
    public static var landSND:Sound = new landSound() as Sound;

    [Embed(source="sounds/prangyarm.mp3")]
    public static var prangyarmSound:Class;
    public static var prangyarmSND:Sound = new prangyarmSound() as Sound;

    [Embed(source="sounds/prangyblock.mp3")]
    public static var prangyblockSound:Class;
    public static var prangyblockSND:Sound = new prangyblockSound() as Sound;

    [Embed(source="sounds/prangypop.mp3")]
    public static var prangypopSound:Class;
    public static var prangypopSND:Sound = new prangypopSound() as Sound;

    [Embed(source="sounds/spring.mp3")]
    public static var springSound:Class;
    public static var springSND:Sound = new springSound() as Sound;

    [Embed(source="sounds/waterdrop.mp3")]
    public static var waterdropSound:Class;
    public static var waterdropSND:Sound = new waterdropSound() as Sound;

    ////// LEVEL THEME ART //////

    // level chunks and decoration graphics are loaded at runtime, not embedded
    public static var themeArt:Array = new Array(THEME_ART_NUM);
    public static var loadingImage:int = 0;
    public static var imageLoader:Loader = null;
    
    ////// ART EMBEDS //////
    
    // player animation
    [Embed(source="/images/player/stand1.png")]
    public static var stand_1_Image:Class;
    public static var stand_1_BMP:Bitmap = new stand_1_Image() as Bitmap;
    [Embed(source="/images/player/stand2.png")]
    public static var stand_2_Image:Class;
    public static var stand_2_BMP:Bitmap = new stand_2_Image() as Bitmap;

    [Embed(source="/images/player/run1.png")]
    public static var run_1_Image:Class;
    public static var run_1_BMP:Bitmap = new run_1_Image() as Bitmap;
    [Embed(source="/images/player/run2.png")]
    public static var run_2_Image:Class;
    public static var run_2_BMP:Bitmap = new run_2_Image() as Bitmap;
    [Embed(source="/images/player/run3.png")]
    public static var run_3_Image:Class;
    public static var run_3_BMP:Bitmap = new run_3_Image() as Bitmap;
    [Embed(source="/images/player/run4.png")]
    public static var run_4_Image:Class;
    public static var run_4_BMP:Bitmap = new run_4_Image() as Bitmap;

    [Embed(source="/images/player/fall.png")]
    public static var fall_Image:Class;
    public static var fallBMP:Bitmap = new fall_Image() as Bitmap;
    [Embed(source="/images/player/rise.png")]
    public static var rise_Image:Class;
    public static var riseBMP:Bitmap = new rise_Image() as Bitmap;
    [Embed(source="/images/player/float.png")]
    public static var float_Image:Class;
    public static var floatBMP:Bitmap = new float_Image() as Bitmap;

    // items
    [Embed(source="/images/items/waterdrop.png")]
    public static var waterdrop_Image:Class;
    public static var waterdropBMP:Bitmap = new waterdrop_Image() as Bitmap;
    [Embed(source="/images/items/prangy.png")]
    public static var prangy_Image:Class;
    public static var prangyBMP:Bitmap = new prangy_Image() as Bitmap;
    [Embed(source="/images/items/prangy-arm.png")]
    public static var prangyArm_Image:Class;
    public static var prangyArmBMP:Bitmap = new prangyArm_Image() as Bitmap;

    // enemies
    [Embed(source="/images/enemies/airmine.png")]
    public static var airmine_Image:Class;
    public static var airmineBMP:Bitmap = new airmine_Image() as Bitmap;
    [Embed(source="/images/enemies/airmine2.png")]
    public static var airmine2_Image:Class;
    public static var airmine2BMP:Bitmap = new airmine2_Image() as Bitmap;
    [Embed(source="/images/enemies/batty.png")]
    public static var batty_Image:Class;
    public static var battyBMP:Bitmap = new batty_Image() as Bitmap;
    [Embed(source="/images/enemies/batty2.png")]
    public static var batty2_Image:Class;
    public static var batty2BMP:Bitmap = new batty2_Image() as Bitmap;
    [Embed(source="/images/enemies/batty3.png")]
    public static var batty3_Image:Class;
    public static var batty3BMP:Bitmap = new batty3_Image() as Bitmap;
    [Embed(source="/images/enemies/batty4.png")]
    public static var batty4_Image:Class;
    public static var batty4BMP:Bitmap = new batty4_Image() as Bitmap;
    [Embed(source="/images/enemies/ghostdragon.png")]
    public static var ghostdragon_Image:Class;
    public static var ghostdragonBMP:Bitmap = new ghostdragon_Image() as Bitmap;
    [Embed(source="/images/enemies/icespike.png")]
    public static var icespike_Image:Class;
    public static var icespikeBMP:Bitmap = new icespike_Image() as Bitmap;
    [Embed(source="/images/enemies/rambite.png")]
    public static var rambite_Image:Class;
    public static var rambiteBMP:Bitmap = new rambite_Image() as Bitmap;
    [Embed(source="/images/enemies/seahorse.png")]
    public static var seahorse_Image:Class;
    public static var seahorseBMP:Bitmap = new seahorse_Image() as Bitmap;
    [Embed(source="/images/enemies/seahorse2.png")]
    public static var seahorse2_Image:Class;
    public static var seahorse2BMP:Bitmap = new seahorse2_Image() as Bitmap;
    [Embed(source="/images/enemies/shocksnake.png")]
    public static var shocksnake_Image:Class;
    public static var shocksnakeBMP:Bitmap = new shocksnake_Image() as Bitmap;
    [Embed(source="/images/enemies/shocksnake2.png")]
    public static var shocksnake2_Image:Class;
    public static var shocksnake2BMP:Bitmap = new shocksnake2_Image() as Bitmap;
    [Embed(source="/images/enemies/shocksnake3.png")]
    public static var shocksnake3_Image:Class;
    public static var shocksnake3BMP:Bitmap = new shocksnake3_Image() as Bitmap;
    [Embed(source="/images/enemies/skulleye.png")]
    public static var skulleye_Image:Class;
    public static var skulleyeBMP:Bitmap = new skulleye_Image() as Bitmap;
    [Embed(source="/images/enemies/skulleye2.png")]
    public static var skulleye2_Image:Class;
    public static var skulleye2BMP:Bitmap = new skulleye2_Image() as Bitmap;
    [Embed(source="/images/enemies/sleepyspring.png")]
    public static var sleepyspring_Image:Class;
    public static var sleepyspringBMP:Bitmap = new sleepyspring_Image() as Bitmap;
    [Embed(source="/images/enemies/sleepyspring2.png")]
    public static var sleepyspring2_Image:Class;
    public static var sleepyspring2BMP:Bitmap = new sleepyspring2_Image() as Bitmap;
    [Embed(source="/images/enemies/sleepyspring3.png")]
    public static var sleepyspring3_Image:Class;
    public static var sleepyspring3BMP:Bitmap = new sleepyspring3_Image() as Bitmap;
    [Embed(source="/images/enemies/waterlady.png")]
    public static var waterlady_Image:Class;
    public static var waterladyBMP:Bitmap = new waterlady_Image() as Bitmap;
    [Embed(source="/images/enemies/waterlady2.png")]
    public static var waterlady2_Image:Class;
    public static var waterlady2BMP:Bitmap = new waterlady2_Image() as Bitmap;

    // particle effects graphics
    [Embed(source="/images/pfx/fireBig.png")]
    public static var fireBig_Image:Class;
    public static var fireBigBMP:Bitmap = new fireBig_Image() as Bitmap;
    [Embed(source="/images/pfx/fireTiny.png")]
    public static var fireTiny_Image:Class;
    public static var fireTinyBMP:Bitmap = new fireTiny_Image() as Bitmap;
    [Embed(source="/images/pfx/prangyArmor.png")]
    public static var prangyArmor_Image:Class;
    public static var prangyArmorBMP:Bitmap = new prangyArmor_Image() as Bitmap;
    [Embed(source="/images/pfx/prangyShirt.png")]
    public static var prangyShirt_Image:Class;
    public static var prangyShirtBMP:Bitmap = new prangyShirt_Image() as Bitmap;
    [Embed(source="/images/pfx/prangySkin.png")]
    public static var prangySkin_Image:Class;
    public static var prangySkinBMP:Bitmap = new prangySkin_Image() as Bitmap;
    [Embed(source="/images/pfx/smoke.png")]
    public static var smoke_Image:Class;
    public static var smokeBMP:Bitmap = new smoke_Image() as Bitmap;
    [Embed(source="/images/pfx/spark.png")]
    public static var spark_Image:Class;
    public static var sparkBMP:Bitmap = new spark_Image() as Bitmap;
    
    // editor graphics
    [Embed(source="/images/editor/select.png")]
    public static var select_Image:Class;
    public static var selectBMP:Bitmap = new select_Image() as Bitmap;
    [Embed(source="/images/editor/butback.png")]
    public static var butback_Image:Class;
    public static var butbackBMP:Bitmap = new butback_Image() as Bitmap;
    [Embed(source="/images/editor/help.png")]
    public static var help_Image:Class;
    public static var helpBMP:Bitmap = new help_Image() as Bitmap;
    [Embed(source="/images/editor/load.png")]
    public static var load_Image:Class;
    public static var loadBMP:Bitmap = new load_Image() as Bitmap;
    [Embed(source="/images/editor/play.png")]
    public static var play_Image:Class;
    public static var playBMP:Bitmap = new play_Image() as Bitmap;
    [Embed(source="/images/editor/new.png")]
    public static var new_Image:Class;
    public static var newBMP:Bitmap = new new_Image() as Bitmap;
    [Embed(source="/images/editor/save.png")]
    public static var save_Image:Class;
    public static var saveBMP:Bitmap = new save_Image() as Bitmap;
    [Embed(source="/images/editor/grid.png")]
    public static var grid_Image:Class;
    public static var gridBMP:Bitmap = new grid_Image() as Bitmap;
    [Embed(source="/images/editor/decor.png")]
    public static var decor_Image:Class;
    public static var decorBMP:Bitmap = new decor_Image() as Bitmap;
    [Embed(source="/images/editor/level.png")]
    public static var level_Image:Class;
    public static var levelBMP:Bitmap = new level_Image() as Bitmap;
    [Embed(source="/images/editor/playerStart.png")]
    public static var playerStart_Image:Class;
    public static var playerStartBMP:Bitmap = new playerStart_Image() as Bitmap;

    [Embed(source="/images/menus/gameHelp.png")]
    public static var gameHelp_Image:Class;
    public static var gameHelpBMP:Bitmap = new gameHelp_Image() as Bitmap;
    [Embed(source="/images/menus/gameWin.png")]
    public static var gameWin_Image:Class;
    public static var gameWinBMP:Bitmap = new gameWin_Image() as Bitmap;
    
    [Embed(source="/images/editor/diffset.png")]
    public static var diffSet_Image:Class;
    public static var diffSetBMP:Bitmap = new diffSet_Image() as Bitmap;
    [Embed(source="/images/editor/pieceedit.png")]
    public static var pieceEdit_Image:Class;
    public static var pieceEditBMP:Bitmap = new pieceEdit_Image() as Bitmap;
    [Embed(source="/images/editor/pieceback.png")]
    public static var pieceBack_Image:Class;
    public static var pieceBackBMP:Bitmap = new pieceBack_Image() as Bitmap;
  }
}