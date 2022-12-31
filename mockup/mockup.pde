int bankSize = 0x4000; // size of one VIC bank

int widthInChars = 32; // the width (in chars) of one screen, 32 is optimum?

// 32*8 = 256 * 200 image, half silhouette = 128*200

int nrCharLines = 256 / widthInChars; // the max. number of different character lines (= max. nr of screens)

int totalScreensSize = nrCharLines * 0x400;
int nrCharSets = (bankSize - totalScreensSize) / 0x800;

//int nrBanks = 2;
//int nrLines = nrCharLines * nrCharSets * nrBanks;
int nrLines=48;

int maxLineLength = (widthInChars - 1) * 8; //(keep 1 character empty to fill empty positions)

int[] lineLengths = new int[nrLines];

int sineTableLength = 32;

int imageHeight = 32;

// for every line, have a sinetable that rotates it
int[][] sineIndex = new int[nrLines][sineTableLength];

double phaseStep = Math.PI / sineTableLength;

int[] linePhases = new int[200];
int[] colors = new color[200];

int green = 255;

PImage image;

void setup() {

  image = loadImage("tree160x200.png");
  //image = loadImage("bell160x200.png");
   //image = loadImage("snowman160x200.png");

  float scale = 2;
  
  // colors snowman
  //for (int i =0; i < 33; i++) {
  //  colors[i] = color(255,0,0);
  //}
  //for (int i = 33; i < 200; i++) {
  //  colors[i] = color(255,255,255);
  //}
  
  int split = 181;
  
  // colors tree
  for (int i =0; i < split; i++) {
    colors[i] = color(0,255,0);
  }
  for (int i = split; i < 200; i++) {
    colors[i] = color(100,66,33);
  }
  
    
  
  
  
  double step = maxLineLength / nrLines;
  
  print ("Step = ", step);
  
  // make table for each line
  // instead of line length, this will be $d018 value (and maybe $dd00)
  for (int i = 0; i < nrLines; i++) {
    lineLengths[i] = Math.round((float)(i * step)); 
  }
  
  // make a sinetable indexing into the lines
  // TODO: some indexes skipped? room to optimize for quality (or size)?
  
  for (int l = 0; l < nrLines; l++) {
    // each line has it's own sinetable to (half) rotate it
    for (int i = 0; i < sineTableLength; i++) {
      sineIndex[l][i] =(int)(l * sin((float)(i * phaseStep)));
    }
  }
  
  // the image
  for (int i = 0; i < 20; i++) {
    linePhases[i] = i;
  }
  for (int i = 20; i < 50; i++) {
    linePhases[i] = i-20;
  }
  for (int i = 50; i < 100; i++) {
    linePhases[i] = i-50;
  }
  for (int i = 100; i < 180; i++) {
    linePhases[i] = (i-100)/2;
  }
  for (int i = 180; i < 200; i++) {
    linePhases[i] = 4;
  }

  print (nrCharLines, " different character lines max\n");
  print ("Room for ", nrCharSets, " char sets\n");
  //print ("Using ", nrBanks, " banks\n");
  print ("So ", nrLines, " different lines\n");
  print (nrLines * sineTableLength, " bytes needed for sinetables");
  // $0800-$1000: code
  // $1000-$2000: music
  // $2000-$4000: -
  // $4000-$c000: animation
  // $c000-$c800: sinetables
  // $c800-$d000: images
  

  size(320, 200);
  background(255);
  frameRate(50);
  
  image(image,0,0);
  //loadPixels();
  
  for (int y = 0; y < 200; y++) {
    
    int pixelCount = 0;
    
    for (int x =0; x < 160; x++) {
      color c = get(x, y);
      float redValue=red(c);
      if (redValue < 128) {
        pixelCount++;
      }
    }
    linePhases[y] = Math.round(pixelCount / scale) % nrLines;
  }

}

void draw() {

  background(0);

    int animFrame = frameCount % sineTableLength;

    if (animFrame == 0) {
      green = green ^ 128;
    }

    

  for (int y =0; y < linePhases.length; y++) {
    int lineLength= linePhases[y];
    int projectedLineIndex = sineIndex[lineLength][animFrame];
    int projectedLineLength = lineLengths[projectedLineIndex];
    
    int start = 160-(projectedLineLength/2);
    int end = 160+(projectedLineLength/2);
    stroke(colors[y]);
    line (start, y, end, y);
    stroke(0);
    
    //int dither = (y % 2 == 0) ? 1 : 0;
    
    //for (int i=0; i < 3*3; i+=3) {
    
      //if (animFrame > sineTableLength /2 ) {
        //line(start+2, y, start+3, y);
      //}
      //else {
        //line(end-2, y, end-3, y);
      //}
    //}
    
    
  }

}
