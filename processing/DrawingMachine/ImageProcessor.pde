public class ImageProcessorOptions {
  int maxBlobs;
  int maxBlobSize;
  int minBlobSize;
  int minThreshold;
  int maxThreshold;
  int thresholdStep;
  int steps;
  
  public ImageProcessorOptions(int mb, int mnbs, int mxbs, int mnth, int mxth, int thst) {
    this.maxBlobs = mb;
    this.maxBlobSize = mxbs;
    this.minBlobSize = mnbs;
    this.minThreshold = mnth;
    this.maxThreshold = mxth;
    this.thresholdStep = thst;
  }
  
  public ImageProcessorOptions(int mb, int mnbs, int mxbs, int st) {
    this.maxBlobs = mb;
    this.maxBlobSize = mxbs;
    this.minBlobSize = mnbs;
    this.steps = st;
  }
}

public interface ImageProcessor {
  public PTBlobs process(PImage pimg, ImageProcessorOptions options);
}

public class EdgeProcessor {
  public EdgeProcessor() {}
  
  public PTBlobs process(PImage pimg, ImageProcessorOptions options) {
    return this.imageToBlobs(this.createEdgeImage(pimg), options);
  }
  
  private PTBlobs imageToBlobs(PImage theImg, ImageProcessorOptions options) {
    PTBlobs blobs = new PTBlobs();
  
    int cvFrameWidth = theImg.width;
    int cvFrameHeight = theImg.height;
  
    opencv.allocate(cvFrameWidth, cvFrameHeight);      
  
    for (int thresh = options.minThreshold; thresh <= options.maxThreshold; thresh += options.thresholdStep) {
      opencv.copy(theImg, 0, 0, cvFrameWidth, cvFrameHeight, 0, 0, cvFrameWidth, cvFrameHeight);
      opencv.threshold(thresh); // set black & white threshold   
  
      Blob[] cvblobs = new Blob[options.maxBlobs];
      cvblobs = opencv.blobs( options.minBlobSize, options.maxBlobSize, options.maxBlobs, true); //, OpenCV.MAX_VERTICES*4 );
      for (int i=0; i<cvblobs.length; i++) {
        blobs.push(new PTBlob(cvblobs[i], 0, 0, thresh));
      }
    }
  
    return blobs;
  }
  
  
  
  
  private PImage createEdgeImage(PImage im) {
    float[][] kernel = { { -1, -1, -1 },
                         { -1,  9, -1 },
                         { -1, -1, -1 }};

    PImage pimg = this.copyImage(im);
    pimg.filter(INVERT);
    pimg.filter(BLUR);
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

  private PImage copyImage(PImage orig) {
    PImage cp = createImage(orig.width, orig.height, ARGB);
    cp.loadPixels();
    cp.copy(orig, 0, 0, orig.width, orig.height, 0, 0, orig.width, orig.height);
    cp.updatePixels();
    return cp;
  }
  
}



public class PosterizeProcessor {
  public PosterizeProcessor() {}
 
 
 
   public Vector process(PImage pimg, int mb, int mnbs, int mxbs, int st) {
    Vector blobs = new Vector();
    PImage tempImg = copyImage(pimg);
    tempImg.filter(BLUR);
    PImage redChannel = createImage(tempImg.width, tempImg.height, RGB);
    PImage greenChannel = createImage(tempImg.width, tempImg.height, RGB);
    PImage blueChannel = createImage(tempImg.width, tempImg.height, RGB);
    redChannel.loadPixels();
    greenChannel.loadPixels();
    blueChannel.loadPixels();
    for (int i=0; i< tempImg.pixels.length; i++) {
      redChannel.pixels[i] = color(red(tempImg.pixels[i]));
      greenChannel.pixels[i] = color(green(tempImg.pixels[i]));
      blueChannel.pixels[i] = color(blue(tempImg.pixels[i]));
    }
    //redChannel.filter(GRAY);
    redChannel.filter(POSTERIZE, st);
    redChannel.updatePixels();
    //greenChannel.filter(GRAY);
    greenChannel.filter(POSTERIZE, st);
    greenChannel.updatePixels();
    //blueChannel.filter(GRAY);
    blueChannel.filter(POSTERIZE, st);
    blueChannel.updatePixels();
    
  
    PImage[] channels = {redChannel, greenChannel, blueChannel};
  
    for(int i=0; i< channels.length; i++) {
      PImage chann = channels[i];
      float THRESH_JUMP = 255 / st;
  
      for(float f = 0; f< 255; f+= THRESH_JUMP) {
        int thresh = ceil(f)+1;
        opencv.allocate(chann.width, chann.height);
        opencv.copy(chann, 0, 0, chann.width, chann.height, 0, 0, chann.width, chann.height);
        opencv.threshold(thresh);
        println("blobs for  thresh " + thresh);
        Blob[] cvblobs = opencv.blobs( mnbs, mxbs, mb, true, OpenCV.MAX_VERTICES*4 );
        println("fubar" + cvblobs.length);
        for (int j=0; j< cvblobs.length; j++) {
          println("WTF");
          blobs.add(new PTBlob(cvblobs[j], 0, 0, thresh));
        }


      }
    }

    println("returning " + blobs.size() + " blobs");
    return blobs;
  
    
  }
  
 
  
  
  private PImage copyImage(PImage orig) {
    PImage cp = createImage(orig.width, orig.height, ARGB);
    cp.loadPixels();
    cp.copy(orig, 0, 0, orig.width, orig.height, 0, 0, orig.width, orig.height);
    cp.updatePixels();
    return cp;
  }
}







public class GreyscalePosterizeProcessor {
  public GreyscalePosterizeProcessor() {}
 
  public Vector process(PImage pimg, int mb, int mnbs, int mxbs, int st) {
    Vector blobs = new Vector();
    PImage tempImg = copyImage(pimg);
    tempImg.loadPixels();
    tempImg.filter(BLUR);
    tempImg.filter(GRAY);
    tempImg.filter(POSTERIZE, st);
    tempImg.updatePixels();
    tempImg.loadPixels();    
  
    PImage[] channels = {tempImg};
  
  
    for(int i=0; i< channels.length; i++) {
      PImage chann = channels[i];
      float THRESH_JUMP = 255 / st;
  
      for(float f = 0; f< 255; f+= THRESH_JUMP) {
        int thresh = ceil(f)+1;
        opencv.allocate(chann.width, chann.height);
        opencv.copy(chann, 0, 0, chann.width, chann.height, 0, 0, chann.width, chann.height);
        opencv.threshold(thresh);
        println("blobs for  thresh " + thresh);
        Blob[] cvblobs = opencv.blobs( mnbs, mxbs, mb, true, OpenCV.MAX_VERTICES*4 );
        println("fubar" + cvblobs.length);
        for (int j=0; j< cvblobs.length; j++) {
          println("WTF");
          blobs.add(new PTBlob(cvblobs[j], 0, 0, thresh));
        }


      }
    }

    println("returning " + blobs.size() + " blobs");
    return blobs;
  
    
  }
  
  
  
  private PImage copyImage(PImage orig) {
    PImage cp = createImage(orig.width, orig.height, ARGB);
    cp.loadPixels();
    cp.copy(orig, 0, 0, orig.width, orig.height, 0, 0, orig.width, orig.height);
    cp.updatePixels();
    return cp;
  }
  
  
  
}
