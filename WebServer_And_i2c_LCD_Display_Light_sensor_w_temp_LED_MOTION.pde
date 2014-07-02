

/*
 * Arduino + temp , motion, light, and serial connected lcd display
 * 
 *      Original Source Created on: Aug 31, 2011
 * Licensed under Creative Commons Attribution-Noncommercial-Share Alike 3.0
 *    Utilized in the following example by JarenHavell.com in "Server room environmental monitor part 2"
 *   http://www.jarenhavell.com/projects/server-room-environmental-monitoring-part-2/
 * HAREDWARE SETUP
 * Arduino Duemilanove (ATMEL 328p)
 * DFRobot Ethernet Shield DFR0110, Powered by a Wiznet W5100 http://www.dfrobot.com/index.php?route=product/product&product_id=169
 * Sparkfun Protoboard (v2)
 * TEMT6000  Ambient Light Sensor by Vishay via the Sparkfun Breakout Board http://www.sparkfun.com/products/8688
 * JK Device HD44780 Compatible 2 x 16 Char LCD display
 * Sparkfun SerLCD I2C backpack https://www.sparkfun.com/products/258
 * Adafruit Arduino enclosure
 * Generic PIR Sensor Motion Sensor module from ebay
 * Modern Device TempSensor i2c Temperature sensor (Ti TMP421)-  hard coded to do i2c on arduino analog pins 2,3,4,5 - from liquidware http://www.liquidware.com/shop/show/SEN-TMP/Temp+Sensor
 * Grove - Serial LCD - "twig serial LCD" 2x16 chars-  from Seeedstudios  http://www.seeedstudio.com/wiki/index.php?title=Twig_-_Serial_LCD
 * 

 */


/* ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~Additional Attributions ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~*/


/*
 LiquidCrystal Library - display() and noDisplay()

 Demonstrates the use a 16x2 LCD display.  The LiquidCrystal
 library works with all LCD displays that are compatible with the
 Hitachi HD44780 driver. There are many of them out there, and you
 can usually tell them by the 16-pin interface.


 The circuit:
 * LCD RX pin to digital pin d2
 * temp sensor analog pins a2,a3,a4,a5 
 * Light Sensor analog pin a0 (TEMT6000)
 * xbee tx d0 
 * xbee rx d1 
 * Ethernet shield attached to pins 10, 11, 12, 13
 * led Pin D3

 Library originally added 18 Apr 2008
 by David A. Mellis
 library modified 5 Jul 2009
 by Limor Fried (http://www.ladyada.net)
 example added 9 Jul 2009
 by Tom Igoe
 modified 22 Nov 2010
 by Tom Igoe

 This example code is in the public domain.

 http://www.arduino.cc/en/Tutorial/LiquidCrystal
 */
/*
  Web  Server
 
 A simple web server that shows the value of the analog input pins.
 using an Arduino Wiznet Ethernet shield. 
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 * Analog inputs attached to pins A0 through A5 (optional)
 
 created 18 Dec 2009
 by David A. Mellis
 modified 4 Sep 2010
 by Tom Igoe
 
/* ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~ BEGIN CODE ~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~*/

// include the library code:

#include <SPI.h>
#include <Ethernet.h>

#include <SoftwareSerial.h>
#include <Wire.h>
#include <LibTemperature.h>

//------------------Start web server Setup -mac and IP address---------
// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 10,0,0,174 };
// Initialize the Ethernet server library
// with the IP address and port you want to use 
// (port 80 is default for HTTP):
Server server(80);
//----------------- End Web Server Setup--------


//------------------Start i2c LCD backpack setup----------
// since the LCD does not send data back to the Arduino, we should only define the txPin
#define txPin 2 //pin used for i2c based LCD backpack
SoftwareSerial LCD = SoftwareSerial(2, txPin);
const int LCDdelay=10;  // conservative, 2 actually works
//------------------End i2c LCD backpack setup


//-----------------Setup the Variables for sensors-------
int sensorPin1 = A0;    // select the input pin for the light sensor
int sensorPin2 = A1;    // select the input pin for the PIR sensor
int sensorValue1 = 0;  // variable to store the value coming from the Light-sensor, default 0
int sensorValue2 = 0;  // variable to store the value coming from the PIR-sensor, default 0
float tempF = 0; // variable to store the value coming from the temp sensor after converted to F degrees
  const int ledpin3 = 3; //pin corresponding to pin 3 for LED

