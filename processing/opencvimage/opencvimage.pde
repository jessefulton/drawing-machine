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








Vector MYBLOBS;

String image_filename = "yager.jpg";
PImage img;
PImage edgeImg;
OpenCV opencv;

int cvFrameSize = 100;
int cvFrameX = 0;
int cvFrameY = 0;


void setup() {
  frameRate(60);

  img = loadImage(image_filename); // Load the original image
  img.resize(400, 0);
  
  size(img.width*3, img.height);
  background(255);
  
  
  
  opencv = new OpenCV(this);
  oscP5 = new OscP5(this, myListeningPort);

  PImage tempImg = loadImage(image_filename);
  tempImg.resize(400,0);
  edgeImg = createEdgeImage(tempImg);

  MAX_DIM = max(img.height, img.width);
  
  
  //print images to screen
  image(img, (width/3.0), 0);
  image(edgeImg, 2*(width/3.0), 0);
  
  println(edgeImg.width);
  println(edgeImg.height);


  MYBLOBS = imageToBlobs(edgeImg);
  
}


void draw() {

  if (MYBLOBS.size() == 0) { exit(); return; }
  else {
//  while (MYBLOBS.size() > 0) {
    MyBlobset mb = (MyBlobset)MYBLOBS.remove(0);
    Blob b = mb.blob;
    int x = mb.xOffset;
    int y = mb.yOffset;

          //TODO: see if two or more lines in blob are along bounding box rectangle
          //Rectangle bounding_box = blobs[blob_num].rectangle;
          
          
          noFill();
          stroke(0,128,0);
          //this.rect( bounding_box.x, bounding_box.y, bounding_box.width, bounding_box.height);
          
          stroke(0); //mb.thresh);
          //fill(0, 255, 0);
          noFill();
        
          beginShape();
          for( int j=0; j<b.points.length; j++ ) {
              vertex( b.points[j].x + x, b.points[j].y + y);
          }
          endShape(CLOSE);
          
  }
  
}





