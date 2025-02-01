#include "OneWire.h"
#include "DallasTemperature.h"
#include "gButton.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels
// Declaration for an SSD1306 display connected to I2C (SDA, SCL pins)
#define OLED_RESET     -1 // Reset pin # (or -1 if sharing Arduino reset pin)
//#define SCREEN_ADDRESS 0x3C ///< See datasheet for Address; 0x3D for 128x64, 0x3C for 128x32
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
OneWire oneWire(A1);
DallasTemperature ds(&oneWire);

// No external pull-up resistor needed
gButton myButton(3); // Pin D3

int pin = 6; // entrée du capteur effet Hall
int led1 = 4;
int max_temp = 0;
float max_vitesse = 0;
int etatPrecedent;
float duration_H;  // Microsecondes
float duration_L;  // Microsecondes
float FHz;
float Period;
float vitesse;
#define Perimetre 0.520 // Perimetre en metre
char screen  = 0;

void setup()
{
  ds.begin();
  display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
  delay(500);
  display.clearDisplay();
  display.setTextColor(WHITE);
  Serial.begin(115200); //Initialize serial port
  etatPrecedent = digitalRead(8);
  //led1=LOW;
  pinMode(pin, INPUT);
  pinMode(led1, OUTPUT);
  myButton.begin();
}

void loop()
{
  ds.requestTemperatures();
  int t = ds.getTempCByIndex(0);
  int etat,delai;
  //char screen  = 0;

  etat = digitalRead(6);
  //digitalWrite(13,etat);

  duration_H = pulseInLong(pin, HIGH);
  duration_L = pulseInLong(pin, LOW);
  Period = (duration_H + duration_L) / 1000000 ; // en seconde
  FHz = 1 / Period;
  vitesse = Perimetre * FHz * 3.6; // Km/h
   if (vitesse <= 2) {
    vitesse = 0;}
    // Check if button pressed
  if (myButton.down()){
	  screen ++;Anemometre_Period_Ant_2
  }

  // Check if temp min is reached
  if (t <= 3) { digitalWrite (led1, LOW);}
  else {digitalWrite (led1, HIGH);}

  // Check if temp max is reached
  if (t > max_temp) {
	  max_temp = t;
  }

  // Check if vitesse max is reached
  if (vitesse > max_vitesse) {
	  max_vitesse = vitesse;
  }

  switch (screen)
  {
	 case 0:
		//clear display
		display.clearDisplay();
		display.setTextSize(2);
		display.setCursor(4, 0);
		display.print("Anemo-Temp");
		display.setCursor(0, 20); //oled display
		display.setTextSize(2);
		display.println(t);

		display.setCursor(60, 20); //oled display
		display.setTextSize(2);
		display.println("deg C");

		display.setCursor(0, 45); //oled display
		display.setTextSize(2);
		display.print(ceil(vitesse));
		display.setCursor(70, 45);
		display.setTextSize(2);
		display.println("Km/h");
		display.display();
    
      break; 
      
	case 1:
		//clear display
		display.clearDisplay();
		display.setTextSize(2);
		display.setCursor(4, 0);
		display.print("Maximum");
		display.setCursor(0, 20); //oled display
		display.setTextSize(2);
		display.println(max_temp);

		display.setCursor(60, 20); //oled display
		display.setTextSize(2);
		display.println("deg C");

		display.setCursor(0, 45); //oled display
		display.setTextSize(2);
		display.print(max_vitesse);
		display.setCursor(70, 45);
		display.setTextSize(2);
		display.println("Km/h");
		display.display();
    
      break;
	  default:
		screen = 0;
     break;
  }

  //Serial.println(vitesse);
  delay(300);
}
