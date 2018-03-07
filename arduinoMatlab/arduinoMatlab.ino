//I/O pin labeling
#define LDR 0
#define LPWM 13

//Constant definitions
const unsigned int NUMREADS = 12;  //Samples to average for smoothing

//Variable definitions
unsigned int val = 0;
String readBuffer = "";
unsigned int sp = 0;
//Smoothing vars (filter electronic noise)
unsigned int readings[NUMREADS] = {0};
unsigned int readIndex = 0;
unsigned int total = 0;

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
  pinMode(LPWM, OUTPUT);
  digitalWrite(LPWM, LOW);
  Serial.begin(9600);
}

void loop() {
  val = smooth();
  if (Serial.available() > 0) {
    readBuffer = Serial.readStringUntil('\n');
    sp = readBuffer.toInt();
    readBuffer = "";    
    Serial.flush();
    analogWrite(LPWM, sp * 255.0 / 1023.0);
    Serial.println(val);
  }
}

