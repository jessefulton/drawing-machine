/**
 * Pixelate  
 * by Hernando Barragan. 
 * 
 * Load a QuickTime file and display the video signal 
 * using rectangles as pixels by reading the values stored 
 * in the current video frame pixels array. 
 */


int numPixels;
int blockSize = 1;
PImage lich;
color myMovieColors[];

void setup() {
  noStroke();
  background(0);
  lich = loadImage("dots.jpg");
  numPixels = lich.width * lich.height;
  size(lich.width, lich.height, P2D);
  myMovieColors = new color[numPixels];

}


// Display values from movie
void draw()  {
  for (int j = 0; j < lich.height; j+=blockSize) {
    for (int i = 0; i < lich.width; i+=blockSize) {
      color pix = (lich.get(i,j));
      float greyVal = (red(pix) + green(pix) + blue(pix))/3.0;
      //println(greyVal+1/256);
      color grey = color(greyVal);
      fill(grey);
      rect(i, j, blockSize, blockSize);
      //myMovieColors[j*numPixels + i] = lich.get(i, j);
    }
  }
}


void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      blockSize++;
    } else if (keyCode == DOWN) {
      blockSize = max(1, blockSize-1);
    } 
  }
}
