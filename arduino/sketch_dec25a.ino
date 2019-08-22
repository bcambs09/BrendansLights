#include <LiquidCrystal.h>
#include <SPI.h>
#include <WiFi.h>
#include <string.h>

#define RED_LED 6
#define BLUE_LED 10
#define GREEN_LED 9

char ssid[] = "My_WiFi"; //  your network SSID (name)
char pass[] = "My_Passwords";    // your network password (use for WPA, or use as key for WEP)

int status = WL_IDLE_STATUS;

WiFiServer server(7500);

int brightness = 255;

int gBright = 0;
int rBright = 0;
int bBright = 0;

int fadeSpeed = 10;

const int rs = 12, en = 11, d4 = 5, d5 = 4, d6 = 3, d7 = 2;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

unsigned long curr_time;
unsigned long last_time;

void printWifiStatusToLCD() {
  lcd.clear();
  if (status == WL_CONNECTED){
    lcd.print(WiFi.localIP());
    lcd.setCursor(0,1);
    lcd.print(WiFi.RSSI());
    lcd.print(" dBm");
  }else{
    lcd.print("Error connecting");
  }
}

void printWifiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print the received signal strength:
  long rssi = WiFi.RSSI();
  Serial.print("signal strength (RSSI):");
  Serial.print(rssi);
  Serial.println(" dBm");
  
  if (status == WL_CONNECTED){
    Serial.println("Connected");
  }else{
    Serial.println("Error");
  }
}

void setup() {
  //Initialize serial and wait for port to open:
  Serial.begin(9600);
  last_time = millis();
  // set up the LCD's number of columns and rows:
  lcd.begin(16, 2);
  // Print a message to the LCD.
  lcd.setCursor(0,0);
  lcd.print("Brendan's Lights");

  // check for the presence of the shield:
  if (WiFi.status() == WL_NO_SHIELD) {
    Serial.println("WiFi shield not present");
    // don't continue:
    while (true);
  }

  String fv = WiFi.firmwareVersion();
  if (fv != "1.1.0") {
    Serial.println("Please upgrade the firmware");
  }

  // attempt to connect to Wifi network:
  if (status != WL_CONNECTED) {
    Serial.print("Attempting to connect to SSID: ");
    Serial.println(ssid);
    // Connect to WPA/WPA2 network. Change this line if using open or WEP network:
    status = WiFi.begin(ssid, pass);

    // wait 10 seconds for connection:
    delay(10000);
  }
  
  // start the server:
  server.begin();
  // you're connected now, so print out the status:
  printWifiStatus();
  printWifiStatusToLCD();
  
  pinMode(GREEN_LED, OUTPUT);
  pinMode(RED_LED, OUTPUT);
  pinMode(BLUE_LED, OUTPUT);
}

void TurnOn() { 
   for (int i = 0; i < 256; i++) {
       analogWrite(RED_LED, rBright);
       rBright +=1;
       delay(fadeSpeed);
   }
 
   for (int i = 0; i < 256; i++) {
       analogWrite(BLUE_LED, bBright);
       bBright += 1;
       delay(fadeSpeed);
   } 

   for (int i = 0; i < 256; i++) {
       analogWrite(GREEN_LED, gBright);
       gBright +=1;
       delay(fadeSpeed);
   } 
}

void TurnOff() {
   for (int i = 0; i < 256; i++) {
       analogWrite(GREEN_LED, brightness);
       analogWrite(RED_LED, brightness);
       analogWrite(BLUE_LED, brightness);
 
       brightness -= 1;
       delay(fadeSpeed);
   }
}

void loop() {
  // printWifiStatus();
  curr_time = millis();
  if(curr_time - last_time >= 2000){
    printWifiStatusToLCD();
    last_time = curr_time;
  }
  
  WiFiClient client = server.available();

  // when the client sends the first byte, say hello:
  if (client) {
    char msg[16];
    for(int i = 0; i < 16; ++i){
      msg[i] = 0;
    }
    char* mode;
    int len = 0;
    while (client.available() > 0) {
      // read the bytes incoming from the client:
      char thisChar = client.read();
      msg[len] = thisChar;
      len += 1;
      // End of request
      if(thisChar == '\n'){
        //Serial.write('\n');
        client.flush();
        break;
      }else{
        //Serial.write(thisChar);
      }
    }
    mode = strtok(msg, " \n");
    if(!strcmp(mode, "w")){
      //Serial.println("Changing color.");
      int red, green, blue;
      red = atoi(strtok(NULL, " \n"));
      green = atoi(strtok(NULL, " \n"));
      blue = atoi(strtok(NULL, " \n"));
      analogWrite(RED_LED, red);
      analogWrite(GREEN_LED, green);
      analogWrite(BLUE_LED, blue);
    }
  }
}
