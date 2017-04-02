
/* 
Building Arduino Dust Sensor with GUI using:        
      - Arduino Mega 2560                   
      - Shinyei PPD42NS                     
 http://www.seeedstudio.com/depot/grove-dust-sensor-p-1050.html
 http://www.sca-shinyei.com/pdf/PPD42NS.pdf                                            
                                                    
 Wiring Instruction:                        
      - PPD42NS Pin 1 => GND                
      - PPD42NS Pin 2 => D51                
      - PPD42NS Pin 3 => 5V                 
      - PPD42NS Pin 4 => D50                
*/




import processing.serial.*;

import cc.arduino.*;

Arduino arduino;
//setup grafic and SVG
PFont Apex;
PFont ApexB;


PShape scale;
PShape scale2;

float pi =3.1415927;
float x,y=1;

//Set variables for PM10 and PM2,5 readings
 long starttime;
 long sampletime_ms = 60000; // TIME BETWEEN MEASURES AND UPDATES

 long triggerOnP2;
 long triggerOffP2;
 long pulseLengthP2;
 long durationP2;
int valP2 = Arduino.HIGH;
boolean triggerP2 = false;
float ratioP2 = 0;
float countP2;
float concLarge;
float Store10;
int i=0;

 long triggerOnP1;
 long triggerOffP1;
 long pulseLengthP1;
 long durationP1;
int valP1 = Arduino.HIGH;
boolean triggerP1 = false;
float ratioP1 = 0;
float countP1;
float concSmall;
float[] Storage10 = new float[3];
float[] Storage25 = new float[3];
color blue = color(179,195,205);
color noblue = color(179,195,205,0);

color green1 = color(122,139,79);
color green2 = color(78,90,75);
color beige = color(240,220,200);
color red = color(154,123,114);

//info txt
String s10= "includes dust, pollen and mold spores and other particles smaller then 10 micrometers \n\n50% of these particles are not filters by your nose and throat ending up in your lungs.\n\nEvery increase of 10 ug/m3 in PM10, the lung cancer rate rises by 22%.";
String s25= "include combustion particles, organic compounds, metals and other particles smaller then 2.5micrometers\n\n 50% of these particles are so small that they pass through the lungs to affect other organs directly.\n\nAs PM2,5 can penetrate deeper into the lungs a increase by 10 ug/m3 increase the lung cancer rate by 36%.";

void setup() {
//screen size
 size(1280 , 720);  
//retina mode
  pixelDensity(2);
//load svg
  scale=loadShape("scale10.svg");
  scale2=loadShape("scale25.svg");
//load font
Apex = ApexB = loadFont("ApexNew-Light-30.vlw");



Storage10[0]= Storage10[1] = 21; //start values avg munich
Storage25[0] = 15;

//start screen 
background(blue);
  
textFont(Apex, 20);
  fill(0);
    text("PM10",30, height/2+40);
    textAlign(RIGHT);
    text("PM2,5",width-30 ,height/2+40);

textFont(ApexB, 35);
  fill(0);
  textAlign(LEFT);
   text("Pollution Sensor", 30,50);
  
    textAlign(LEFT, CENTER);
      text(Storage10[0]+"ug/m3", 30, height/2-10);
    textAlign(RIGHT, CENTER);
      text(Storage25[0]+"ug/m3", width-30, height/2-10);

 
 
  pushMatrix(); 
translate(x, Storage10[0]*10);
shape(scale ,width/2-285-10, -2000+height/2);
  popMatrix();
  
  pushMatrix(); 
translate(x, Storage25[0]*20);
shape(scale2 ,width/2+10, -2000+height/2);
  popMatrix();
  
  setGradient(0, 0, width, 200, blue,noblue,1);
  
  setGradient(0, 490, width, 250, blue,noblue,2);
  
  stroke(50);
strokeWeight(2);
line(300, height/2, width-300, height/2);


//info
textFont(Apex, 15);
  fill(0);
      textAlign(LEFT);
textLeading(20);
    text(s10,30, height/2+70,250,1000);
    textAlign(RIGHT);
    text(s25,width-30 ,height/2+70, -250,1000);


textFont(ApexB, 35);
  fill(0);
  textAlign(LEFT);
   text("Pollution Sensor", 30,50);


// connect arduino 
arduino = new Arduino(this, "/dev/tty.usbmodem1411", 57600);  //coose your port

//Set pinmode
arduino.pinMode(50, Arduino.INPUT); //PM2,5
arduino.pinMode(51, Arduino.INPUT);// PM10
//Serial.begin(9600);
delay(10);

}