void penUp() { 
    Object[] args = {"up"};
    oscP5.send(new OscMessage("pen", args), myNetAddressList);
    PEN_UP = true;
    println("pen up!");
}
void penDown() { 
    Object[] args = {"down"};
    oscP5.send(new OscMessage("pen", args), myNetAddressList);
    PEN_UP = false; 
    println("pen down!");
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




private void pointToScreen(float x, float y) {
    println(x + ", " + y);

  int screen_x = int(x * width); //* SCREEN_SCALE_FACTOR * origAspectRatio);
  int screen_y = int(y * height);// * SCREEN_SCALE_FACTOR);
  
  float mlt = (origAspectRatio > 1) ? width : height;
  screen_x = int(x * mlt);
  screen_y = int(y * mlt);
  

    stroke(0, 255, 0);
    if(x>1 || y>1) { 
      stroke(255,0,0); 
      screen_x = (x>1) ? int(mlt) : screen_x;
      screen_y = (y>1) ? int(mlt) : screen_y;
    }

    point(screen_x, screen_y);
  

//    point((SCREEN_SCALE_FACTOR * x), (SCREEN_SCALE_FACTOR * y));
    
    //curPoint.normalize();

    //stroke(0,0, 255);
    //ellipse((SKETCH_WIDTH * curPoint.x), (SKETCH_HEIGHT * curPoint.y), 10, 10);
    //println(points[count].x + " " +  points[count].y);

    //ellipse(curPoint.x, curPoint.y, 10, 10);

}


private void sendNextPoint() {
    
    try {
      RPoint[] curShape = pathPoints[shapeIndex];
      RPoint curPoint = curShape[pointIndex];
      float theX = (curPoint.x - minX) / MAX_DIM;
      float theY = (curPoint.y - minY) / MAX_DIM;

      Object[] oscArgs = new Object[2];
      
      oscArgs[0] = theX;
      oscArgs[1] = theY;
      if (theX > 1 || theY > 1) {
        println("Message out of range: {x: " + theX + "; y: " + theY + "; maxDim: " + MAX_DIM + "}");
      }
      oscP5.send(new OscMessage("location", oscArgs), myNetAddressList);
      //pointToScreen((curPoint.x / ORIGINAL_WIDTH), (curPoint.y / ORIGINAL_HEIGHT));
      pointToScreen(theX, theY);
    }
    catch(Exception e) {
      println(e.getMessage());
      FINISHED = true;
    }
    

    
    
}


private void doNext() {
    if (FINISHED) {
      return;
    }

    RPoint[] curShape = pathPoints[shapeIndex];
    //RPoint curPoint = curShape[pointIndex];
    
    if (shapeIndex == 0 && pointIndex == 0) {
      sendNextPoint();
      pointIndex++;
    }
    //we have finished the shape and the pen is still down, raise pen
    else if (pointIndex >= curShape.length && !PEN_UP) {
      penUp();
    }
    //we have finished the shape and the pen up, move to beginning of next shape
    else if (pointIndex >= curShape.length && PEN_UP) {
      pointIndex = 0;
      shapeIndex++;
      sendNextPoint();
    }
    //we have drawn the last shape
    else if (shapeIndex >= pathPoints.length) {
      FINISHED = true;
      penUp();
    }
    //we are at the first point in the shape and pen is up, lower pen
    else if (pointIndex == 0 && PEN_UP) {
      penDown();
    }
    //else, move to next point 
    else {
      sendNextPoint();
      pointIndex++;
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












java.util.Vector imageToBlobs(PImage theImg) {
  java.util.Vector blobs = new java.util.Vector();


  int cvFrameWidth = 50;
  int xStep = cvFrameWidth - (cvFrameWidth/4);
  int cvFrameHeight = 50;
  int yStep = cvFrameHeight - (cvFrameHeight/4);
  int MAX_BLOB_SIZE = cvFrameWidth*cvFrameHeight/2;
  int MIN_BLOB_SIZE = 10;
  int MAX_BLOBS = 200;
  
  int MIN_THRESH = 100;
  int MAX_THRESH = 200;
  int THRESH_STEP = 10;


  for (int x=0; x<=theImg.width; x+=xStep) {
    for (int y=0; y<=theImg.height; y+=yStep) {

      //if x is too close to edge
      int sdw = ((theImg.width - x) < cvFrameWidth) ? (theImg.width - x) : cvFrameWidth;
      int sdh = ((theImg.height - y) < cvFrameHeight) ? (theImg.height - y) : cvFrameHeight;

      opencv.allocate(sdw, sdh);      

      for (int thresh = MIN_THRESH; thresh <= MAX_THRESH; thresh += THRESH_STEP) {
        //TODO: set opencv.ROI(cvFrameX, cvFrameY, destWidth, destHeight);
  
        //opencv.copy(image, sx, sy, swidth, sheight, dx, dy, dwidth, dheight);
        opencv.copy(theImg, x, y, sdw, sdh, 0, 0, sdw, sdh);

        opencv.threshold(thresh); //, 255, OpenCV.THRESH_BINARY & OpenCV.THRESH_OTSU);    // set black & white threshold   
        Blob[] cvblobs = opencv.blobs( MIN_BLOB_SIZE, MAX_BLOB_SIZE, MAX_BLOBS, true); //, OpenCV.MAX_VERTICES*4 );

        //blobs.add(new MyBlobset(cvblobs, x, y));
        for (int i=0; i<cvblobs.length; i++) {
          blobs.add(new MyBlobset(cvblobs[i], x, y, thresh));
        }
      }
      
    }
  }
  

  
  return blobs;
}


class MyBlobset {
  Blob blob;
  int xOffset;
  int yOffset;
  int thresh;
  
  MyBlobset(Blob b, int xOffset, int yOffset, int thresh) {
    this.blob = b;
    this.xOffset = xOffset;
    this.yOffset = yOffset;
    this.thresh = thresh;
  }
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
