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

 
/** Sample 10 - How to create fast-rendering terrains from heightmaps,
and how to use texture splatting to make the terrain look good.  */
public class HelloTerrain extends SimpleApplication {
 
  private TerrainQuad terrain;
  private Vector3f lightDir = new Vector3f(-4.9236743f, -1.27054665f, 5.896916f);
  Material mat_terrain;
 
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
    Node mainScene = new Node("Main Scene");
    rootNode.attachChild(mainScene);

    DirectionalLight sun = new DirectionalLight();
    sun.setDirection(lightDir);
    sun.setColor(ColorRGBA.White.clone().multLocal(1.7f));
    mainScene.addLight(sun);

    Spatial sky = SkyFactory.createSky(assetManager, "Scenes/Beach/FullskiesSunset0068.dds", false);
        sky.setLocalScale(350);
        mainScene.attachChild(sky);

    flyCam.setMoveSpeed(50);

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
            val=0.0f;
            r = 0;
            g = 0;
            b = 255;
            counters[0]++;
          } else if (elev>=8000){
            val=255.0f;
            counters[1]++;
          } else {
            val = (elev*255.0f)/8000.0f;
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
          if (b>0 && val>0){
            System.out.println("Strange... "+elev);
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
 
    /** 1. Create terrain material and load four textures into it. */
    mat_terrain = new Material(assetManager, 
            "Common/MatDefs/Terrain/Terrain.j3md");
 
    /** 1.1) Add ALPHA map (for red-blue-green coded splat textures) */
    Texture alpha_texture = new Texture2D();
    alpha_texture.setImage(textureImage);
    mat_terrain.setTexture("Alpha", alpha_texture);

    Texture alpha_texture2 = new Texture2D();
    alpha_texture.setImage(textureImage);
    mat_terrain.setTexture("Alpha", alpha_texture);

    //System.out.println("Image at 1000,1000: "+textureImage)

    //mat_terrain.setTexture("Alpha", assetManager.loadTexture("Textures/Terrain/splat/alphamap.png"));
 

    assetManager.registerLocator("/Users/federico/repos/worldgen/jmedemo/HeightMapNavigator/assets/", FileLocator.class);
    //mat_terrain.setTexture("Alpha", assetManager.loadTexture("Textures/alphamap.png"));
    /** 1.2) Add GRASS texture into the red layer (Tex1). */
    Texture grass = assetManager.loadTexture(
            "Textures/Terrain/splat/grass.jpg");
    grass.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture("Tex1", grass);
    mat_terrain.setFloat("Tex1Scale", 64f);
 
    /** 1.3) Add DIRT texture into the green layer (Tex2) */
    Texture dirt = assetManager.loadTexture(
            "Textures/Terrain/splat/dirt.jpg");
    dirt.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture("Tex2", dirt);
    mat_terrain.setFloat("Tex2Scale", 32f);
 
    /** 1.4) Add ROAD texture into the blue layer (Tex3) */
    Texture water = assetManager.loadTexture("Textures/water.png");
    Texture beach = assetManager.loadTexture("Textures/beach.png");

    Texture rock = assetManager.loadTexture(
            "Textures/Terrain/splat/road.jpg");
    rock.setWrap(WrapMode.Repeat);
    mat_terrain.setTexture("Tex3", water);
    mat_terrain.setFloat("Tex3Scale", 128f);
    //mat_terrain.setTexture("Tex4", beach);
    //mat_terrain.setFloat("Tex4Scale", 128f);
 
    /** 2. Create the height map */
    /*AbstractHeightMap heightmap = null;
    Texture heightMapImage = assetManager.loadTexture(
            "Textures/Terrain/splat/mountains512.png");
    heightmap = new ImageBasedHeightMap(heightMapImage.getImage());
    heightmap.load();*/

   //createSky();
 
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

    /*rootNode.attachChild(SkyFactory.createSky(
            assetManager, "Textures/Sky/Bright/BrightSky.dds", false));*/
 
    /** 5. The LOD (level of detail) depends on were the camera is: */
    TerrainLodControl control = new TerrainLodControl(terrain, getCamera());
    control.setLodCalculator( new DistanceLodCalculator(65, 1000007f) );
    terrain.addControl(control);
  }
}