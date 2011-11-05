import hypermedia.video.*;
import geomerative.*;
import oscP5.*;
import netP5.*;


OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
/* listeningPort is the port the server is listening for incoming messages */
int myListeningPort = 32000;
/* the broadcast port is the port the clients should listen for incoming messages from the server*/
int myBroadcastPort = 12000;

String myConnectPattern = "/server/connect";
String myDisconnectPattern = "/server/disconnect";
String nextPointPattern = "/point/next";


static boolean SEND_OSC = true;
static boolean PRINT_TO_SCREEN = true;

CommandList COMMANDS;
int TOTAL_COMMANDS=0;

RShape s;
RShape polyshp;
RPoint[][] pathPoints;

int path = 0;
int pathPoint = 0;

int shapeIndex = 0;
int pointIndex = 0;


float origAspectRatio = 1.0;


//This controls the granularity of the points
float SCALE_FACTOR = 2.0;
float SCREEN_SCALE_FACTOR = 1.0;

float ORIGINAL_WIDTH = 0;
float ORIGINAL_HEIGHT = 0;
float MAX_DIM = 0;

float minX, minY, maxX, maxY;

boolean PEN_UP = true;
boolean FINISHED = false;





PTBlob CURRENT_BLOBSET;
int BLOB_POINT_INDEX = 0;


PTBlobs MYBLOBS;

String image_filename = "paper.jpg";
PImage img;
PImage edgeImg;
OpenCV opencv;

int cvFrameSize = 100;
int cvFrameX = 0;
int cvFrameY = 0;


void setup() {
  frameRate(120);

  img = loadImage(image_filename); // Load the original image
  img.resize(0, 800);
  
  size(img.width*2, img.height);
  background(255);
  
  noFill();
  stroke(0, 90);
  
  
  opencv = new OpenCV(this);
  oscP5 = new OscP5(this, myListeningPort);

  PImage tempImg = loadImage(image_filename);
  tempImg.resize(0,800);
  edgeImg = createEdgeImage(tempImg);

  MAX_DIM = max(img.height, img.width);
  
  
  //print images to screen
  image(img, (width/2.0), 0);
  //image(edgeImg, 2*(width/3.0), 0);
  


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


void draw() {
  doNext();
}

void screenCommand(OscCommand cmd) {
  if (cmd instanceof MoveCommand) {
    MoveCommand mv = (MoveCommand) cmd;
    int newX = int(MAX_DIM * mv.x);
    int newY = int(MAX_DIM * mv.y);
    //println(mv.x + " ==> " + newX + "; " + mv.y + " ==> " + newY);
    //point(newX, newY);
    vertex(newX, newY);
  }
  
  else if (cmd instanceof PenCommand) {
    String dir = (String)cmd.getParams()[0];
    if (dir.equals(PenCommand.UP)) {
      //println("ENDING SHAPE!");
      endShape();
    }
    else {
      //println("BEGINNING SHAPE!");
      beginShape();
    }
      
  }
  
}

void doNext() {
  OscCommand cmd = getNextCommand();
  if (cmd == null) { 
    println("FINISHED");
    return; 
  }
  else {
    if (SEND_OSC) {
      sendCommand(cmd);
    }
    if (PRINT_TO_SCREEN) {
      screenCommand(cmd);
    }
    int remainder = COMMANDS.size();
    float pctComplete =  float(TOTAL_COMMANDS - remainder) / float(TOTAL_COMMANDS) * 100;
    int minutes = millis()/(1000*60);
    int seconds = millis()/(1000) - 60*minutes;
    println ("Step " + (TOTAL_COMMANDS - remainder) + " of " + TOTAL_COMMANDS + "; " + pctComplete + "% complete... (runtime: " + minutes + "m " + seconds + "s)");
  }
}

OscCommand getNextCommand() {
  if(COMMANDS.isEmpty()) {
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



void oscEvent(OscMessage theOscMessage) {
  /* check if the address pattern fits any of our patterns */
  if (theOscMessage.addrPattern().equals(myConnectPattern)) {
    connect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(myDisconnectPattern)) {
    disconnect(theOscMessage.netAddress().address());
  }
  else if (theOscMessage.addrPattern().equals(nextPointPattern)) {
    doNext();
  }
  /**
   * if pattern matching was not successful, then broadcast the incoming
   * message to all addresses in the netAddresList. 
   */
  else {
    oscP5.send(theOscMessage, myNetAddressList);
  }
}




 private void connect(String theIPaddress) {
     if (!myNetAddressList.contains(theIPaddress, myBroadcastPort)) {
       myNetAddressList.add(new NetAddress(theIPaddress, myBroadcastPort));
       println("### adding "+theIPaddress+" to the list.");
     } else {
       println("### "+theIPaddress+" is already connected.");
     }
     println("### currently there are "+myNetAddressList.list().size()+" remote locations connected.");
 }



private void disconnect(String theIPaddress) {
if (myNetAddressList.contains(theIPaddress, myBroadcastPort)) {
		myNetAddressList.remove(theIPaddress, myBroadcastPort);
       println("### removing "+theIPaddress+" from the list.");
     } else {
       println("### "+theIPaddress+" is not connected.");
     }
       println("### currently there are "+myNetAddressList.list().size());
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
  
  int MIN_THRESH = 30; //50;
  int MAX_THRESH = 200;
  int THRESH_STEP = 10;

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
  
  float[][] kernel = { { -1, -1, -1 },
                       { -1,  9, -1 },
                       { -1, -1, -1 } };
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
