/*
this example for fully function (official)ethernet code for arduino & pachube. 
including the use of DHCP library, Watchdog timer & manually reset the shield.

hardware note: 
You will need Arduino Duemilanove w/ atmega328. (the sketch is quite big)
You will need LadyADA's bootloader for Watchdog timer to work. (http://www.ladyada.net/library/arduino/bootloader.html)
You will need some modification to reset the ethernet shield.

library note: 
Special thanks to Jordan Terrell(http://blog.jordanterrell.com/) and Georg Kaindl(http://gkaindl.com) for DHCP library


*/

#include <Ethernet.h>
#include <EthernetDHCP.h>
#include <avr/io.h>
#include <avr/wdt.h>
#include <string.h>

#define ID             1    //incase you have more than 1 unit on same network, just change the unit ID to other number
#define REMOTEFEED     8686 //remote feed number here, this has to be your own feed
#define LOCALFEED      7873 //local feed number here
#define APIKEY         "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" // enter your pachube api key here


/*******************************************************************/
/* CONTROL DEVICE 0
/*******************************************************************/

/* delcare the pins where the device is conencted */
int device0_pin1 = 7;              
int device0_pin2 = 6;

/* declare current and previous state of the device */
int device0_past = 0; 
int device0_current = 0;
int device0_state;

void monitorDevice0() {
  Serial.println("device1 is:");
  Serial.println(device0_state);
  if(device0_past == device0_current) {
  Serial.println("same state");
   //its already ON or already OFF
  } else {
  Serial.println("different state");
   switchDevice0();
   device0_past = device0_current; 
  }
}  

void switchDevice0() {
  // if the device is on do a pulse to switch it of
  if(device0_state == 0) {
      // switch off the device
      digitalWrite(device0_pin1,HIGH);
      delay(1000);
      digitalWrite(device0_pin1,LOW);
      delay(1000);
  } else {
      // switch on the device
      digitalWrite(device0_pin2,HIGH);
      delay(1000);
      digitalWrite(device0_pin2,LOW);
      delay(1000);
  }  
}


/*******************************************************************/
/* CONTROL DEVICE 1
/*******************************************************************/

/* delcare the pins where the device is conencted */
int device1_pin1 = 5;              
int device1_pin2 = 4;

/* declare current and previous state of the device */
int device1_past = 0; 
int device1_current = 0;
int device1_state;


void monitorDevice1() {
  Serial.println(device1_state);
  if(device1_past == device1_current) {
  Serial.println("device1: same state");
  // its already ON or already OFF
  } else {
    Serial.println("device 1: different state");
   switchDevice1();
   device1_past = device1_current; 
  }
}  

void switchDevice1() {
  // if the device is off do a pulse to switch it on
  if(device1_state == 0) {
      // switch off the device
      digitalWrite(device1_pin1,HIGH);
      delay(1000);
      digitalWrite(device1_pin1,LOW);
      delay(1000);
  } else {
      // switch on the device
      digitalWrite(device1_pin2,HIGH);
      delay(1000);
      digitalWrite(device1_pin2,LOW);
      delay(1000);
  }  
}

/*******************************************************************/
/* CONTROL DEVICE 2
/*******************************************************************/

/* delcare the pins where the device is conencted */
int device2_pin1 = 3;              
int device2_pin2 = 2;

/* declare current and previous state of the device */
int device2_past = 0; 
int device2_current = 0;
int device2_state;


void monitorDevice2() {
  Serial.println(device2_state);
  if(device2_past == device2_current) {
  Serial.println("device2: same state");
  // its already ON or already OFF
  } else {
    Serial.println("device 2: different state");
   switchDevice2();
   device2_past = device2_current; 
  }
}  

void switchDevice2() {
  // if the device is off do a pulse to switch it on
  if(device2_state == 0) {
      // switch off the device
      digitalWrite(device2_pin1,HIGH);
      delay(1000);
      digitalWrite(device2_pin1,LOW);
      delay(1000);
  } else {
      // switch on the device
      digitalWrite(device2_pin2,HIGH);
      delay(1000);
      digitalWrite(device2_pin2,LOW);
      delay(1000);
  }  
}
/*******************************************************************/

byte mac[] = { 
  0xDA, 0xAD, 0xCA, 0xEF, 0xFE,  byte(ID) };


byte server [] = {  //www.pachube.com
   173,203,98,29
};


boolean ipAcquired = false;
boolean connectedd = false;
boolean reading = false;
#define REMOTE_FEED_DATASTREAMS    27 //define how many of maximun data from remote feed
float remoteSensor[REMOTE_FEED_DATASTREAMS];   
char pachube_data[80];
char buff[64];
char *found;
int pointer = 0;
boolean found_status_200 = false;
boolean found_session_id = false;
boolean found_CSV = false;
boolean found_content = false;
int content_length;
int successes = 0;
int failures = 0;
int counter = 1;
Client client(server, 80);

//timer variables
long previousWdtMillis = 0;
long wdtInterval = 0;
long previousEthernetMillis = 0;
long ethernetInterval = 0;

// variable to store local sensors
int analog1 = 0;
int analog2 = 0;
int analog3 = 0;

//define analog pins for sensors
int analogPin1 = 1;    
int analogPin2 = 2;
int analogPin3 = 5;

//digital out
int resetPin = 9; //reset pin to manually reset the ethernet shield


void setup(){
  
  pinMode(device0_pin1, OUTPUT); 
  pinMode(device0_pin2, OUTPUT);   

  pinMode(device1_pin1, OUTPUT); 
  pinMode(device1_pin2, OUTPUT);

  pinMode(device2_pin1, OUTPUT); 
  pinMode(device2_pin2, OUTPUT);  
  
  MCUSR=0;
  wdt_enable(WDTO_8S); // setup Watch Dog Timer to 8 sec
  pinMode(resetPin,OUTPUT);
  Serial.begin(9600);
  Serial.println("restarted");

}

void loop(){

   monitorDevice0();
   monitorDevice1();
   monitorDevice2();
   
  // Watch Dog Timer will reset the arduino if it doesn't get "wdt_reset();" every 8 sec
  if ((millis() - previousWdtMillis) > wdtInterval) {
    previousWdtMillis = millis();
    wdtInterval = 5000;
    wdt_reset();
    Serial.println("wdt reset");
  }

  //main function is here, at the moment it will only connect to pachube every 10 sec
  if ((millis() - previousEthernetMillis) > ethernetInterval) {
    previousEthernetMillis = millis();
    ethernetInterval = 2000; //10 sec
    wdt_reset();
    Serial.println("wdt reset");
    useEthernet();
      

  }


  while (reading){ 
    while (client.available()) {
      checkForResponse(); 
    } 
  }
}
  
