import netP5.*;
import oscP5.*;

OscP5 osc;
NetAddress sc;

float mh = 150.0;
float my = 50.0;
float ml = 0.0;
float mh2 = 0.0;

void setup(){
  size(500,500);
  osc = new OscP5(this, 12321);
  sc = new NetAddress("127.0.0.1", 57120);
  osc.plug(this, "getkval", "/kbsval");
}

void draw(){
  background(0);
  //request current control bus value from supercollider
  osc.send( "/getkdata", new Object[]{ 0, 0 }, sc);
  //meter bounding box
  stroke(255,255,0);
  strokeWeight(4);
  noFill();
  rect(50,my,50,mh);
  //meter rect
  noStroke();
  fill(153,255,0);
  mh2 = map(ml, 0.0, 1.0, 150.0, 0.0);
  rect(50, my+mh2, 50, 150-mh2);
  
  /*
  OscMessage msg = new OscMessage("/getkbus");
  msg.add(0);
  msg.add(0);
  osc.send(msg, sc);
  */
}

void getkval(int knum, float val){
  ml = val;
}