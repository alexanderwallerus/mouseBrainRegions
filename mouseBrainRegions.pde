//code by Alexander Wallerus
//MIT License

boolean showAllRegions = false;
boolean hemisphere = true;

import peasy.PeasyCam;
PeasyCam cam;

int[][][] ids;
HashMap<Integer, Integer> idCols;
PShape zLayers[];

IntList myRegions;
Cursor cursor;
boolean showMesh = false;

//This code needs the toxiclibs processing library installed
import toxi.geom.*;
import toxi.geom.mesh.*;
import toxi.volume.*;
import toxi.processing.*;
ToxiclibsSupport gfx;

//scale of the volume relative to the smallest dim, here 320; i.e. 320*1.425 = 456
Vec3D toxScale = new Vec3D(1.65, 1, 1.425); 
VolumetricSpaceArray volume = new VolumetricSpaceArray(toxScale, 528, 320, 456);
IsoSurface surface = new ArrayIsoSurface(volume);
TriangleMesh mesh;

void setup(){
  size(1000, 1000, P3D);

  cam = new PeasyCam(this, 400);
  //increase the zFar clipping plane from default to 20x
  float cameraZ = (height/2.0) / tan(PI*60.0/360.0);
  perspective(PI/3.0, width/height, cameraZ/100.0, cameraZ*10.0 *20);
  
  hint(DISABLE_DEPTH_SORT);
  hint(DISABLE_DEPTH_TEST);
  hint(DISABLE_DEPTH_MASK);
  hint(ENABLE_STROKE_PERSPECTIVE);
  
  cursor = new Cursor();
  
  //load the IDs of the regions to be visualized
  myRegions = new IntList();
  String[] lines = loadStrings("myRegions/regions.txt");
  for(String l : lines){
    myRegions.append(int(trim( split(l, ',')[1] )));
  }
  
  ids = new int[528][320][456];
  //colors are just ints => can store each color as an int with color(r, g, b) 
  //and access its r, g, b with red(c), green(c), blue(c) or its int as color(c)
  idCols = new HashMap<Integer, Integer>();

  //current byte
  int i=0;          
  //grid positions
  int x=0, y=0, z=0;
  //color the nothingness black
  idCols.put(0, color(0));

  byte b[] = loadBytes("allenData/annotation.raw");
  //println(b.length);//308,183,040 8bit bytes /4= 77,045,760 32 bit bytes/data points
  
  while(i < b.length){
    //this data is encoded in little endian uint32
    //bytes are -128 to 127 => convert to uint8; 0 to 255
    int firstByte = b[i+3] & 0xff; 
    int secondByte = b[i+2] & 0xff; 
    int thirdByte = b[i+1] & 0xff; 
    int fourthByte = b[i] & 0xff; 
    //the data is in little endian => last byte in order is the highest magnitude
    int id = 256*256*256*firstByte + 256*256*secondByte + 256*thirdByte + fourthByte;
    ids[x][y][z] = id;   
    //if(ids[x][y][z] != 0){
    //  println("xyz:", x, y, z, "ID:", ids[x][y][z]);
    //}  

    if(!idCols.containsKey(id)){
      //this id hasn't been encountered yet
      println("new id: " + id);
      println("found at xyz: ", x, y, z); 
      
      if(showAllRegions){
        //choose a random color for each region
        idCols.put(id, color(random(256), random(256), random(256)));
      } else {
        //if this new region is within myRegions, assign it a special color
        boolean inMyRegions = false;
        for(int region : myRegions){
          if(id == region){
            //println("found region: " + id);
            inMyRegions = true;
          }
        }
        if(inMyRegions){
          idCols.put(id, color(random(0, 256), random(0, 256), random(100, 256)));
        } else {
          idCols.put(id, color(0, 0, random(0, 100)));
        }
      }
      println("asigned color: " +  red(idCols.get(id)) + "," + green(idCols.get(id)) +
                            "," + blue(idCols.get(id)));
    }
    
    //move on 4 bytes
    i += 4;
    x++;
    if(x>=528){
      x=0;
      y++;
      if(y>=320){
        y=0;
        z++;
        if(z % 10 == 0){
          println("z rollover, new z: " + z);
        }
      }
    }
  }
  println("filled in volume data");
  
  //check if all IDs for myRegions were properly utilized
  checkUsedIDs();
  
  //Cannot fit all data into a single shape => use a group shape made of z slices
  zLayers = new PShape[456];
  for(int l=0; l<zLayers.length; l++){
    zLayers[l] = createShape(GROUP);
  }
  
  println("creating point cloud");
  int untilZ = hemisphere ? ids[0][0].length/2 : ids[0][0].length;
  
  //throughout each z, y, x add a point with the region's color
  for(z=0; z<untilZ; z++){
    PShape layer = createShape();
    layer.beginShape(POINTS);
    for(y=0; y<ids[0].length; y++){
      for(x=0; x<ids.length; x++){
        layer.strokeWeight(1);
        layer.noFill();
        int id = ids[x][y][z];
        color c = idCols.get(id);
        layer.stroke(c);
        //only add to the point cloud if it is not black
        if(id != 0){
          layer.vertex(x, y, z);
        }
      }
    }
    layer.endShape(); 
    zLayers[z].addChild(layer);
    if(z % 10 == 0){
      println("finished z layer: " + z);
    }
  }

  println("created point cloud");
  
  gfx = new ToxiclibsSupport(this);
}

