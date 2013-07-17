# About
This is the source code for a custom drawing machine which was built by the [Mechatronics research group at UCSC](http://danm.ucsc.edu/web/Mechatronics)

The machine is run by a Make Controller which communicates to two stepper motors (x/y axes) and a linear servo motor (z axis - or pen up/down.)

### Processing
Processing is used to do image maniuplation and convert a bitmap image into a series of vector shapes. This information is then sent to Max/MSP over OSC.

### Max/MSP
A Max/MSP patch recieves OSC messages with image information and translates that data into a series of commands, instructing the motors to move to the correct physical locations.
There is a constant stream of data back and forth between the motors (via the Make Controller) and Max/MSP to ensure all motion is coordinated and timed properly.

## Video
Watch a [timelapse][] of the initial build.

##Images
[Drawing Machine Prints on Flickr][flickr link]

[![Drawing Machine Prints on Flickr][flickr image]][flickr link]

  [timelapse]: https://vimeo.com/28810990
  [flickr link]: http://www.flickr.com/photos/jessefulton/sets/72157629021647557
  [flickr image]: http://farm8.staticflickr.com/7172/6758645323_86f0969b66.jpg (Yager)