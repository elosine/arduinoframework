int nb = 4;
int b[] = {2, 3, 4, 5};
boolean bg[] = {true, true, true, true};

void setup() {
  Serial.begin(9600);
  for (int i = 0; i < nb; i++) {
    pinMode(b[i], INPUT_PULLUP);
  }
}

void loop() {
  for (int i = 0; i < nb; i++) {
    if (digitalRead(b[i]) == LOW) {
      if (bg[i]) {
        bg[i] = false;
        Serial.print("b" + String(i) + ":");
        Serial.println(1);
      }
    }
    else {
      if (!bg[i]) {
        bg[i] = true;
        Serial.print("b" + String(i) + ":");
        Serial.println(0);
      }
    }
  }
  delay(15);
}
