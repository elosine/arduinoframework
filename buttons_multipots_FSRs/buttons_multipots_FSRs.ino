//VARIABLES////////////////////////////////
////Buttons
int nb = 8;
int b[] = {2, 3, 4, 5, 6, 7, 8, 9};
boolean bg[] = {true, true, true, true, true, true, true, true};
boolean btg[] = {true, true, true, true, true, true, true, true};
int btamt[] = {10, 2, 2, 2, 2, 2, 2, 2};
int btv[] = {0, 0, 0, 0, 0, 0, 0, 0};
////Pots
int np = 4;
int p[] = {A0, A2, A3, A4};
int pv[] = {0, 0, 0, 0};
int ppv[] = {0, 0, 0, 0};
////FSRs
int nfsrs = 1;
int fsr[] = {A5};
int fv[1];
int thresh[] = {80};
boolean peakgate[] = {true};
int pval[1];
//SETUP///////////////////////////////////
void setup() {
  Serial.begin(9600);
  for (int i = 0; i < nb; i++) {
    pinMode(b[i], INPUT_PULLUP);
  }
}
//LOOP///////////////////////////////////
void loop() {
  ////FSRs//////////////////
  for (int i = 0; i < nfsrs; i++) {
    fv[i] = analogRead(fsr[i]); //read analog pins
    //Peak Detection
    if (fv[i] > thresh[i]) { //if above threshold
      //Print out raw fsr value
      Serial.print("fsr" + String(i) + ":");
      Serial.println(fv[i], DEC);
      if (fv[i] > pval[i]) { //if going up
        pval[i] = fv[i]; //store current value as last value
      }//
      else { // if no longer going up, you have found a peak
        if (peakgate[i]) { //gate so only one peak gets through
          Serial.print("fsrpk" + String(i) + ":"); //send out peak
          Serial.println(fv[i], DEC);
          peakgate[i] = false; //close gate so only one peak gets through
        }
      }
    }
    if (fv[i] < thresh[i]) {//if fsr val falls below threshold, then reset peak gate to look for next peak
      if (peakgate[i] == false) {//so more than one value does not come through
        peakgate[i] = true;
        Serial.print("fsrpk" + String(i) + ":"); //send out peak
        Serial.println(0);
      }
    }
  }//end for(int i=0;i<nfsrs;i++)
  ////POTS//////////////////
  for (int i = 0; i < np; i++) {
    pv[i] = analogRead(p[i]);
    if ( pv[i] > (ppv[i] + 1) || pv[i] < (ppv[i] - 1) ) { //post value only if pot changes
      Serial.print("p" + String(i) + ":");
      Serial.println(pv[i]);
    }
    ppv[i] = pv[i];
  }
  ////BUTTONS//////////////////
  for (int i = 0; i < nb; i++) {
    if (digitalRead(b[i]) == LOW) { //When Button Pressed
      //////Momentary//////
      if (bg[i]) {
        bg[i] = false;
        Serial.print("b" + String(i) + ":");
        Serial.println(1);
      }
      //////Toggle//////
      if (btg[i]) {
        btg[i] = false;
        btv[i] = (btv[i] + 1) % btamt[i];
        Serial.print("bt" + String(i) + ":");
        Serial.println(btv[i]);
      }
    }
    else { //When Button Released
      //////Momentary//////
      if (!bg[i]) {
        bg[i] = true;
        Serial.print("b" + String(i) + ":");
        Serial.println(0);
      }
      //////Toggle//////
      if (!btg[i]) {
        btg[i] = true;
      }
    }
  }
  delay(15);
}
