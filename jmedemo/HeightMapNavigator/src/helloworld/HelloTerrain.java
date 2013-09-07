package helloworld;
 
import com.jme3.app.SimpleApplication;
import com.jme3.material.Material;
import com.jme3.renderer.Camera;
import com.jme3.terrain.geomipmap.TerrainLodControl;
import com.jme3.terrain.heightmap.AbstractHeightMap;
import com.jme3.terrain.geomipmap.TerrainQuad;
import com.jme3.terrain.geomipmap.lodcalc.DistanceLodCalculator;
import com.jme3.terrain.heightmap.HillHeightMap; // for exercise 2
import com.jme3.terrain.heightmap.ImageBasedHeightMap;
import com.jme3.texture.Texture;
import com.jme3.texture.Texture.WrapMode;
import java.util.ArrayList;
import java.util.List;
import java.nio.channels.FileChannel;
import java.io.RandomAccessFile;
import java.nio.MappedByteBuffer;
import com.jme3.texture.Image;
import java.nio.ByteBuffer;
import com.jme3.texture.Texture2D;
import com.jme3.asset.plugins.FileLocator;
import com.jme3.util.SkyFactory;
import com.jme3.light.DirectionalLight;
import com.jme3.math.Vector3f;
import com.jme3.scene.Spatial;
import com.jme3.renderer.queue.RenderQueue.ShadowMode;
import com.jme3.scene.Node;
import com.jme3.math.ColorRGBA;
import com.jme3.app.SimpleApplication;
import com.jme3.bullet.BulletAppState;
import com.jme3.bullet.collision.shapes.CapsuleCollisionShape;
import com.jme3.bullet.collision.shapes.CollisionShape;
import com.jme3.bullet.control.CharacterControl;
import com.jme3.bullet.control.RigidBodyControl;
import com.jme3.bullet.util.CollisionShapeFactory;
import com.jme3.input.KeyInput;
import com.jme3.input.controls.ActionListener;
import com.jme3.input.controls.KeyTrigger;
import com.jme3.material.Material;
import com.jme3.math.Vector3f;
import com.jme3.renderer.Camera;
import com.jme3.scene.Node;
import com.jme3.terrain.geomipmap.TerrainLodControl;
import com.jme3.terrain.heightmap.AbstractHeightMap;
import com.jme3.terrain.geomipmap.TerrainQuad;
import com.jme3.terrain.heightmap.ImageBasedHeightMap;
import com.jme3.texture.Texture;
import com.jme3.texture.Texture.WrapMode;
import java.util.ArrayList;
import java.util.List;
import jme3tools.converters.ImageToAwt;
import com.jme3.post.FilterPostProcessor;
import com.jme3.water.WaterFilter;
 
/** Sample 10 - How to create fast-rendering terrains from heightmaps,
and how to use texture splatting to make the terrain look good.  */
public class HelloTerrain extends SimpleApplication implements ActionListener {
 
  private TerrainQuad terrain;
  private Vector3f lightDir = new Vector3f(-4.9236743f, -1.27054665f, 5.896916f);
  private BulletAppState bulletAppState;
  private RigidBodyControl landscape;
  private CharacterControl player;
  private Vector3f walkDirection = new Vector3f();
  private boolean left = false, right = false, up = false, down = false;
  Material mat_terrain;
  private FilterPostProcessor fpp;
  private WaterFilter water;
  //private Vector3f lightDir = new Vector3f(-4.9f, -1.3f, 5.9f); // same as light source
  private float initialWaterHeight = 0.0f; // choose a value for your scene

  private static String[] TERRAIN_TEXTURE_NAMES = new String[]{
      "Tex1", "Tex2", "Tex3"
  };
  private static String[] TERRAIN_TEXTURE_SCALE_NAMES = new String[]{
      "Tex1Scale", "Tex2Scale", "Tex3Scale"
  };
  private static String[] ALPHA_TEXTURE_NAMES = new String[]{
    "Alpha"
  };
  //private static String TERRAIN_MATERIAL_NAME = "Common/MatDefs/Terrain/Terrain.j3md";
  private static String TERRAIN_MATERIAL_NAME = "MatDefs/MyTerrain.j3md";

