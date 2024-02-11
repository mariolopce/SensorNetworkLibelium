/*  
 *  ------ [802_03] - receive XBee packets -------- 
 *  
 *  Explanation: This program shows how to receive packets with 
 *  XBee-802.15.4 modules.
 *  
 *  Copyright (C) 2016 Libelium Comunicaciones Distribuidas S.L. 
 *  http://www.libelium.com 
 *  
 *  This program is free software: you can redistribute it and/or modify 
 *  it under the terms of the GNU General Public License as published by 
 *  the Free Software Foundation, either version 3 of the License, or 
 *  (at your option) any later version. 
 *  
 *  This program is distributed in the hope that it will be useful, 
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of 
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 *  GNU General Public License for more details. 
 *  
 *  You should have received a copy of the GNU General Public License 
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>. 
 *  
 *  Version:           3.0
 *  Design:            David Gascón 
 *  Implementation:    Yuri Carmona
 */

#include <WaspWIFI_PRO.h> 
#include <WaspXBee802.h>
#include <WaspSensorEvent_v30.h>
#include <WaspFrame.h>

#include <Countdown.h>
#include <FP.h>
#include <MQTTFormat.h>
#include <MQTTLogging.h>
#include <MQTTPacket.h>
#include <MQTTPublish.h>
#include <MQTTSubscribe.h>
#include <MQTTUnsubscribe.h>

// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket = SOCKET1;
///////////////////////////////////////


// choose TCP server settings
///////////////////////////////////////
char HOST[]        = "mqtt3.thingspeak.com"; //MQTT Broker
char REMOTE_PORT[] = "1883";  //MQTT
char LOCAL_PORT[]  = "3000";
///////////////////////////////////////

// define variable
uint8_t error;
uint8_t status;

unsigned long previous;
uint16_t socket_handle = 0;

uint16_t ciclo = 0;

char buffer[100];
char temp_gateway_string[10]; // Make sure this is large enough to hold your float
char x_gateway_string[10];
char y_gateway_string[10];
char z_gateway_string[10];
char pressure_gateway_string[10];
char humidity_gateway_string[10];

int temp_gateway; // Make sure this is large enough to hold your float
int x_gateway;
int y_gateway;
int z_gateway;
float pressure_gateway;
float humidity_gateway;

int battery;
char temperature[10], x_acc[10], y_acc[10], z_acc[10], humidity[10], pressure[10];

int wifi_setUp_done = 0;

void setup()
{  
  // init USB port
  USB.ON();
  USB.println(F("Gateway"));
  ACC.ON();

  // init XBee 
  xbee802.ON();
}


