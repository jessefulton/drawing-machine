

void initControls() {
    //TODO: http://www.sojamo.de/libraries/controlP5/examples/ControlP5window/ControlP5window.pde
  controlP5 = new ControlP5(this);
  //controlP5.setAutoDraw(false);
  controlWindow = controlP5.addControlWindow("controlP5window",0,500,480,75);
  controlWindow.hideCoordinates();
  
  controlWindow.setBackground(color(0));
  
  
  Controller textLabel = controlP5.addTextlabel("INSTRUCTIONS", "Press 's' to show this control window, 'h' to hide it", 10, 10);
  textLabel.setWindow(controlWindow);
  Controller granularitySlider = controlP5.addSlider("GRANULARITY", 0.0, 1.0, GRANULARITY, 80,(40),70,14);
  granularitySlider.setWindow(controlWindow);
  granularitySlider.setLabel("");
  Controller granularityLabel = controlP5.addTextlabel("GRANULARITY_LABEL", "GRANULARITY", 80, 60);
  granularityLabel.setWindow(controlWindow);

  Controller thresholdStepNumberbox = controlP5.addNumberbox("THRESHOLD_STEP", THRESH_STEP, 160,(40),70,14);
  thresholdStepNumberbox.setWindow(controlWindow);
  Controller thresholdRange = controlP5.addRange("THRESHOLD_RANGE", 10.0, 250.0, float(MIN_THRESH), float(MAX_THRESH), 240,(40),70,14);
  thresholdRange.setWindow(controlWindow);
  thresholdRange.setLabel("");
  Controller threshLabel = controlP5.addTextlabel("THRESH_RANGE_LABEL", "THRESHOLD_RANGE", 240, 60);
  threshLabel.setWindow(controlWindow);
  
  Controller regenerateButton = controlP5.addButton("REGENERATE",1.0,320,(40),70,14);
  regenerateButton.setWindow(controlWindow);
  Controller imageModeToggle = controlP5.addToggle("IMAGE_MODE", true, 10, (40), 40, 14);
  imageModeToggle.setWindow(controlWindow);
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
    MIN_THRESH = int(r.lowValue());
    //r.setHighValue(float(MAX_THRESH));
    //r.setLowValue(float(MIN_THRESH));
  }
  else if (theEvent.controller().name().equals("GRANULARITY")) {
    Slider r = (Slider) theEvent.controller();
    println("granularity: " + r.value());
    GRANULARITY = r.value();
  }
  
}





