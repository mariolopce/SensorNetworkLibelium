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
//char HOST[]        = "http://mqtt.te.upm.es/"; //MQTT Broker
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
float temperature, x_acc, y_acc, z_acc, humidity, pressure;

char temp_string[10]; // Make sure this is large enough to hold your float
char x_string[10];
char y_string[10];
char z_string[10];
char pressure_string[10];
char humidity_string[10];

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

      connectWifi();
      unsigned char payload[100];
      snprintf((char *)payload, 100, "field1=%d&status=MQTTPUBLISH", 1);
      sendDataMQTT((char *)"channels/2428994/publish", payload);
      Utils.setLED(LED0, LED_OFF);



      
    }
    else if (strcmp((char*)xbee802._payload, "Alarm: Motion detected") == 0){


      connectWifi();
      unsigned char payload[100];
      snprintf((char *)payload, 100, "field2=%d&status=MQTTPUBLISH", 1);
      sendDataMQTT((char *)"channels/2428994/publish", payload);
      Utils.setLED(LED0, LED_OFF);

      
    

    }
    else{
      
      sscanf( (const char*) xbee802._payload, "%s %s %s %d %s %s %s", temp_string, humidity_string, pressure_string, &battery, x_string, y_string, z_string);
      //sscanf( (const char*) xbee802._payload, "%d %d %d %s", 1, 2, 3, "hola");
      Utils.setLED(LED1, LED_ON);
      temperature = atof(temp_string);
      humidity = atof(humidity_string);
      pressure = atof(pressure_string);
      x_acc = atof(x_string);
      y_acc = atof(y_string);
      z_acc = atof(z_string);
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
      
      
      
      // Show data stored in '_payload' buffer indicated by '_length'
      USB.print(F("Length: "));  
      USB.println( xbee802._length,DEC); //print the usefull data of the buffer, which is the buffer elemets among the length
      Utils.setLED(LED1, LED_OFF);
      ciclo++;
  
  
      connectWifi();
      unsigned char payload[100];
      
      snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&status=MQTTPUBLISH", int(temp_gateway), int(humidity_gateway), long(pressure_gateway), PWR.getBatteryLevel());
      sendDataMQTT((char *)"channels/2422894/publish", payload);
  
       snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&status=MQTTPUBLISH", int(temperature), int(humidity), long(pressure), battery);
      sendDataMQTT((char *)"channels/2428811/publish", payload);
  
      snprintf((char *)payload, 100, "field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(x_gateway), int(y_gateway), int(z_gateway));
      sendDataMQTT((char *)"channels/2422894/publish", payload);
 
      snprintf((char *)payload, 100, "field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(x_acc), int(y_acc), int(z_acc));
      sendDataMQTT((char *)"channels/2428811/publish", payload);
      Utils.setLED(LED0, LED_OFF);
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




void connectWifi(){
  Utils.setLED(LED0, LED_ON);
     //////////////////////////////////////////////////
  // 1. Switch ON
  //////////////////////////////////////////////////
  error = WIFI_PRO.ON(socket);

  if ( error == 0 ){
    USB.println(F("1. WiFi switched ON"));
  }else{
    USB.println(F("1. WiFi did not initialize correctly"));
  }
    //////////////////////////////////////////////////
  // 2. Check if connected
  ////////////////////////////////////////////////// 
    
  // get actual time
  previous = millis();

  // check connectivity
  status =  WIFI_PRO.isConnected();

  // check if module is connected
  if ( status == true ){
    USB.print(F("2. WiFi is connected OK"));
    USB.print(F(" Time(ms):"));
    USB.println(millis() - previous);

    // get IP address
    error = WIFI_PRO.getIP();

    if (error == 0){
      USB.print(F("IP address: "));
      USB.println( WIFI_PRO._ip );
    }else{
      USB.println(F("getIP error"));
    }
  }else{
    USB.print(F("2. WiFi is connected ERROR"));
    USB.print(F(" Time(ms):"));
    USB.println(millis() - previous);
  }



}

void sendDataMQTT(char* topic, unsigned char payloadd[]){

  
  //////////////////////////////////////////////////
  // 3. TCP
  //////////////////////////////////////////////////

  // Check if module is connected
  if (status == true){

    ////////////////////////////////////////////////
    // 3.1. Open TCP socket
    ////////////////////////////////////////////////
    error = WIFI_PRO.setTCPclient( HOST, REMOTE_PORT, LOCAL_PORT);

    // check response
    if (error == 0){
      // get socket handle (from 0 to 9)
      socket_handle = WIFI_PRO._socket_handle;

      USB.print(F("3.1. Open TCP socket OK in handle: "));
      USB.println(socket_handle, DEC);
    }else{
      USB.println(F("3.1. Error calling 'setTCPclient' function"));
      WIFI_PRO.printErrorCode();
      status = false;
    }
  }

  if (status == true)
  {
    /// Publish MQTT
    MQTTPacket_connectData data = MQTTPacket_connectData_initializer;
    MQTTString topicString = MQTTString_initializer;
    unsigned char buf[200];
    int buflen = sizeof(buf);
    //unsigned char payload[100];

    // options
    data.clientID.cstring = (char*)"FCEpCQUHESInLQohNxsiAio";
    data.password.cstring = (char*)"+/Y4P8d/ZpSi/KeI0XXJ+O/H";
    data.username.cstring = (char*)"FCEpCQUHESInLQohNxsiAio";
    data.keepAliveInterval = 30;
    data.cleansession = 1;
    int len = MQTTSerialize_connect(buf, buflen, &data); /* 1 */

    // Topic and message
    topicString.cstring = topic;

    int payloadlen = strlen((const char*) payloadd);
    len += MQTTSerialize_publish(buf + len, buflen - len, 0, 0, 0, 0, topicString, payloadd, payloadlen); /* 2 */

    len += MQTTSerialize_disconnect(buf + len, buflen - len); /* 3 */


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