void loop()
{ 
  // receive XBee packet (wait for 10 seconds)
  error = xbee802.receivePacketTimeout( 10000 );

  // check answer  
  if( error == 0 ) 
  {
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Data: "));  
    USB.println( xbee802._payload, xbee802._length);  //payload and lenght of the payload buffer
     
    if (strcmp((char*)xbee802._payload, "Alarm: Free fall detected") == 0){
       // Mandar alarma
    }
    else if (strcmp((char*)xbee802._payload, "Alarm: Motion detected") == 0){
      // Mandar alarma
    }
    else{
      sscanf( (const char*) xbee802._payload, "%s %s %s %d %s %s %s", temperature, humidity, pressure, &battery, x_acc, y_acc, z_acc);
    //sscanf( (const char*) xbee802._payload, "%d %d %d %s", 1, 2, 3, "hola");
    
    USB.println(F("Temperature: "));
    USB.println(temperature);
    USB.println(F("Humidity: "));
    USB.println(humidity);
    USB.println(F("Pressure: "));
    USB.println(pressure);
    USB.println(F("Battery level: "));
    USB.println(battery);
    USB.println(F("X_Acc: "));
    USB.println(x_acc);
    USB.println(F("Y_Acc: "));
    USB.println(y_acc);
    USB.println(F("Z_Acc: "));
    USB.println(z_acc);

    //Temperature
    temp_gateway = Events.getTemperature();
    //Humidity
    humidity_gateway = Events.getHumidity();
    //Pressure
    pressure_gateway = Events.getPressure();


    //ADD HERE THE READ AND SHOW OF THE ACC TAKEN FROM THE COMMENTED CODE FROM ABOVE

    //----------X Value-----------------------
    x_gateway = ACC.getX();
  
    //----------Y Value-----------------------
    y_gateway = ACC.getY();
  
    //----------Z Value-----------------------
    z_gateway = ACC.getZ();
  
    //-------------------------------
    }
    
    
    // Show data stored in '_payload' buffer indicated by '_length'
    USB.print(F("Length: "));  
    USB.println( xbee802._length,DEC); //print the usefull data of the buffer, which is the buffer elemets among the length

    ciclo++;

    //////////////////////////////////////////////////
    // 1. Switch ON
    //////////////////////////////////////////////////

    if(wifi_setUp_done==0){
    
      error = WIFI_PRO.ON(socket);
    
      if ( error == 0 )
      {
        USB.println(F("1. WiFi switched ON"));
      }
      else
      {
        USB.println(F("1. WiFi did not initialize correctly"));
      }
    }
      //////////////////////////////////////////////////
    // 2. Check if connected
    //////////////////////////////////////////////////
  
    // get actual time
    previous = millis();
  
    // check connectivity
    status =  WIFI_PRO.isConnected();
  
    // check if module is connected
    if ( status == true )
    {
      USB.print(F("2. WiFi is connected OK"));
      USB.print(F(" Time(ms):"));
      USB.println(millis() - previous);
  
      // get IP address
      error = WIFI_PRO.getIP();
  
      if (error == 0)
      {
        USB.print(F("IP address: "));
        USB.println( WIFI_PRO._ip );
      }
      else
      {
        USB.println(F("getIP error"));
      }
    }
    else
    {
      USB.print(F("2. WiFi is connected ERROR"));
      USB.print(F(" Time(ms):"));
      USB.println(millis() - previous);
    }
  
  
  
    //////////////////////////////////////////////////
    // 3. TCP
    //////////////////////////////////////////////////
  
    // Check if module is connected
    if (status == true)
    {
  
      ////////////////////////////////////////////////
      // 3.1. Open TCP socket
      ////////////////////////////////////////////////
      error = WIFI_PRO.setTCPclient( HOST, REMOTE_PORT, LOCAL_PORT);
  
      //LINEA NUEVA INTRODUCIDA
      //LOCAL_PORT[3]= (LOCAL_PORT[3] == '9') ? '0': (LOCAL_PORT[3]+1);

      while(wifi_setUp_done == 0){
        // check response
        if (error == 0)
        {
          // get socket handle (from 0 to 9)
          socket_handle = WIFI_PRO._socket_handle;
    
          USB.print(F("3.1. Open TCP socket OK in handle: "));
          USB.println(socket_handle, DEC);
          wifi_setUp_done=1;
        }
        else
        {
          USB.println(F("3.1. Error calling 'setTCPclient' function"));
          WIFI_PRO.printErrorCode();
          status = false;
        }

        delay(1000);
      
      }
      
    }
  
    if (status == true)
    {
      /// Publish MQTT
      MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
      MQTTString topicString = MQTTString_initializer;
      unsigned char buf[200];
      int buflen = sizeof(buf);
      unsigned char payload[100];

      unsigned char acc_buf[200];
      int acc_buflen = sizeof(buf);
      unsigned char acc_payload[100];
  
      // options
      data.clientID.cstring = (char*)"JwIBCDIyAxEGGBozBgYLGDg";
      data.password.cstring = (char*)"H6N/1Vyt6HvzFLAdGhPKKoHn";
      data.username.cstring = (char*)"JwIBCDIyAxEGGBozBgYLGDg";
      data.keepAliveInterval = 30;
      data.cleansession = 1;
      int len = MQTTSerialize_connect(buf, buflen, &data); /* 1 */
      int acc_len = MQTTSerialize_connect(acc_buf, acc_buflen, &data);
  
      // Topic and message
      //topicString.cstring = (char *)"g0/mota1/temperature";
      //snprintf((char *)payload, 100, "%s%d", "Mota1 #", ciclo);
    
      topicString.cstring = (char *) "channels/2425312/publish";
      //snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(temp_gateway), int(humidity_gateway), long(pressure_gateway), PWR.getBatteryLevel(), int(x_gateway), int(y_gateway), int(z_gateway));
      snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&status=MQTTPUBLISH", int(temp_gateway), int(humidity_gateway), long(pressure_gateway), PWR.getBatteryLevel());
      USB.println(int(x_gateway));
      USB.println(int(y_gateway));
      USB.println(int(z_gateway));
      snprintf((char *)acc_payload, 100, "field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(x_gateway), int(y_gateway), int(z_gateway));
      //snprintf((char *)payload, 100, "field1=%d&field2=%d&status=MQTTPUBLISH", int(temp_gateway), int(humidity_gateway));
      //USB.println(payload);
      int payloadlen = strlen((const char*)payload);
      int acc_payloadlen = strlen((const char*)acc_payload);
  
      len += MQTTSerialize_publish(buf + len, buflen - len, 0, 0, 0, 0, topicString, payload, payloadlen); /* 2 */
  
      len += MQTTSerialize_disconnect(buf + len, buflen - len); /* 3 */


      acc_len += MQTTSerialize_publish(acc_buf + acc_len, acc_buflen - acc_len, 0, 0, 0, 0, topicString, acc_payload, acc_payloadlen); /* 2 */
  
      acc_len += MQTTSerialize_disconnect(acc_buf + acc_len, acc_buflen - acc_len); /* 3 */
  
  
      ////////////////////////////////////////////////
      // 3.2. send data
      ////////////////////////////////////////////////
      
      error = WIFI_PRO.send( socket_handle, buf, len);
  
      // check response
      if (error == 0)
      {
        USB.println(F("3.2. Send data OK"));
      }
      else
      {
        USB.println(F("3.2. Error calling 'send' function"));
        WIFI_PRO.printErrorCode();
      }
      
      delay(100);
      
      error = WIFI_PRO.send( socket_handle, acc_buf, acc_len);
  
      // check response
      if (error == 0)
      {
        USB.println(F("3.2. Send acc data OK"));
      }
      else
      {
        USB.println(F("3.2. Error calling 'send' function for sending acc data"));
        WIFI_PRO.printErrorCode();
      }
      
      
  
      ////////////////////////////////////////////////
      // 3.3. Wait for answer from server
      ////////////////////////////////////////////////
      /*      USB.println(F("Listen to TCP socket:"));
            error = WIFI_PRO.receive(socket_handle, 30000);
  
            // check answer
            if (error == 0)
            {
              USB.println(F("\n========================================"));
              USB.print(F("Data: "));
              USB.println( WIFI_PRO._buffer, WIFI_PRO._length);
  
              USB.print(F("Length: "));
              USB.println( WIFI_PRO._length,DEC);
              USB.println(F("========================================"));
            }
      */
    }
    ////////////////////////////////////////////////
    // 3.4. close socket
    ////////////////////////////////////////////////
    error = WIFI_PRO.closeSocket(socket_handle);
  
    // check response
    if (error == 0)
    {
      USB.println(F("3.3. Close socket OK"));
    }
    else
    {
      USB.println(F("3.3. Error calling 'closeSocket' function"));
      WIFI_PRO.printErrorCode();
    }

  
  }
  else
  {
    // Print error message:
    /*
     * '7' : Buffer full. Not enough memory space
     * '6' : Error escaping character within payload bytes
     * '5' : Error escaping character in checksum byte
     * '4' : Checksum is not correct	  
     * '3' : Checksum byte is not available	
     * '2' : Frame Type is not valid
     * '1' : Timeout when receiving answer   
    */
    USB.print(F("Error receiving a packet:"));
    USB.println(error,DEC);     
  }
} 
