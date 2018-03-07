//Name:         LightCtrl
//Description:  Light controller
//Author:       David Velasquez
//Date:         06/03/2018

//Library definition
#include <PID_v1.h>

//I/O pin labeling
#define LDR 0
#define LPWM 13

//Constant definitions
const unsigned int NUMREADS = 12;  //Samples to average for smoothing
double consKp = 0.032, consKi = 3.2, consKd = 0.0016; //Controller constants

//Variable definitions
double sp = 0, y = 0, out = 0; //System Variables
String readBuffer = "";
//Smoothing vars (filter electronic noise)
unsigned int readings[NUMREADS] = {0};
unsigned int readIndex = 0;
unsigned long total = 0;

//Library definitions
PID myPID(&y, &out, &sp, consKp, consKi, consKd, DIRECT);

//Subroutines and functions
unsigned int smooth() { //Recursive moving average subroutine
  total = total - readings[readIndex]; // subtract the last reading
  readings[readIndex] = analogRead(LDR); // read from the sensor:
  total = total + readings[readIndex]; // add the reading to the total:
  readIndex = readIndex + 1; // advance to the next position in the array:
  if (readIndex >= NUMREADS) {// if we're at the end of the array...
    readIndex = 0; // ...wrap around to the beginning:
  }
  return total / NUMREADS; // calculate the average:
}

//Configuration
void setup() {
  //Pin config
  pinMode(LPWM, OUTPUT);

  //Output cleaning
  digitalWrite(LPWM, LOW);

  //Communications
  myPID.SetMode(AUTOMATIC);
  Serial.begin(9600);
}

void loop() {
  y = smooth();
  if (Serial.available() > 0) {
    readBuffer = Serial.readStringUntil('\n');
    sp = readBuffer.toInt();
    readBuffer = "";    
    Serial.flush();    
    Serial.println(int(y));
  }
  myPID.Compute();
  analogWrite(LPWM, out);
}

