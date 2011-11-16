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

float GRANULARITY = 0.5;

float origAspectRatio = 1.0;


//This controls the granularity of the points
float SCALE_FACTOR = 2.0;
float SCREEN_SCALE_FACTOR = 1.0;

float ORIGINAL_WIDTH = 0;
float ORIGINAL_HEIGHT = 0;
float MAX_DIM = 0;

float minX, minY, maxX, maxY;

int MIN_THRESH = 40; //50;
int MAX_THRESH = 200;
int THRESH_STEP = 20;


boolean PEN_UP = true;
boolean FINISHED = false;

ControlP5 controlP5;



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



  size(img.width, img.height);
  background(0);


  //TODO: http://www.sojamo.de/libraries/controlP5/examples/ControlP5window/ControlP5window.pde
  controlP5 = new ControlP5(this);

  controlP5.addSlider("GRANULARITY", 0.0, 1.0, GRANULARITY, 80,(height-40),70,14);
  controlP5.addNumberbox("THRESHOLD_STEP", THRESH_STEP, 160,(height-40),70,14);
  controlP5.addRange("THRESHOLD_RANGE", 10.0, 250.0, float(MIN_THRESH), float(MAX_THRESH), 240,(height-40),70,14);
  controlP5.addButton("REGENERATE",1.0,400,(height-40),70,14);
  controlP5.addToggle("IMAGE_MODE", true, 10, (height - 40), 40, 14);

  noFill();
  stroke(0, 90);


  //print images to screen
  image(img, 0, 0);
  //image(edgeImg, 2*(width/3.0), 0);

  generate();

}


void keyPressed() {
  if (key == 'h') {
    controlP5.hide();
  } else if (key == 's') {
    controlP5.show();
  }
}



//TODO: I think we're currently only doing black and white - see what happens when doing each RGB channel individually
void generate() {
  PImage tempImg = loadImage(image_filename);
  tempImg.resize(int(img.width*GRANULARITY), int(img.height*GRANULARITY));
  edgeImg = createEdgeImage(tempImg);

  MAX_DIM = max(edgeImg.height, edgeImg.width);
  
  MYBLOBS = imageToBlobs(edgeImg);

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
  image(img, 0, 0);
}

void showBlobs() {
    background(255);
    stroke(0, 127);
    noFill();
    Iterator iter = MYBLOBS.iterator();
    CoordinateMapper mapper = new CoordinateMapper(MAX_DIM);
    int screenmax = max(height, width);
    while (iter.hasNext()) {
      println("drawing blob");
      PTBlob b = (PTBlob)iter.next();
      beginShape();
      for (int i=0; i<b.points.length; i++) {
        float theX = mapper.map(b.points[i].x + b.xOffset) * screenmax;
        float theY = mapper.map(b.points[i].y + b.yOffset) * screenmax;
        vertex(theX, theY);
      }
      endShape();
    }  
}

void IMAGE_MODE(boolean flag) {
  if (flag == true) {
    showImage();
  }
  else {
    showBlobs();
  }
}

void REGENERATE() {
  println("clicked regenerate");
  generate();
}

void THRESHOLD_STEP(int step) {
  println("step: " + step);
  THRESH_STEP = step;
}

void controlEvent(ControlEvent theEvent) {
  if(theEvent.controller().name().equals("THRESHOLD_RANGE")) {
    Range r = (Range) theEvent.controller();
    println("thresh: " + r.highValue() + "; " + r.lowValue());
    MAX_THRESH = int(r.highValue());
    THRESH_STEP = int(r.lowValue());
    //r.setHighValue(float(MAX_THRESH));
    //r.setLowValue(float(MIN_THRESH));
  }
  else if (theEvent.controller().name().equals("GRANULARITY")) {
    Slider r = (Slider) theEvent.controller();
    println("granularity: " + r.value());
    GRANULARITY = r.value();
  }
  
}


void draw() { }


void doNext() {
  OscCommand cmd = getNextCommand();
  if (cmd == null) { 
    println("FINISHED");
    return;
  }
  else {
    sendCommand(cmd);
    int remainder = COMMANDS.size();
    float pctComplete =  float(TOTAL_COMMANDS - remainder) / float(TOTAL_COMMANDS) * 100;
    int minutes = millis()/(1000*60);
    int seconds = millis()/(1000) - 60*minutes;
    println ("Step " + (TOTAL_COMMANDS - remainder) + " of " + TOTAL_COMMANDS + "; " + pctComplete + "% complete... (runtime: " + minutes + "m " + seconds + "s)");
  }
}

OscCommand getNextCommand() {
  if (COMMANDS.isEmpty()) {
    return null;
  }
  else {
    return COMMANDS.removeNext();
  }
}

void sendCommand(OscCommand cmd) {
  if (cmd instanceof MoveCommand) {
    try {
      //println("SENDING: " + cmd.x + ", " + cmd.y);
    }
    catch(Exception e) {
      println(e);
    }
  }
  oscP5.send(new OscMessage(cmd.getPattern(), cmd.getParams()), myNetAddressList);
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