  /*private static String[] TERRAIN_TEXTURE_NAMES = new String[]{
      "DiffuseMap", "DiffuseMap_1", "DiffuseMap_2"
  };
  private static String[] TERRAIN_TEXTURE_SCALE_NAMES = new String[]{
      "DiffuseMap_0_scale", "DiffuseMap_1_scale", "DiffuseMap_2_scale"
  };
  private static String[] ALPHA_TEXTURE_NAMES = new String[]{
    "AlphaMap", "AlphaMap_1"
  };
  private static String TERRAIN_MATERIAL_NAME = "Common/MatDefs/Terrain/TerrainLighting.j3md";  
 */
  public static void main(String[] args) {
    HelloTerrain app = new HelloTerrain();
    app.start();
  }

    private void createSky() {
        Texture west = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_west.jpg");
        Texture east = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_east.jpg");
        Texture north = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_north.jpg");
        Texture south = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_south.jpg");
        Texture up = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_up.jpg");
        Texture down = assetManager.loadTexture("Textures/Sky/Lagoon/lagoon_down.jpg");

        Spatial sky = SkyFactory.createSky(assetManager, west, east, north, south, up, down);
        rootNode.attachChild(sky);
    }
 
  @Override
  public void simpleInitApp() {
    /** Set up Physics */
    bulletAppState = new BulletAppState();
    stateManager.attach(bulletAppState);


    Node mainScene = new Node("Main Scene");
    rootNode.attachChild(mainScene);

    DirectionalLight sun = new DirectionalLight();
    sun.setDirection(lightDir);
    sun.setColor(ColorRGBA.White.clone().multLocal(1.7f));
    mainScene.addLight(sun);

    Spatial sky = SkyFactory.createSky(assetManager, "Scenes/Beach/FullskiesSunset0068.dds", false);
        sky.setLocalScale(350);
        mainScene.attachChild(sky);

    flyCam.setMoveSpeed(150);
    setUpKeys();

    short map_width = 2049;
    short map_height = 2049;

    ByteBuffer textureData = ByteBuffer.allocateDirect(map_width*map_height*4);
    ByteBuffer textureData_2 = ByteBuffer.allocateDirect(map_width*map_height*4);
    float[] myHeightMap = new float[map_width * map_height];
    
    System.out.println("LOADING MAP... START");
    int[] counters = new int[]{0,0,0,0};
    try {
      String path = "/Users/federico/my_world/elevation_java";
      RandomAccessFile rac = new RandomAccessFile(path, "rw");
      FileChannel fc = rac.getChannel();
      FileChannel.MapMode rw_mode = FileChannel.MapMode.READ_WRITE;
      MappedByteBuffer mbb_metadata = fc.map(rw_mode, 0, 4);
      short width = mbb_metadata.getShort(0);
      short height = mbb_metadata.getShort(2);
      System.out.println("map size: "+width+"x"+height);
      MappedByteBuffer mbb_values = fc.map(rw_mode, 4, fc.size()-4);

      
      int startx = 0;
      int starty = 0;
      for (int x=0;x<map_width ;x++){
        for (int y=0;y<map_height;y++){
          float elev = 0.0f;
          if (x<3000 && y<2000){
            elev = mbb_values.getFloat((((y+starty)*width)<<2)+((x+startx)<<2));
            elev = elev / 3.0f;
          }
          float val = 0.0f;
          int r=0,g=0,b=0,a=255;
          int r2=0,g2=0,b2=0,a2=0;
          if (elev<=0) {
            if (elev<=-5000){
              val = 0.0f;
            } else {
              val = (elev+5000.0f)/50.0f;
            }
            r = 0;
            g = 0;
            b = 255;
            counters[0]++;
          } else if (elev>=8000){
            val=255.0f;
            counters[1]++;
          } else {
            val = 100.0f+((elev*155.0f)/8000.0f);
            if (elev<500){
              r = 255;
              g = 0;
              b = 0;
              counters[2]++;
            } else {
              r = 0;
              g = 255;
              b = 0;    
              counters[3]++;          
            }
          }
          int ix = map_width - (x+1);
          myHeightMap[ix*map_width+y]=val;

          //System.out.println("ASKING: "+((y*513+x)*3+2));
          // textureData.putChar((y*513+x)*3+0,b); 
          // textureData.putChar((y*513+x)*3+1,g);
          // textureData.putChar((y*513+x)*3+2,r);
          textureData.     
            put((byte) r).
            put((byte) g).
            put((byte) b).
            put((byte) a);
          textureData_2.     
            put((byte) 0).
            put((byte) 0).
            put((byte) 0).
            put((byte) 255);            
        }
      }

      fc.close();
      rac.close();
    } catch (Exception e){
      e.printStackTrace();
    }

    System.out.println("Counters 0 "+counters[0]);
    System.out.println("Counters 1 "+counters[1]);
    System.out.println("Counters 2 "+counters[2]);
    System.out.println("Counters 3 "+counters[3]);
    System.out.println("LOADING MAP... DONE");


    Image textureImage = new Image(Image.Format.RGBA8,map_width,map_height,textureData);
    Image textureImage_2 = new Image(Image.Format.RGBA8,map_width,map_height,textureData_2);
 
assetManager.registerLocator("/Users/federico/repos/worldgen/jmedemo/HeightMapNavigator/assets/", FileLocator.class);
    

    /** 1. Create terrain material and load four textures into it. */
    mat_terrain = new Material(assetManager, TERRAIN_MATERIAL_NAME);

    //mat_terrain = new Material(assetManager, "Common/MatDefs/Terrain/TerrainLighting.j3md");
    //mat_terrain.setBoolean("useTriPlanarMapping", false);
    //mat_terrain.setFloat("Shininess", 0.0f);
 
    /** 1.1) Add ALPHA map (for red-blue-green coded splat textures) */
    Texture alpha_texture = new Texture2D();
    alpha_texture.setImage(textureImage);
    mat_terrain.setTexture(ALPHA_TEXTURE_NAMES[0], alpha_texture);

    Texture alpha_texture2 = new Texture2D();
    alpha_texture2.setImage(textureImage_2);
    //mat_terrain.setTexture(ALPHA_TEXTURE_NAMES[1], alpha_texture2);

    //System.out.println("Image at 1000,1000: "+textureImage)

    //mat_terrain.setTexture("Alpha", assetManager.loadTexture("Textures/Terrain/splat/alphamap.png"));
 

    //mat_terrain.setTexture("Alpha", assetManager.loadTexture("Textures/alphamap.png"));
    /** 1.2) Add GRASS texture into the red layer (Tex1). */
    Texture grass = assetManager.loadTexture(
            "Textures/Terrain/splat/grass.jpg");
    grass.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture(TERRAIN_TEXTURE_NAMES[0], grass);
    mat_terrain.setFloat(TERRAIN_TEXTURE_SCALE_NAMES[0], 64f);
 
    /** 1.3) Add DIRT texture into the green layer (Tex2) */
    Texture dirt = assetManager.loadTexture(
            "Textures/Terrain/splat/dirt.jpg");
    dirt.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture(TERRAIN_TEXTURE_NAMES[1], dirt);
    mat_terrain.setFloat(TERRAIN_TEXTURE_SCALE_NAMES[1], 32f);
 
    /** 1.4) Add ROAD texture into the blue layer (Tex3) */
    Texture water = assetManager.loadTexture("Textures/water.png");
    Texture beach = assetManager.loadTexture("Textures/beach.png");

    Texture rock = assetManager.loadTexture(
            "Textures/Terrain/splat/road.jpg");
    rock.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture(TERRAIN_TEXTURE_NAMES[2], water);
    mat_terrain.setFloat(TERRAIN_TEXTURE_SCALE_NAMES[2], 128f);
 
    /** 3. We have prepared material and heightmap. 
     * Now we create the actual terrain:
     * 3.1) Create a TerrainQuad and name it "my terrain".
     * 3.2) A good value for terrain tiles is 64x64 -- so we supply 64+1=65.
     * 3.3) We prepared a heightmap of size 512x512 -- so we supply 512+1=513.
     * 3.4) As LOD step scale we supply Vector3f(1,1,1).
     * 3.5) We supply the prepared heightmap itself.
     */
    int patchSize = 65;
    terrain = new TerrainQuad("my terrain", patchSize, map_width, myHeightMap);
        


    
 
    /** 4. We give the terrain its material, position & scale it, and attach it. */
    terrain.setMaterial(mat_terrain);
    terrain.setLocalTranslation(0, -100, 0);
    terrain.setLocalScale(2f, 1f, 2f);
    terrain.setShadowMode(ShadowMode.Receive);
    rootNode.attachChild(terrain);

    waterStuff();

    /** 5. The LOD (level of detail) depends on were the camera is: */
    TerrainLodControl control = new TerrainLodControl(terrain, getCamera());
    control.setLodCalculator( new DistanceLodCalculator(65, 1000007f) );
    terrain.addControl(control);

    // We set up collision detection for the scene by creating a static 
    /* RigidBodyControl with mass zero.*/
    terrain.addControl(new RigidBodyControl(0));
 
    // We set up collision detection for the player by creating
    // a capsule collision shape and a CharacterControl.
    // The CharacterControl offers extra settings for
    // size, stepheight, jumping, falling, and gravity.
    // We also put the player in its starting position.
    CapsuleCollisionShape capsuleShape = new CapsuleCollisionShape(1.5f, 6f, 1);
    player = new CharacterControl(capsuleShape, 0.05f);
    player.setJumpSpeed(20);
    player.setFallSpeed(30);
    player.setGravity(0);
    player.setPhysicsLocation(new Vector3f(-10, 10, 10));
 
    // We attach the scene and the player to the rootnode and the physics space,
    // to make them appear in the game world.
    bulletAppState.getPhysicsSpace().add(terrain);
    bulletAppState.getPhysicsSpace().add(player);
  }

