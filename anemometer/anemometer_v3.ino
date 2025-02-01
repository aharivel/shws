#include "OneWire.h"
#include "DallasTemperature.h"
#include "gButton.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1 

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);
OneWire oneWire(A1);
DallasTemperature ds(&oneWire);

gButton myButton(3);

int pin = 6;
int led1 = 4;
int max_temp = 0;
float max_vitesse = 0;
int etatPrecedent;
float duration_H, duration_L, FHz, Period, vitesse;
#define Perimetre 0.520 

char screen = 0;

void setup() {
    ds.begin();
    display.begin(SSD1306_SWITCHCAPVCC, 0x3C);
    delay(500);
    display.clearDisplay();
    display.setTextColor(WHITE);
    
    Serial.begin(115200);

    pinMode(pin, INPUT);
    pinMode(led1, OUTPUT);
    pinMode(8, INPUT); // Ensure pin 8 is an input

    myButton.begin();
    etatPrecedent = digitalRead(8);
}

void loop() {
    ds.requestTemperatures();
    int t = ds.getTempCByIndex(0);
    
    duration_H = pulseInLong(pin, HIGH, 100000);
    duration_L = pulseInLong(pin, LOW, 100000);

    if (duration_H == 0 || duration_L == 0) {
        vitesse = 0;
    } else {
        Period = (duration_H + duration_L) / 1000000.0;
        FHz = 1.0 / Period;
        vitesse = Perimetre * FHz * 3.6;
    }

    if (t > max_temp) max_temp = t;
    if (vitesse > max_vitesse) max_vitesse = vitesse;

    if (myButton.down()) {
        screen++;
    }

    if (t <= 3) {
        digitalWrite(led1, LOW);
    } else {
        digitalWrite(led1, HIGH);
    }

    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(0, 0);
    display.print("Temp: ");
    display.print(t);
    display.println(" C");

    display.print("Speed: ");
    display.print(vitesse);
    display.println(" km/h");

    display.display();
}

