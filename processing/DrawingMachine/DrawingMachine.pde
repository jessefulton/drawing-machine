//Duh! http://processing.org/reference/norm_.html

import javax.swing.JFileChooser;
//import javax.swing.filechooser.FileNameExtensionFilter;
import controlP5.*;
import hypermedia.video.*;
import geomerative.*;
import oscP5.*;
import netP5.*;


CommandList COMMANDS;
int TOTAL_COMMANDS=0;

RShape s;
RShape polyshp;
RPoint[][] pathPoints;

int path = 0;
int pathPoint = 0;

int shapeIndex = 0;
int pointIndex = 0;

float GRANULARITY = 1.0;

float origAspectRatio = 1.0;


//This controls the granularity of the points
float SCALE_FACTOR = 2.0;
float SCREEN_SCALE_FACTOR = 1.0;

float ORIGINAL_WIDTH = 0;
float ORIGINAL_HEIGHT = 0;
float MAX_DIM = 0;

float minX, minY, maxX, maxY;

int MIN_THRESH = 10; //50;
int MAX_THRESH = 250;
int THRESH_STEP = 30;
int MAX_BLOB_SIZE;
int MIN_BLOB_SIZE;

boolean PEN_UP = true;
boolean FINISHED = false;

ControlP5 controlP5;
ControlWindow controlWindow;



PTBlob CURRENT_BLOBSET;
int BLOB_POINT_INDEX = 0;


PTBlobs MYBLOBS;

boolean showBlobs = true;

String image_filename = "";
PImage img;
PImage edgeImg;
OpenCV opencv;

int cvFrameSize = 100;
int cvFrameX = 0;
int cvFrameY = 0;


void setup() {
  JFileChooser chooser = new JFileChooser();
  
  try {
      // Create a File object containing the canonical path of the
      // desired directory
      File f = new File(new File("./data").getCanonicalPath());
      // Set the current directory
      chooser.setCurrentDirectory(f);
  }
  catch (IOException e) {
  }
  
  //chooser.setFileFilter(new FileNameExtensionFilter("JPG & GIF Images", "jpg", "gif"));
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    println("You chose to open this file: " + chooser.getSelectedFile().getName());
    image_filename = chooser.getSelectedFile().getAbsolutePath();
  }
  else {
    image_filename = "blank.gif";
    exit();
  }


  frameRate(4);

  img = loadImage(image_filename); // Load the original image
  //img.resize(0, 800);
  MAX_BLOB_SIZE = img.width*img.height/10;
  MIN_BLOB_SIZE = img.width*img.height/2500;


  opencv = new OpenCV(this);
  startServer();


  //tempImg.resize(800,0);



  size(800, 600);
  background(0);

  initControls();

  noFill();
  stroke(0, 90);

  int screenmaxdim = min(height, width);
  float xRatio = img.width / float(width);
  float yRatio = img.height / float(height);
  println("image dimensions: " + img.width + "x" + img.height);
  float resz = max(xRatio, yRatio);
  SCREEN_SCALE_FACTOR = resz < 1.0 ? 1.0 : resz;
  println("SCREEN_SCALE_FACTOR " + SCREEN_SCALE_FACTOR);
  showImage();
  generate();

}

void draw() {
  //controlP5.draw();
}


void keyPressed() {
  if (key == 'h') {
    controlP5.window("controlP5window").hide();
  } else if (key == 's') {
    controlP5.window("controlP5window").show();
  }
}




void generate() {
  PImage tempImg = loadImage(image_filename);
  tempImg.resize(int(img.width*GRANULARITY), int(img.height*GRANULARITY));
  
  tempImg.loadPixels();
 
  //EdgeProcessor edgeProcessor = new EdgeProcessor();
  //  MYBLOBS = edgeProcessor.process(tempImg, new ImageProcessorOptions(8000, MIN_BLOB_SIZE, MAX_BLOB_SIZE, MIN_THRESH, MAX_THRESH, THRESH_STEP));

  PosterizeProcessor processor = new PosterizeProcessor();
  Vector blobs = processor.process(tempImg, 8000, MIN_BLOB_SIZE, MAX_BLOB_SIZE, 6);// , 8000, MAX_BLOB_SIZE, MIN_BLOB_SIZE, 6));
  MYBLOBS = new PTBlobs(blobs);
  
  //GreyscalePosterizeProcessor processor = new GreyscalePosterizeProcessor();
  //Vector blobs = processor.process(tempImg, 8000, MIN_BLOB_SIZE, MAX_BLOB_SIZE, 6);// , 8000, MAX_BLOB_SIZE, MIN_BLOB_SIZE, 6));
  //MYBLOBS = new PTBlobs(blobs);

  MAX_DIM = max(tempImg.height, tempImg.width);
  

  CoordinateMapper coordMapper = new CoordinateMapper(MAX_DIM);
  CommandGenerator cg = new CommandGenerator(MYBLOBS, coordMapper);
  try {
    COMMANDS = cg.generate();
  }
  catch (Exception e) {
    println(e);
    exit();
  }
  TOTAL_COMMANDS = COMMANDS.size();
}


void showImage() {
  background(255);  
  image(img, 0, 0, img.width/SCREEN_SCALE_FACTOR, img.height/SCREEN_SCALE_FACTOR);
}

void showBlobs() {
    background(255);
    println("About to draw " + MYBLOBS.size() + " blobs");
    Iterator iter = MYBLOBS.iterator();
    CoordinateMapper mapper = new CoordinateMapper(MAX_DIM);
    int screenmaxdim = max(img.height, img.width);
    while (iter.hasNext()) {
      PTBlob b = (PTBlob)iter.next();
      beginShape();
      for (int i=0; i<b.points.length; i++) {
        float theX = mapper.map(b.points[i].x + b.xOffset) * (screenmaxdim/SCREEN_SCALE_FACTOR);
        float theY = mapper.map(b.points[i].y + b.yOffset) * (screenmaxdim/SCREEN_SCALE_FACTOR);
    
        stroke(0);
        noFill();

        vertex(theX, theY);
      }
      endShape();

    }
    
    
    /*
    println("finished drawing blobs");
    PImage blobsImage = createImage(width, height, ARGB);
    blobsImage.loadPixels();
    loadPixels();
    for (int i = 0; i < (width*height); i++) {
      blobsImage.pixels[i] = pixels[i];
    }
    blobsImage.updatePixels();
    //blobsImage.filter(INVERT);
    //blobsImage = createEdgeImage(blobsImage);

    //background(255);
    PTBlobs consolidatedBlobs = imageToBlobs(blobsImage);
    for(int i=0; i<consolidatedBlobs.size(); i++) {
      stroke(0, 150);
      noFill();
      PTBlob cb = (PTBlob)consolidatedBlobs.get(i);
      beginShape();
      for (int j=0; j<cb.points.length; j++) {
        vertex(300+cb.points[j].x+cb.xOffset, cb.points[j].y+cb.yOffset);
      }
      endShape();
    }
    */
}