//-----------------End sensor variable madness------------

//-----------------Start LCD controlls-------------------
// wbp: goto with row & column
void goTo(int row, int col) {
  LCD.print(0xFE, BYTE);   //command flag
  LCD.print((col + row*64 + 128), BYTE);    //position 
  delay(LCDdelay);
}


void clearLCD(){
  LCD.print(0xFE, BYTE);   //command flag
  LCD.print(0x01, BYTE);   //clear command.
  delay(LCDdelay);
}
void backlightOn() {  //turns on the backlight
  LCD.print(0x7C, BYTE);   //command flag for backlight stuff
  LCD.print(157, BYTE);    //light level.
  delay(LCDdelay);
}
void backlightOff(){  //turns off the backlight
  LCD.print(0x7C, BYTE);   //command flag for backlight stuff
  LCD.print(128, BYTE);     //light level for off.
   delay(LCDdelay);
}
void serCommand(){   //a general function to call the command flag for issuing all other commands   
  LCD.print(0xFE, BYTE);
}

//---------------------End LCD controlls-----------------


//---------------------Begin LCD setup -----------------
void setup() {
pinMode(txPin, OUTPUT); //sets up Pint as output to LCD
  LCD.begin(9600);
  clearLCD();
  goTo(0,0);
//}
//--------------------End LCD Setup-----------------------


//---------------------Begin LED Output-------------------

  pinMode(3, OUTPUT);     //setup pin for digital out - pin 3

//---------------------End led Output---------------------



//------------------Begin Web SErver Setup---------------
//void setup()
//{
  // start the Ethernet connection and the server:
  Ethernet.begin(mac, ip);
  server.begin();
}
//------------------End Web SErver Setup----------------





//-------------------Begin Sensor read and LCD control----------------------

void loop() {

     // read the value from the sensors:
 sensorValue1 = analogRead(sensorPin1); //light sensor
 sensorValue2 = analogRead(sensorPin2); //PIR
 LibTemperature temp = LibTemperature(0); // reads temperature in Celcius
 
 // convert to degF
  tempF = (temp.GetTemperature() * 9 / 5) + 32; 
  //stores float to int because serlcd wont send floats
  int tempfd = tempF;
  
 
 // Print sensor value to the LCD.

  goTo(1,0);
  LCD.print("Light");
  goTo(0,0);
  LCD.print("    ");
  goTo(0,0);
  LCD.print(sensorValue1);

  goTo(1,6);
  LCD.print("PIR");
  goTo(0,6);
  LCD.print("    ");
  goTo(0,6);
  LCD.print(sensorValue2);
  
  goTo(1,10);
  LCD.print("Temp F"); 
  goTo(0,12);
  LCD.print(tempfd);


//Iluminate LED if motion.
digitalWrite(3, HIGH);   // set the LED on

{if (sensorValue2 < 10) {
          // no motion
          digitalWrite(ledpin3, LOW);   // set the LED off
        } 
        else {
          // motion
          digitalWrite(ledpin3, HIGH);   // set the LED ON
        }
}
delay(500);


//}



//-----------------End Sensor read and LCD control------------------------

//-----------------Web Server code---------------------------

 // listen for incoming clients
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean currentLineIsBlank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        // if you've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so you can send a reply
        if (c == '\n' && currentLineIsBlank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();

		     //meta-refresh page every 2 seconds
          client.print("<HEAD>");
          client.print("<meta http-equiv=\"refresh\" content=\"30\">");
          client.print("<TITLE />Network Monitoring Device</title>");
          client.print("</head>");
		  
		  
          // output the value of each analog input pin
          //for (int analogChannel = 0; analogChannel < 1; analogChannel++) {
            
            int analogChannel = 0;  //select channell 1
            client.print("Light Level from channel ");
            client.print(analogChannel);
            client.print(" is ");
            client.print(analogRead(analogChannel));
            client.println("<br />");
            client.print("Temperature is ");
            client.print(tempfd);
            client.print(" Degrees F");
            client.println("<br />");
          //}
          break;
        }
        if (c == '\n') {
          // you're starting a new line
          currentLineIsBlank = true;
        } 
        else if (c != '\r') {
          // you've gotten a character on the current line
          currentLineIsBlank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(1);
    // close the connection:
    client.stop();
  }
}

//--------------------End web server code ----------------------
