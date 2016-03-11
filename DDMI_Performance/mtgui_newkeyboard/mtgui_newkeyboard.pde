import oscP5.*;
import netP5.*;

OscP5 osc;
NetAddress sc;

float pitch, amp;
float keyw;
float r1 = 42.0;
float r2 = 80.0;
int startpart; //offset from c, e.g. d=2, f#=6...

float numkeys;
int keyh;

void setup() {
  size(1000, 200);
  numkeys = int(r2-r1);
  keyw = width/numkeys;
  keyh = height;
  startpart = int(r1)%12;

  r1 = r1-0.5; //adjustment so center of key is actual pitch
  r2 = r2 - 0.5;

  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
}

void draw() {
  background(255);

  if (mousePressed) {
    pitch = map(mouseX, 0.0, width, r1, r2); //two octave range
    amp = norm(mouseY, height, 0.0);
    OscMessage pitchmsg = new OscMessage("/pitch");
    pitchmsg.add(pitch);
    osc.send(pitchmsg, sc);
    OscMessage ampmsg = new OscMessage("/amp");
    ampmsg.add(amp);
    osc.send(ampmsg, sc);

    OscMessage trig = new OscMessage("/trig");
    trig.add(1);
    osc.send(trig, sc);
  }

  strokeWeight(2);
  for (int i=0; i<numkeys; i++) {
    int n = i+startpart;
    if (n%12 == 1 || n%12 == 3 || n%12==6 || n%12==8 || n%12==10) {
      //parameters for black keys
      fill(0);
      keyh = height-50;
      noStroke();
    } //
    else {
      //parameters for white keys
      fill(255);
      keyh = height;
      stroke(0);
    }
    rect( keyw*i, 0, keyw, keyh);
  }

  // rect(0, 0, keyw, height);
  // rect(keyw, 0, keyw, height);
  // rect(2*keyw, 0, keyw, height);
  // rect(3*keyw, 0, keyw, height);
  //rect(4*keyw, 0, keyw, height);
}

void mousePressed() {
}

void mouseReleased() {
  OscMessage trig = new OscMessage("/trig");
  trig.add(0);
  osc.send(trig, sc);
}

//change pitch/amp while dragging mouse
//replace pitch range with variables
//make a visual keyboard with pitch restrictions
//light up objects when pressing