void setGradient(int x, int y, float w, float h, color c1, color c2,int updown) {

  noFill();

  if (updown==1)
    for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c1, c2, inter);
      stroke(c);
      line(x, i, x+w, i);
    }
      else{
        for (int i = y; i <= y+h; i++) {
      float inter = map(i, y, y+h, 0, 1);
      color c = lerpColor(c2, c1, inter);
      stroke(c);
      line(x, i, x+w, i);
      
      }
      
    }
}

    

//measure fuction + gui 
void measure(){
  
  
valP1 = arduino.digitalRead(50); // Small ( pm2.5)
valP2 = arduino.digitalRead(51); // Large ( pm10 )

//——–PM2,5————-

if(valP1 == Arduino.LOW && triggerP1 == false){
triggerP1 = true;
triggerOnP1 = millis()*1000;
}

if (valP1 == Arduino.HIGH && triggerP1 == true){
triggerOffP1 = millis()*1000;
pulseLengthP1 = triggerOffP1 - triggerOnP1;
durationP1 = durationP1 + pulseLengthP1;
triggerP1 = false;
}

//———–PM10————

if(valP2 == Arduino.LOW && triggerP2 == false){
triggerP2 = true;
triggerOnP2 = millis()*1000;
}

if (valP2 == Arduino.HIGH && triggerP2 == true){
triggerOffP2 = millis()*1000;
pulseLengthP2 = triggerOffP2 - triggerOnP2;
durationP2 = durationP2 + pulseLengthP2;
triggerP2 = false;
}

//———-Calcolo———–

if ((millis() - starttime) > sampletime_ms) {

// Integer percentage 0=>100
ratioP1 = durationP1/(sampletime_ms*10.0); // Integer percentage 0=>100
ratioP2 = durationP2/(sampletime_ms*10.0);
//cal1
countP1 = 1.1*pow(ratioP1,3)-3.8*pow(ratioP1,2)+1023*ratioP1+0.62; //to be calibrated
countP2 = 1.1*pow(ratioP2,3)-3.8*pow(ratioP2,2)+520*ratioP2+0.62;

float PM10count = countP2;
float PM25count = countP1 - countP2;

//PM10 count to mass concentration conversion
float r10 = 2.6*pow(10,-6);
float pi = 3.14159;
float vol10 = (4/3)*pi*pow(r10,3);
float density = 1.65*pow(10,12);
float mass10 = density*vol10;
float K = 3531.5;
concLarge = (PM10count)*K*mass10;

//PM2.5 count to mass concentration conversion
float r25 = 0.44*pow(10,-6);
float vol25 = (4/3)*pi*pow(r25,3);
float mass25 = density*vol25;
concSmall = (PM25count)*K*mass25;



print("PM10Conc: ");
print(concLarge);
print(" ug/m3 , PM2.5Conc: ");
print(concSmall);
println(" ug/m3");



concLarge = round(concLarge * 100)  /100;
concSmall = round(concSmall * 100) /100;

//save values in array

if (concLarge>1.1){
   Store10=concLarge;
}
else{
  Storage10[2]=concLarge;
}

if (i==0){
  Storage10[0]=Store10;

  }
  else{
    Storage10[1]=Store10;
  
  }




if (concSmall>=0){
   Storage25[0]=concSmall;
}
else{
  Storage25[2]=concSmall;
}

print(Store10);
println(Storage25[0]);

//graphic


background(blue);
  
textFont(Apex, 20);
  fill(0);
    text("PM10",30, height/2+40);
    textAlign(RIGHT);
    text("PM2,5",width-30 ,height/2+40);

textFont(ApexB, 35);
  fill(0);
  textAlign(LEFT);
   text("Pollution Sensor", 30,50);
  
    textAlign(LEFT, CENTER);
      text(Storage10[0]+"ug/m3", 30, height/2-10);
    textAlign(RIGHT, CENTER);
      text(Storage25[0]+"ug/m3", width-30, height/2-10);

 
 
  pushMatrix(); 
translate(x, Storage10[0]*10);
shape(scale ,width/2-285-10, -2000+height/2);
  popMatrix();
  
  pushMatrix(); 
translate(x, Storage25[0]*20);
shape(scale2 ,width/2+10, -2000+height/2);
  popMatrix();
  
  setGradient(0, 0, width, 200, blue,noblue,1);
  
  setGradient(0, 490, width, 250, blue,noblue,2);
  
  stroke(50);
strokeWeight(2);
line(300, height/2, width-300, height/2);


//info
textFont(Apex, 15);
  fill(0);
      textAlign(LEFT);
textLeading(20);
    text(s10,30, height/2+70,250,1000);
    textAlign(RIGHT);
    text(s25,width-30 ,height/2+70, -250,1000);


textFont(ApexB, 35);
  fill(0);
  textAlign(LEFT);
   text("Pollution Sensor", 30,50);



//Reset Values
durationP1 = 0;
durationP2 = 0;
starttime = millis();



}
}


void draw(){
 
   measure(); // Recall of the measure program


}