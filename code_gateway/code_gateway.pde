/*  
 *  ------ Code for the gateway-------- 
 *  
 *  Explanation: This program receives the data transmitted by
 *  the end device. It saves each of the values. It also measures
 *  all the properties measured in the end device too. Each time
 *  a message containing the data from the end device is received,
 *  the gateway performs its measurements and publishes in the
 *  Thingspeak server both values.
 *  If alarms are received from the end device, they are autoatically
 *  published.
 *  
 *  Group:              Red 
 *  Implementation:     Mario López Cea
 *                      Jesús Mayordomo García
 *                      Kimiya Shabani
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

// Socket 1 selected
///////////////////////////////////////
uint8_t socket = SOCKET1;
///////////////////////////////////////


// choose TCP server settings
///////////////////////////////////////
char HOST[]        = "mqtt3.thingspeak.com"; //Thingspeak MQTT Broker used
char REMOTE_PORT[] = "1883";  //MQTT
char LOCAL_PORT[]  = "3000";
///////////////////////////////////////

// define variables
uint8_t error;
uint8_t status;

unsigned long previous;
uint16_t socket_handle = 0;

uint16_t ciclo = 0;

char buffer[100];

// Variables used to save the measurements performed by the gateway
/////////////////////////
int temp_gateway; 
int x_gateway;
int y_gateway;
int z_gateway;
float pressure_gateway;
float humidity_gateway;
/////////////////////////

// Variables used to save the measurements received from the end device
/////////////////////////////////////////////////////////////
int battery;
float temperature, x_acc, y_acc, z_acc, humidity, pressure;
char temp_string[10]; 
char x_string[10];
char y_string[10];
char z_string[10];
char pressure_string[10];
char humidity_string[10];
//////////////////////////////////////////////////////////////

void setup()
{  
  // init USB port
  USB.ON();
  USB.println(F("Gateway"));
  ACC.ON();

  // init XBee to receive data from end device 
  xbee802.ON();
}


void loop()
{ 
  // receive XBee packet (wait for 10 seconds)
  error = xbee802.receivePacketTimeout( 10000 );

  // check answer
  // if message correctly received, payload is saved  
  if( error == 0 ) 
  {
    
    USB.print(F("Data: "));  
    USB.println( xbee802._payload, xbee802._length);  //Printed payload and length of the payload buffer

    //  Check which message is received from the end device
    //  MESSAGE 1:  Free fall alarm
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////// 
    if (strcmp((char*)xbee802._payload, "Alarm: Free fall detected") == 0){

      connectWifi();                                                      // connect to the Wi-Fi
      unsigned char payload[100];
      snprintf((char *)payload, 100, "field1=%d&status=MQTTPUBLISH", 1);  // Payload = 1 to field1
      sendDataMQTT((char *)"channels/2428994/publish", payload);          // Publish to the topic in which alarms are shown
      Utils.setLED(LED0, LED_OFF);                                        // Set LED to OFF
 
    }
      //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //  MESSAGE 2: Movement alarm
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    else if (strcmp((char*)xbee802._payload, "Alarm: Motion detected") == 0){

      connectWifi();                                                        // connect to the Wi-Fi
      unsigned char payload[100];
      snprintf((char *)payload, 100, "field2=%d&status=MQTTPUBLISH", 1);    // Payload = 1 to field2
      sendDataMQTT((char *)"channels/2428994/publish", payload);            // Publish to the topic in which alarms are shown
      Utils.setLED(LED0, LED_OFF);

    }
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
      
    //  MESSAGE 3: Sensor data
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    else{
      
      sscanf( (const char*) xbee802._payload, "%s %s %s %d %s %s %s", temp_string, humidity_string, pressure_string, &battery, x_string, y_string, z_string); // Sensor values saved
      Utils.setLED(LED1, LED_ON);         // Green LED to ON to advertise that measures are starting
      
      // Values received are transformed from strings to floats
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
  
      //Get temperature
      temp_gateway = Events.getTemperature();
      //Get humidity
      humidity_gateway = Events.getHumidity();
      //Get pressure
      pressure_gateway = Events.getPressure();
  
      //----------X Value-----------------------
      x_gateway = ACC.getX();
    
      //----------Y Value-----------------------
      y_gateway = ACC.getY();
    
      //----------Z Value-----------------------
      z_gateway = ACC.getZ();
    
      //-------------------------------
      
      // Lenth of the payload is displayed
      USB.print(F("Length: "));  
      USB.println( xbee802._length,DEC);
      Utils.setLED(LED1, LED_OFF);  // Measuring finished, green LED OFF
      ciclo++;
  
      // Connect to Wi-Fi
      connectWifi();
      unsigned char payload[100];

      // Publish in gateway topic the temperature, humidity, pressure and battery level measured by the gateway
      snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&status=MQTTPUBLISH", int(temp_gateway), int(humidity_gateway), long(pressure_gateway), PWR.getBatteryLevel());
      sendDataMQTT((char *)"channels/2422894/publish", payload);

      // Publish in end device topic the temperature, humidity, pressure and battery level measured by the end device
       snprintf((char *)payload, 100, "field1=%d&field2=%d&field3=%ld&field4=%d&status=MQTTPUBLISH", int(temperature), int(humidity), long(pressure), battery);
      sendDataMQTT((char *)"channels/2428811/publish", payload);

      // Publish in gateway topic the three axes of the accelerometer measured by the gateway
      snprintf((char *)payload, 100, "field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(x_gateway), int(y_gateway), int(z_gateway));
      sendDataMQTT((char *)"channels/2422894/publish", payload);

      // Publish in end device topic the three axes of the accelerometer measured by the gateway
      snprintf((char *)payload, 100, "field5=%d&field6=%d&field7=%d&status=MQTTPUBLISH", int(x_acc), int(y_acc), int(z_acc));
      sendDataMQTT((char *)"channels/2428811/publish", payload);
      
      Utils.setLED(LED0, LED_OFF);  // Transmission finished, red LED to OFF
    }
      ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
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



/*  
 *  ------ Function to stablish the connection with the Wi-Fi -------- 
 *  The module has to be previously configured with the ID nad password of the WiFi usedm
 *  This function switches on the WiFi and check if the voard is connected
 */
void connectWifi(){
  Utils.setLED(LED0, LED_ON); // Measuring started, set green LED to ON
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

/*  
 *  ------ Function to publish a message in the MQTT broker-------- 
 *  Inputs:
 *    topic: topic in which is going to be published the message
 *    payloadd: message which is going to be transmitted
 */
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

    // Stablish ID, password and username of the MQTT device of Thingspeak
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
