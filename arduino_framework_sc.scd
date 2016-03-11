SerialPort.listDevices;
(
s.options.memSize = 81920;
s.waitForBoot{
	fork{
		//VARIABLES///////////////////
		var nvox = 4;
		////Arduino
		var ino = ArduinoSMS("/dev/tty.wchusbserial1a140", 9600);
		////Hardware Headers
		var hh = ["p0", "p1", "p2", "p3", "p4", "b0", "b1", "b2", "b3", "b4", "b5", "b6", "b7","fsr0"];
		////Mappings
		var ma = [
			/*p0*/[0,1023,0.0,1.0],
			/*p1*/[0,1023,0.0,1.0],
			/*p2*/[0,1023,0.0,1.0],
			/*p3*/[0,1023,0.0,1.0],
			/*p4*/[0,1023,0.0,1.0],
			/*b0*/[0,1,0,1],
			/*b1*/[0,1,0,1],
			/*b2*/[0,1,0,1],
			/*b3*/[0,1,0,1],
			/*b4*/[0,1,0,1],
			/*b5*/[0,1,0,1],
			/*b6*/[0,1,0,1],
			/*b7*/[0,1,0,1],
			/*fsr0*/[100,900,0.0, 100.0]
		];
		////Control Busses
		var kbs = {Bus.control(s)}!100;
		//ARDUINO/////////////////////
		ino.action = {
			arg msg;
			var sm = msg.split($:);
			hh.do{ |it ix|
				if( it==sm[0], {
					var val = sm[1].asFloat.linlin( ma[ix][0],ma[ix][1],ma[ix][2],ma[ix][3] );
					sm[0].post;
					"-".post;
					val.postln;
					kbs[ix].setSynchronous(val);
				} ) //end if
			} //end hh.do
		} //end ino.action
	}//end fork
}//end s.waitForBoot
)