void draw(){
  background(0);
  blendMode(LIGHTEST);
  if(!showMesh){
    for(PShape l : zLayers){
      shape(l);
    }
  } else if (mesh != null){
    pushMatrix();
      ambientLight(48,48,48);
      lightSpecular(230,230,230);
      directionalLight(255,255,255,0,-0.5,1);
      specular(255,255,255);
      shininess(16.0);
      noStroke();
      fill(255);
      //the mesh will be centered at the origin => move to the center of its volume
      translate(264, 160, 228);
      //the mesh is originally length 1 at its smallest dimension
      scale(320);
      gfx.mesh(mesh, true);
    popMatrix();
  }
  drawAxis(new PVector(0, 0, 0));
  cursor.update();
  cursor.show();
  //println(frameCount);
}

void exportMesh(){
  float[] volumeData = volume.getData();
  int i = 0;
  for(int z=0; z<ids[0][0].length; z++){
    for(int y=0; y<ids[0].length; y++){
      for(int x=0; x<ids.length; x++){
        boolean inMyRegions = false;
        for(int region : myRegions){
          if(ids[x][y][z] == region){
            inMyRegions = true;
          }
        }
        if(showAllRegions){
          inMyRegions = ids[x][y][z] != 0 ? true : false;
        }
        if(inMyRegions){
          volumeData[i] = 1.0;
        } else {
          volumeData[i] = 0.0;
        }
        i++;
      }
    }
  }
  volume.closeSides();
  surface.reset();
  float isoThreshold = 0.1;
  mesh = (TriangleMesh)surface.computeSurfaceMesh(mesh, isoThreshold);
  println("created mesh with " + mesh.getNumFaces() + " faces");
  String date = str(year()) + nf(month(), 2) + nf(day(), 2);
  String saveDir = "/exports/myRegions" + date + ".stl";
  mesh.saveAsSTL(sketchPath(saveDir), true);
}

class Cursor{
  int x, y, z;
  //check the following keys
  boolean isShift, isControl, isX, isY, isZ;
  
  void cursor(){
    x = 0; y = 0; z = 0;
  }
  
  void update(){
    int scaling = 1;
    if(isShift){  scaling = -1;  }
    if(isControl){  scaling *= 10;  }
    if(isX){  x += scaling;  }  
    if(isY){  y += scaling;  }
    if(isZ){  z += scaling;  }
    x = constrain(x, 0, 527);
    y = constrain(y, 0, 319);
    z = constrain(z, 0, 455);
  }
  
  void show(){
    pushStyle();
      int localID = ids[x][y][z];
      PVector cursorPos = new PVector(screenX(x, y, z), screenY(x, y, z), 
                                      screenZ(x, y, z));
      cam.beginHUD();
        textSize(15);
        fill(255);
        textAlign(LEFT);
        text("current ID at cursor position: " + localID, 10, 15);
        stroke(255);  noFill();
        ellipseMode(CENTER);
        ellipse(cursorPos.x, cursorPos.y, 12, 12);
      cam.endHUD();
    popStyle();
  }
  
  boolean moveCursor(int k, boolean b){
  //this function allows reading simultaneous key presses
  //println(k);
  switch(k){
    case 16:
      return isShift = b;
    case 17:
      return isControl = b;
    case 88:
      return isX = b;
    case 89:
      return isY = b;
    case 90:
      return isZ = b;
    default:
      return b;
    }
  }
}

void keyPressed(){
  cursor.moveCursor(keyCode, true);
  if(key == 'm'){
    showMesh = !showMesh;
  }
  if(key == 'e'){
    println("creating and exporting mesh\nPreview it with \"m\"");
    exportMesh();
  }
}
void keyReleased(){
  cursor.moveCursor(keyCode, false);
}

void checkUsedIDs(){
 for(int id : myRegions){
    boolean found = false;
    for(int val : idCols.keySet()){
      if(id == val){
        found = true;
      }
    //alternatively check if(idCols.containsKey(id)){
    }
    if(found){
      println("found ID: " + id + " in brain region data");
    }
    else {
      println("couldn't find ID: " + id + " in brain region data");
    }
  }
}

void drawAxis(PVector pos){
  float l = 50;
  stroke(255, 0, 0);
  strokeWeight(2);
  line(pos.x, pos.y, pos.z, pos.x+l, pos.y, pos.z);
  PVector xAxis = new PVector(screenX(pos.x+l, pos.y, pos.z), 
                  screenY(pos.x+l, pos.y, pos.z), screenZ(pos.x+l, pos.y, pos.z));
  stroke(0, 255, 0);
  line(pos.x, pos.y, pos.z, pos.x, pos.y+l, pos.z);
  PVector yAxis = new PVector(screenX(pos.x, pos.y+l, pos.z),
                  screenY(pos.x, pos.y+l, pos.z), screenZ(pos.x, pos.y+l, pos.z));
  stroke(0, 0, 255);
  line(pos.x, pos.y, pos.z, pos.x, pos.y, pos.z+l);
  PVector zAxis = new PVector(screenX(pos.x, pos.y, pos.z+l), 
                  screenY(pos.x, pos.y, pos.z+l), screenZ(pos.x, pos.y, pos.z+l));
  strokeWeight(1);
  cam.beginHUD();
    textAlign(CENTER);
    textSize(20);
    fill(255, 0, 0);
    text("X Axis", xAxis.x, xAxis.y, xAxis.z);
    fill(0, 255, 0);
    text("Y Axis", yAxis.x, yAxis.y, yAxis.z);
    fill(0, 0, 255);
    text("Z Axis", zAxis.x, zAxis.y, zAxis.z);
    textAlign(LEFT);
    //text("This Text is in the top left", 10, 10);  
  cam.endHUD();
}
