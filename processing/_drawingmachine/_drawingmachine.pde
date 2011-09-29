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

int SKETCH_WIDTH = 800;
int SKETCH_HEIGHT = 800;
float SCALE_FACTOR = 1.0;
float SCREEN_SCALE_FACTOR = 1.0;

float ORIGINAL_WIDTH = 0;
float ORIGINAL_HEIGHT = 0;

int STEP_DELAY = 400;
int PEN_DELAY = 5000;

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
  s = RG.loadShape("GoogleLogo.svg");  

  ORIGINAL_HEIGHT = s.getOrigHeight();
  ORIGINAL_WIDTH = s.getOrigWidth();

  ORIGINAL_HEIGHT = 1000;
  ORIGINAL_WIDTH = 1000;
  println(ORIGINAL_HEIGHT);
  println(ORIGINAL_WIDTH);
  s.scale(SCALE_FACTOR);
  pathPoints = s.getPointsInPaths();


  float imHeight = s.getOrigHeight();
  float imWidth = s.getOrigWidth();
  float xScale = SKETCH_WIDTH / imWidth;
  float yScale = SKETCH_HEIGHT / imHeight;
  //TODO, choose right scale (min/max)
  SCREEN_SCALE_FACTOR = 1 - ((xScale < 1 || yScale < 1) ? min(xScale, yScale) : max(xScale, yScale));
  println("SCREEN SCALE: " + SCREEN_SCALE_FACTOR);
  



}
void draw() {

}

void penUp() { 
    Object[] args = {"up"};
    oscP5.send(new OscMessage("pen", args), myNetAddressList);
    PEN_UP = true;
    println("pen up!");
    delay(PEN_DELAY);
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



/*

private void pointToScreen(Object pts) {
    
  
  //  stroke(0,0,255);
    point(int((curPoint.x / ORIGINAL_WIDTH) * 400), int((curPoint.y / ORIGINAL_HEIGHT) * 400));
  
    stroke(0, 255, 0);
    point((SCREEN_SCALE_FACTOR * curPoint.x), (SCREEN_SCALE_FACTOR * curPoint.y));
    
    //curPoint.normalize();

    //stroke(0,0, 255);
    //ellipse((SKETCH_WIDTH * curPoint.x), (SKETCH_HEIGHT * curPoint.y), 10, 10);
    //println(points[count].x + " " +  points[count].y);

    //ellipse(curPoint.x, curPoint.y, 10, 10);

}
*/

private void sendNextPoint() {
    RPoint[] curShape = pathPoints[shapeIndex];
    RPoint curPoint = curShape[pointIndex];
  
    Object[] oscArgs = new Object[2];
    oscArgs[0] = curPoint.x / ORIGINAL_WIDTH;
    oscArgs[1] = curPoint.y / ORIGINAL_HEIGHT;
    
    oscP5.send(new OscMessage("location", oscArgs), myNetAddressList);
    
    println("Sending message " + oscArgs[0] + ", " + oscArgs[1]);
}


private void doNext() {
    if (FINISHED) {
      return;
    }
    
    RPoint[] curShape = pathPoints[shapeIndex];
    RPoint curPoint = curShape[pointIndex];
    
    //we have finished the shape and the pen is still down, raise pen
    if (pointIndex >= curShape.length && !PEN_UP) {
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
      pointIndex++;
      sendNextPoint();
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
