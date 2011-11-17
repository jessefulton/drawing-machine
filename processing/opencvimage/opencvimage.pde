//Duh! http://processing.org/reference/norm_.html

import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;
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
  
  chooser.setFileFilter(new FileNameExtensionFilter("JPG & GIF Images", "jpg", "gif"));
  int returnVal = chooser.showOpenDialog(null);
  if (returnVal == JFileChooser.APPROVE_OPTION) {
    println("You chose to open this file: " + chooser.getSelectedFile().getName());
    image_filename = chooser.getSelectedFile().getAbsolutePath();
  }
  else {
    image_filename = "blank.gif";
    exit();
  }


  frameRate(120);

  img = loadImage(image_filename); // Load the original image
  //img.resize(0, 800);


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



//TODO: I think we're currently only doing black and white - see what happens when doing each RGB channel individually
void generate() {
  PImage tempImg = loadImage(image_filename);
  tempImg.resize(int(img.width*GRANULARITY), int(img.height*GRANULARITY));
  
  tempImg.loadPixels();

  PImage redChannel = createImage(tempImg.width, tempImg.height, RGB);
  PImage greenChannel = createImage(tempImg.width, tempImg.height, RGB);
  PImage blueChannel = createImage(tempImg.width, tempImg.height, RGB);
  redChannel.loadPixels();
  greenChannel.loadPixels();
  blueChannel.loadPixels();
  for (int i=0; i< tempImg.pixels.length; i++) {
    redChannel.pixels[i] = color(red(tempImg.pixels[i]));
    greenChannel.pixels[i] = color(green(tempImg.pixels[i]));
    blueChannel.pixels[i] = color(blue(tempImg.pixels[i]));
  }

  MYBLOBS = new PTBlobs();

  PImage[] channels = {redChannel, greenChannel, blueChannel};

  for(int i=0; i< channels.length; i++) {
    PImage channel = channels[i];
    PImage edged = createEdgeImage(channel);
    
    PTBlobs channelBlobs = imageToBlobs(edged);
    MYBLOBS.addAll(channelBlobs);
  }
  
  
  
  edgeImg = createEdgeImage(tempImg);
  MYBLOBS.addAll(imageToBlobs(edgeImg));

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
    Iterator iter = MYBLOBS.iterator();
    CoordinateMapper mapper = new CoordinateMapper(MAX_DIM);
    int screenmaxdim = max(img.height, img.width);
    while (iter.hasNext()) {
      PTBlob b = (PTBlob)iter.next();
      println(b.thresh);
    //background(0,0,255);
    stroke(0,255,0, 30);
    //noFill();

      beginShape();
      for (int i=0; i<b.points.length; i++) {
        float theX = mapper.map(b.points[i].x + b.xOffset) * (screenmaxdim/SCREEN_SCALE_FACTOR);
        float theY = mapper.map(b.points[i].y + b.yOffset) * (screenmaxdim/SCREEN_SCALE_FACTOR);
        vertex(theX, theY);
      }
      endShape();

    }
    println("finished drawing blobs");
}


PTBlobs imageToBlobs(PImage theImg) {
  PTBlobs blobs = new PTBlobs();

  int cvFrameWidth = theImg.width;
  int xStep = cvFrameWidth - (cvFrameWidth/4);
  int cvFrameHeight = theImg.height;
  int yStep = cvFrameHeight - (cvFrameHeight/4);
  int MAX_BLOB_SIZE = cvFrameWidth*cvFrameHeight/10;
  int MIN_BLOB_SIZE = cvFrameWidth*cvFrameHeight/2500;
  println("min blob size: " + MIN_BLOB_SIZE);
  int MAX_BLOBS = 8000;



  //  for (int x=0; x<=theImg.width; x+=xStep) {
  //    for (int y=0; y<=theImg.height; y+=yStep) {

  //if x is too close to edge
  int sdw = cvFrameWidth; //((theImg.width - x) < cvFrameWidth) ? (theImg.width - x) : cvFrameWidth;
  int sdh = cvFrameHeight; //((theImg.height - y) < cvFrameHeight) ? (theImg.height - y) : cvFrameHeight;

  opencv.allocate(sdw, sdh);      

  for (int thresh = MIN_THRESH; thresh <= MAX_THRESH; thresh += THRESH_STEP) {
    //TODO: set opencv.ROI(cvFrameX, cvFrameY, destWidth, destHeight);

    //opencv.copy(image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
    opencv.copy(theImg, 0, 0, sdw, sdh, 0, 0, sdw, sdh);

    opencv.threshold(thresh); //, 255, OpenCV.THRESH_BINARY & OpenCV.THRESH_OTSU);    // set black & white threshold   

    Blob[] cvblobs = new Blob[MAX_BLOBS];
    cvblobs = opencv.blobs( MIN_BLOB_SIZE, MAX_BLOB_SIZE, MAX_BLOBS, true); //, OpenCV.MAX_VERTICES*4 );


    println("Found: " + cvblobs.length + " blobs at threshold: " + thresh);


    //blobs.add(new PTBlob(cvblobs, x, y, thresh));
    for (int i=0; i<cvblobs.length; i++) {
      blobs.push(new PTBlob(cvblobs[i], 0, 0, thresh));
    }
  }

  //    }
  //  }

  return blobs;
}




PImage createEdgeImage(PImage pimg) {
  pimg.filter(INVERT);
  pimg.filter(BLUR);

  float[][] kernel = { 
    { 
      -1, -1, -1
    }
    , 
    { 
      -1, 9, -1
    }
    , 
    { 
      -1, -1, -1
    }
  };
  pimg.loadPixels();

  PImage edged = createImage(pimg.width, pimg.height, RGB);
  // Loop through every pixel in the image.
  for (int y = 1; y < pimg.height-1; y++) { // Skip top and bottom edges
    for (int x = 1; x < pimg.width-1; x++) { // Skip left and right edges
      float sum = 0; // Kernel sum for this pixel
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          // Calculate the adjacent pixel for this kernel point
          int pos = (y + ky)*pimg.width + (x + kx);
          // Image is grayscale, red/green/blue are identical
          float val = red(pimg.pixels[pos]);
          // Multiply adjacent pixels based on the kernel values
          sum += kernel[ky+1][kx+1] * val;
        }
      }
      // For this pixel in the new image, set the gray value
      // based on the sum from the kernel
      edged.pixels[y*pimg.width + x] = color(sum);
    }
  }
  // State that there are changes to edged.pixels[]
  edged.updatePixels(); 
  return edged;
}

