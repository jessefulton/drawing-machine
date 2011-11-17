
OscP5 oscP5;
NetAddressList myNetAddressList = new NetAddressList();
/* listeningPort is the port the server is listening for incoming messages */
int myListeningPort = 32000;
/* the broadcast port is the port the clients should listen for incoming messages from the server*/
int myBroadcastPort = 12000;

String myConnectPattern = "/server/connect";
String myDisconnectPattern = "/server/disconnect";
String nextPointPattern = "/point/next";


void startServer() {
   oscP5 = new OscP5(this, myListeningPort); 
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
  } 
  else {
    println("### "+theIPaddress+" is already connected.");
  }
  println("### currently there are "+myNetAddressList.list().size()+" remote locations connected.");
}



private void disconnect(String theIPaddress) {
  if (myNetAddressList.contains(theIPaddress, myBroadcastPort)) {
    myNetAddressList.remove(theIPaddress, myBroadcastPort);
    println("### removing "+theIPaddress+" from the list.");
  } 
  else {
    println("### "+theIPaddress+" is not connected.");
  }
  println("### currently there are "+myNetAddressList.list().size());
}







void doNext() {
  OscCommand cmd = getNextCommand();
  if (cmd == null) { 
    println("FINISHED");
    noLoop();
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






