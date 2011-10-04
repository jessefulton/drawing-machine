import hypermedia.video.*;


String image_filename = "dots.jpg";
PImage img;
PImage edgeImg;
OpenCV opencv;

int cvFrameSize = 100;
int cvFrameX = 0;
int cvFrameY = 0;


void setup() {
  
  float[][] kernel = { { -1, -1, -1 },
                       { -1,  9, -1 },
                       { -1, -1, -1 } };
    
  img = loadImage(image_filename); // Load the original image
  img.loadPixels();
  
  edgeImg = createImage(img.width, img.height, RGB);
  // Loop through every pixel in the image.
  for (int y = 1; y < img.height-1; y++) { // Skip top and bottom edges
    for (int x = 1; x < img.width-1; x++) { // Skip left and right edges
      float sum = 0; // Kernel sum for this pixel
      for (int ky = -1; ky <= 1; ky++) {
        for (int kx = -1; kx <= 1; kx++) {
          // Calculate the adjacent pixel for this kernel point
          int pos = (y + ky)*img.width + (x + kx);
          // Image is grayscale, red/green/blue are identical
          float val = red(img.pixels[pos]);
          // Multiply adjacent pixels based on the kernel values
          sum += kernel[ky+1][kx+1] * val;
        }
      }
      // For this pixel in the new image, set the gray value
      // based on the sum from the kernel
      edgeImg.pixels[y*img.width + x] = color(sum);
    }
  }
  // State that there are changes to edgeImg.pixels[]
  edgeImg.updatePixels();
  
  
  
  //img.resize(600, 0);
  //size(img.width, img.height);
  size(img.width*2, img.height);

  opencv = new OpenCV(this);
//  opencv.allocate(img.width,img.height);
//  opencv.copy(edgeImg);
  //opencv.loadImage("dots.jpg", img.width, img.height);
 
  image(img, 0, 0);
  image(edgeImg, width/2.0, 0);
}


void draw() {

    delay(1000);
  
    opencv.allocate(cvFrameSize,cvFrameSize);
    
    int  destWidth = (cvFrameX+cvFrameSize) > edgeImg.width ? (edgeImg.width - cvFrameX) : cvFrameSize;
    int  destHeight = (cvFrameY+cvFrameSize) > edgeImg.height ? (edgeImg.height - cvFrameY) : cvFrameSize;
    

    int MAX_BLOB_SIZE = cvFrameSize*cvFrameSize;
    //MAX_BLOB_SIZE = 100;
    // find blobs
    
    for (int thresh = 50; thresh <= 200; thresh += 10) {
        //TODO: set opencv.ROI(cvFrameX, cvFrameY, destWidth, destHeight);
    
        opencv.copy(edgeImg, cvFrameX, cvFrameY, cvFrameSize, cvFrameSize, 0, 0, destWidth, destHeight);

        opencv.threshold(thresh, 255, OpenCV.THRESH_BINARY & OpenCV.THRESH_OTSU);    // set black & white threshold   
        Blob[] blobs = opencv.blobs( 5, MAX_BLOB_SIZE, 200, true); //, OpenCV.MAX_VERTICES*4 );
    
        println(blobs.length);
    
        stroke(0, 0, 255);
        //fill(0, 255, 0);
        noFill();
        // draw blob results
        for( int i=0; i<blobs.length; i++ ) {
            beginShape();
            for( int j=0; j<blobs[i].points.length; j++ ) {
                vertex( blobs[i].points[j].x + cvFrameX, blobs[i].points[j].y + cvFrameY);
            }
            endShape(CLOSE);
        }
    }
  
  cvFrameX += cvFrameSize;
  if (cvFrameX > edgeImg.width) {
    cvFrameY += cvFrameSize;
    cvFrameX = 0;
  }
  
  if (cvFrameY > edgeImg.height) {
    exit();
  }
}