  private void waterStuff(){
    fpp = new FilterPostProcessor(assetManager);
  water = new WaterFilter(rootNode, lightDir);
  water.setWaterHeight(initialWaterHeight);
  fpp.addFilter(water);
  viewPort.addProcessor(fpp);
  }

  /**
   * This is the main event loop--walking happens here.
   * We check in which direction the player is walking by interpreting
   * the camera direction forward (camDir) and to the side (camLeft).
   * The setWalkDirection() command is what lets a physics-controlled player walk.
   * We also make sure here that the camera moves with player.
   */
  @Override
  public void simpleUpdate(float tpf) {
    Vector3f camDir = cam.getDirection().clone().multLocal(0.6f);
    Vector3f camLeft = cam.getLeft().clone().multLocal(0.4f);
    walkDirection.set(0, 0, 0);
    if (left)  { walkDirection.addLocal(camLeft); }
    if (right) { walkDirection.addLocal(camLeft.negate()); }
    if (up)    { walkDirection.addLocal(camDir); }
    if (down)  { walkDirection.addLocal(camDir.negate()); }
    player.setWalkDirection(walkDirection);
    cam.setLocation(player.getPhysicsLocation());
  }

  /** These are our custom actions triggered by key presses.
   * We do not walk yet, we just keep track of the direction the user pressed. */
  public void onAction(String binding, boolean value, float tpf) {
    if (binding.equals("Left")) {
      if (value) { left = true; } else { left = false; }
    } else if (binding.equals("Right")) {
      if (value) { right = true; } else { right = false; }
    } else if (binding.equals("Up")) {
      if (value) { up = true; } else { up = false; }
    } else if (binding.equals("Down")) {
      if (value) { down = true; } else { down = false; }
    } else if (binding.equals("Jump")) {
      player.jump();
    }
  }

    /** We over-write some navigational key mappings here, so we can
   * add physics-controlled walking and jumping: */
  private void setUpKeys() {
    inputManager.addMapping("Left", new KeyTrigger(KeyInput.KEY_A));
    inputManager.addMapping("Right", new KeyTrigger(KeyInput.KEY_D));
    inputManager.addMapping("Up", new KeyTrigger(KeyInput.KEY_W));
    inputManager.addMapping("Down", new KeyTrigger(KeyInput.KEY_S));
    inputManager.addMapping("Jump", new KeyTrigger(KeyInput.KEY_SPACE));
    inputManager.addListener(this, "Left");
    inputManager.addListener(this, "Right");
    inputManager.addListener(this, "Up");
    inputManager.addListener(this, "Down");
    inputManager.addListener(this, "Jump");
  }
}