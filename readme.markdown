# About
This is the source code for a custom drawing machine which was built by the [Mechatronics research group at UCSC](http://danm.ucsc.edu/web/Mechatronics)

The machine is run by a Make Controller which communicates to two stepper motors (x/y axes) and a linear servo motor (z axis - or pen up/down.)

## Overview
Processing is used to do image maniuplation and convert a bitmap image into a series of vector shapes. This information is then sent to Max/MSP over OSC.

A Max/MSP patch recieves OSC messages with image information and translates that data into a series of commands, instructing the motors to move to the correct physical locations.
There is a constant stream of data back and forth between the motors (via the Make Controller) and Max/MSP to ensure all motion is coordinated and timed properly.

# Usage

Instructions for the machine are located in Presentation of the main patch - max/stepper.json

Processing is used for image manipulation. When you first open the Processing sketch, you will be prompted to open the source image you'd like to draw.
After, you will see a control panel with a group of options for controlling the final output for the drawing machine.

![Processing Control Panel](/ProcessingControls.png "Processing Control Panel")

* **MIN_BLOB_SIZE / MAX_BLOB_SIZE** - The smallest/largest "blob" that the image will be broken down into. If there are lots of small dots/circles, increase MIN_SIZE, if you're losing detail decrease MAX_SIZE.
* **GRANULARITY** - A smaller granularity will result in slightly less detail for large images, but will also speed up processing time considerably. This is basically a resampling value: 1.0 = no resizing; 0.5 = resize by half; etc.
* **THRESHOLD_STEP** - the image processor posterizes the image by breaking it down into a certain number of solid colors. This controls how many of these colors to limit the image to.
* **THRESHOLD_RANGE** - You can limit the range of colors used by the image processor. If you have a very dark image, you'll want to lower this value, if the image is very bright, increasing this value should give you more details.

Anytime a value is changed, you must click the **REGENERATE** button. You must also then switch to "normal" viewing mode and then back into the preview viewing mode by clicking the **IMAGE_MODE** button twice.


#Documentation

## Video
Watch a [timelapse][] of the initial build.

##Images
[Drawing Machine Prints on Flickr][flickr link]

[![Drawing Machine Prints on Flickr][flickr image]][flickr link]

  [timelapse]: https://vimeo.com/28810990
  [flickr link]: http://www.flickr.com/photos/jessefulton/sets/72157629021647557
  [flickr image]: http://farm8.staticflickr.com/7172/6758645323_86f0969b66.jpg (Yager)
