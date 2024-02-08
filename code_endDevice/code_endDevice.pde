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


    //ADDED HERE THE READ AND SHOW OF THE ACC TAKEN FROM THE COMMENTED CODE FROM ABOVE

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
    

    USB.OFF();
    //Events.OFF();

    RTC.setAlarm1("00:00:00:30",RTC_OFFSET,RTC_ALM1_MODE5);
  }

  if (intFlag & SENS_INT)
  {
    
    // Load the interruption flag. Contains information about what device is triggering the interruption
    Events.loadInt();
    
    // In case the interruption came from PIR
    if (pir.getInt())
    {
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
