


int bankSize = 0x4000; // size of one VIC bank

int widthInChars = 32; // the width (in chars) of one screen, 32 is optimum?
int nrCharLines = 256 / widthInChars; // the max. number of different character lines (= max. nr of screens)

int totalScreensSize = nrCharLines * 0x400;
int nrCharSets = (bankSize - totalScreensSize) / 0x800;


int nrBanks = 2;
int nrLines = nrCharLines * nrCharSets * nrBanks;

int maxLineLength = (widthInChars - 1) * 8; //(keep 1 character empty to fill empty positions)

int[] lineLengths = new int[nrLines];

int sineTableLength = 32;

int imageHeight = 32;

// for every line, have a sinetable that rotates it
int[][] sineIndex = new int[nrLines][sineTableLength];

double phaseStep = Math.PI / sineTableLength;

int[] linePhases = new int[200];

int green = 255;


void setup() {

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
    //print(sineIndex[i], "\n");
    }
  }
  
  // the image
  //for (int i = 0; i < linePhases.length; i++) {
   //linePhases[i] = (int)(i * ((float)nrLines / (float)linePhases.length));  

  
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
  print ("So ", nrLines, " different lines per bank\n");

  
  size(320, 200);
  background(0);
  frameRate(50);



  

}



void draw() {
 
  background(0);
  //clear();
  
  
  //int sineValue = sineIndex[animFrame];
  
  
  //textSize(16);
  //text(animFrame, 0, 180);
  //text(sineValue, 50, 180);
  
  
  
  
  //for (int y = 0; y < nrLines; y++) {
    //line(0, y, lineLengths[y], y); 
  //}
  
    
    int animFrame = frameCount % sineTableLength;
    
    if (animFrame == 0) {
      green = green ^ 128;
    }
    
    stroke(0,green,0);
    
  for (int y =0; y < linePhases.length; y++) {
       
    int lineLength= linePhases[y];
    
    int projectedLineIndex = sineIndex[lineLength][animFrame];
    int projectedLineLength = lineLengths[projectedLineIndex];
    line (160-(projectedLineLength/2), y, 160+(projectedLineLength/2), y);
  }
  
  
}
