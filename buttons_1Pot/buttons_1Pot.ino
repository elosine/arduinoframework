//VARIABLES////////////////////////////////
////Buttons
int nb = 4;
int b[] = {2, 3, 4, 5};
boolean bg[] = {true, true, true, true};
boolean btg[] = {true, true, true, true};
int btamt[] = {10, 2, 2, 2};
int btv[] = {0, 0, 0, 0};
////Pots
int p0 = A0;
int pv = 0;
int ppv = 0;
//SETUP///////////////////////////////////
void setup() {
  Serial.begin(9600);
  for (int i = 0; i < nb; i++) {
    pinMode(b[i], INPUT_PULLUP);
  }
}
//LOOP///////////////////////////////////
void loop() {
  ////POTS//////////////////
  pv = analogRead(p0);
  if ( pv > (ppv + 1) || pv < (ppv - 1) ) { //post value only if pot changes
    Serial.println(pv);
  }
  ppv = pv;
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
