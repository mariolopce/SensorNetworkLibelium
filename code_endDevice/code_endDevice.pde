/*
    ------ Waspmote Pro Code Example --------

    Explanation: This is the basic Code for Waspmote Pro

    Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L.
    http://www.libelium.com

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

// Put your libraries here (#include ...)
#include <WaspSensorEvent_v30.h>
#include <WaspXBee802.h>
#include <WaspFrame.h>

// Destination MAC address
//////////////////////////////////////////
char RX_ADDRESS[] = "0013A200417EE503"; //addres of the board that will receive
//////////////////////////////////////////

// Define the Waspmote ID
char WASPMOTE_ID[] = "node_01";

// define variable
uint8_t error;

char buffer[100];
char temp_string[10]; // Make sure this is large enough to hold your float
char x_string[10];
char y_string[10];
char z_string[10];
char preasure_string[10];
char humidity_string[10];

uint8_t status;
int x_acc;
int y_acc;
int z_acc;
float temp;
float humd;
float pres;
int value;
pirSensorClass pir(SOCKET_1);

void setup()
{
  // Setting ON USB and ACC
  USB.ON();
  USB.println(F("Exercise 3: Sensor reading + sleep"));
  ACC.ON();

  // store Waspmote identifier in EEPROM memory
  frame.setID( WASPMOTE_ID );
  
  // init XBee
  xbee802.ON();
  
  // Setting time
  RTC.ON(); 
  RTC.setTime("29:01:22:02:18:24:56");
  USB.print(F("Time: "));
  USB.println(RTC.getTime());
  // Setting alarm  in offset mode:
  // Alarm 1 is set 30 seconds later
  RTC.setAlarm1("00:00:00:30",RTC_OFFSET,RTC_ALM1_MODE5);


}


void loop()
{
  
  // User should implement some warning
    // In this example, now wait for signal
    // stabilization to generate a new interruption
    // Read the sensor level
    // Turn on the sensor board
    Events.ON();
    value = pir.readPirSensor();
    
    while (value == 1)
    {
      USB.println(F("...wait for PIR stabilization"));
      delay(1000);
      value = pir.readPirSensor();
    }
    // Enable interruptions from the board
  Events.attachInt();
  ///////////////////////////////////////////////
  // 1. Starts accelerometer
  ///////////////////////////////////////////////
  ACC.ON();

  ///////////////////////////////////////////////
  // 2. Enable interruption: ACC Free Fall interruption 
  ///////////////////////////////////////////////
  ACC.setFF(); 

  //----------Check Register-----------------------
  // should always answer 0x32, it is used to check
  // the proper functionality of the accelerometer
  status = ACC.check();
  

  /*

  //----------X Value-----------------------
  x_acc = ACC.getX();

  //----------Y Value-----------------------
  y_acc = ACC.getY();

  //----------Z Value-----------------------
  z_acc = ACC.getZ();

  //-------------------------------

  USB.print(F("\n------------------------------\nCheck: 0x")); 
  USB.println(status, HEX);
  USB.println(RTC.getTime());
  USB.println(F("\n \t0X\t0Y\t0Z")); 
  USB.print(F(" ACC\t")); 
  USB.print(x_acc, DEC);
  USB.print(F("\t")); 
  USB.print(y_acc, DEC);
  USB.print(F("\t")); 
  USB.println(z_acc, DEC);

  */

  ///////////////////////////////////////////////
  // 3. Set low-power consumption state
  ///////////////////////////////////////////////  
  USB.println(F("Waspmote goes into sleep mode until the Accelerometer causes an interrupt"));
  PWR.sleep(SENSOR_ON);


   // Interruption event happened

  ///////////////////////////////////////////////
  // 4. Disable interruption: ACC Free Fall interrupt 
  //    This is done to avoid new interruptions
  ///////////////////////////////////////////////
  ACC.ON();
  ACC.unsetFF(); 
  // Disable interruptions from the board
  Events.detachInt();

  USB.ON();
  USB.println(F("Waspmote wakes up"));

  ///////////////////////////////////////////////
  // 5. Check the interruption source 
  ///////////////////////////////////////////////
  // Only mandatory when multiple interruption 
  // sources are expected to be generated
  if( intFlag & ACC_INT )
  {
    // clear interruption flag
    intFlag &= ~(ACC_INT);
    xbee802.ON();

    snprintf(buffer, sizeof(buffer), "Alarm: Free fall detected");

    // send XBee packet
    error = xbee802.send( RX_ADDRESS, (uint8_t*)buffer, strlen(buffer));
    
    // check TX flag
    if( error == 0 )
    {
      USB.println(F("send ok"));
      
      // blink green LED
      Utils.blinkGreenLED();
      
    }
    else 
    {
      USB.println(F("send error"));
      
      // blink red LED
      Utils.blinkRedLED();
    }

    memset(buffer, 0, sizeof(buffer)); // Resets buffer contents to 0
    
    // print info
    USB.ON();
    USB.println(F("++++++++++++++++++++++++++++"));
    USB.println(F("++ ACC interrupt detected ++"));
    USB.println(F("++++++++++++++++++++++++++++")); 
    USB.println(); 


    // blink LEDs
    for(int i=0; i<10; i++)
    {
      Utils.blinkLEDs(50);
    }
    
    
  }
  if ( intFlag & RTC_INT )
  {
    // clear interruption flag
    intFlag &= ~(RTC_INT);
    Utils.setLED(LED1, LED_ON);
    // print info
    USB.ON();
    USB.println(F("++++++++++++++++++++++++++++"));
    USB.println(F("++ RTC interrupt detected ++"));
    USB.println(F("++++++++++++++++++++++++++++")); 
    USB.println();

    Events.ON();
    //Temperature
    temp = Events.getTemperature();
    //Humidity
    humd = Events.getHumidity();
    //Pressure
    pres = Events.getPressure();


    //ADD HERE THE READ AND SHOW OF THE ACC TAKEN FROM THE COMMENTED CODE FROM ABOVE

    //----------X Value-----------------------
    x_acc = ACC.getX();
  
    //----------Y Value-----------------------
    y_acc = ACC.getY();
  
    //----------Z Value-----------------------
    z_acc = ACC.getZ();
  
    //-------------------------------
  
    USB.print(F("\n------------------------------\nCheck: 0x")); 
    USB.println(status, HEX);
    USB.println(RTC.getTime());
    USB.println(F("\n \t0X\t0Y\t0Z")); 
    USB.print(F(" ACC\t")); 
    USB.print(x_acc, DEC);
    USB.print(F("\t")); 
    USB.print(y_acc, DEC);
    USB.print(F("\t")); 
    USB.println(z_acc, DEC);

    //UNTIL HERE IS THE PART COPIED FROM ABOVE OF THE ACCELEREOMTER
  
    
    ///////////////////////////////////////
    // 2. Print BME280 Values
    ///////////////////////////////////////
    USB.println("-----------------------------");
    USB.print("Temperature: ");
    USB.printFloat(temp, 2);
    USB.println(F(" Celsius"));
    USB.print("Humidity: ");
    USB.printFloat(humd, 1); 
    USB.println(F(" %")); 
    USB.print("Pressure: ");
    USB.printFloat(pres, 2); 
    USB.println(F(" Pa")); 
    USB.println("-----------------------------");  

    //show battery
    USB.print(F("Battery Level: "));
    USB.print(PWR.getBatteryLevel(),DEC);
    USB.println(F(" %"));
    USB.println("-----------------------------"); 
    USB.println("");

    Utils.setLED(LED1, LED_OFF);

    USB.OFF();
    //Events.OFF();

    RTC.setAlarm1("00:00:00:30",RTC_OFFSET,RTC_ALM1_MODE5);
    xbee802.ON();

    
    dtostrf(temp, 6, 2, temp_string);
    dtostrf(x_acc, 6, 2, x_string);
    dtostrf(y_acc, 6, 2, y_string);
    dtostrf(z_acc, 6, 2, z_string);
    dtostrf(humd, 6, 2, humidity_string);
    dtostrf(pres, 6, 2, preasure_string);

    Utils.setLED(LED0, LED_ON);
     // create new frame
    frame.createFrame(ASCII);  
    
    // add frame fields
    frame.addSensor(SENSOR_STR, "new_sensor_frame");
    frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel()); 
    snprintf(buffer, sizeof(buffer), "%s %s %s %d %s %s %s", temp_string, humidity_string, preasure_string, PWR.getBatteryLevel(), x_string, y_string, z_string);
    //snprintf(buffer, sizeof(buffer), "%d %d %d %s", 1, 2, 3, "hola");
    // send XBee packet
    error = xbee802.send( RX_ADDRESS, (uint8_t*)buffer, strlen(buffer));
    
    // check TX flag
    if( error == 0 )
    {
      USB.println(F("send ok"));
      
      // blink green LED
      Utils.blinkGreenLED();
      
    }
    else 
    {
      USB.println(F("send error"));
      
      // blink red LED
      Utils.blinkRedLED();
    }

    memset(buffer, 0, sizeof(buffer)); // Resets buffer contents to 0
    Utils.setLED(LED0, LED_OFF);
    
  }

  if (intFlag & SENS_INT)
  {
    
    // Load the interruption flag. Contains information about what device is triggering the interruption
    Events.loadInt();
    
    // In case the interruption came from PIR
    if (pir.getInt())
    {
      xbee802.ON();
      snprintf(buffer, sizeof(buffer), "Alarm: Motion detected");

      // send XBee packet
      error = xbee802.send( RX_ADDRESS, (uint8_t*)buffer, strlen(buffer));
      
      // check TX flag
      if( error == 0 )
      {
        USB.println(F("send ok"));
        
        // blink green LED
        Utils.blinkGreenLED();
        
      }
      else 
      {
        USB.println(F("send error"));
        
        // blink red LED
        Utils.blinkRedLED();
      }

      memset(buffer, 0, sizeof(buffer)); // Resets buffer contents to 0
      
      USB.println(F("-----------------------------"));
      USB.println(F("Interruption from PIR"));
      USB.println(F("-----------------------------"));
    }    
    
    
    
    // Clean the interruption flag
    intFlag &= ~(SENS_INT);
    
  }

  ///////////////////////////////////////////////////////////////////////
  // 6. Clear interruption pin   
  ///////////////////////////////////////////////////////////////////////
  // This function is used to make sure the interruption pin is cleared
  // if a non-captured interruption has been produced
  PWR.clearInterruptionPin();
  

}
