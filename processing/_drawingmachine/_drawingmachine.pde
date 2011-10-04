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

int SKETCH_WIDTH = 800;
int SKETCH_HEIGHT = 450;

//This controls the granularity of the points
float SCALE_FACTOR = 2.0;
float SCREEN_SCALE_FACTOR = 1.0;

float ORIGINAL_WIDTH = 0;
float ORIGINAL_HEIGHT = 0;
float MAX_DIM = 0;

float minX, minY, maxX, maxY;

boolean PEN_UP = true;
boolean FINISHED = false;

void setup() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT); 
  background(255);
  frameRate(60);
  oscP5 = new OscP5(this, myListeningPort);
  

  fill(0, 255, 0);
  stroke(255, 0, 0);
  strokeWeight(2);
  
  RG.init(this);
  s = RG.loadShape("GoogleLogoSq.svg");  


  s.scale(SCALE_FACTOR);

  ORIGINAL_HEIGHT = s.getHeight();
  ORIGINAL_WIDTH = s.getWidth();

  
  pathPoints = s.getPointsInPaths();



  float imHeight = s.getOrigHeight();
  float imWidth = s.getOrigWidth();
  MAX_DIM = max(ORIGINAL_HEIGHT, ORIGINAL_WIDTH);
  println("MAX_DIM: " + MAX_DIM);
  println ("\t" + max(imHeight, imWidth));
  RPoint tl = s.getTopLeft();
  RPoint tr = s.getTopRight();
  RPoint br = s.getBottomRight();
  RPoint bl = s.getBottomLeft();
  
  //TODO: figure out mins and maxes and use those to maximize image area
  
  float[] maxes = { s.getHeight(), s.getWidth(), tl.x, tl.y, tr.x, tr.y, br.x, br.y, bl.x, bl.y };
  MAX_DIM = max(maxes);

  //map the min values to 0%, max values to 100%
  minX = min(tl.x, bl.x);
  maxX = max(tr.x, br.x);
  minY = min(tl.y, tr.y);
  maxY = min(bl.y, br.y);

  float calcHeight = maxY-minY;
  float calcWidth = maxX-minX;

  MAX_DIM = max((maxX-minX), (maxY-minY));
  
  /*
  println("\t corners: " + tl.x + ", " + tl.y + "; "
      + tr.x + ", " + tr.y + "; "
      + br.x + ", " + br.y + "; "
      + bl.x + ", " + bl.y);
  */
  
  
  origAspectRatio = calcWidth / calcHeight; //s.getOrigWidth() / s.getOrigHeight();
  float xScale = SKETCH_WIDTH / imWidth;
  float yScale = SKETCH_HEIGHT / imHeight;
  
  
  println("ASPECT: " + origAspectRatio);
  println(xScale);
  println(yScale);
  //TODO, choose right scale (min/max)
  SCREEN_SCALE_FACTOR = ((xScale < 1 || yScale < 1) ? min(xScale, yScale) : max(xScale, yScale));
  println("SCREEN SCALE: " + SCREEN_SCALE_FACTOR);
  



}


void draw() {
//  doNext();
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
