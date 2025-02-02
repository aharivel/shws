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

int pin = 6; // Hall effect sensor
int led1 = 4;
int max_temp = 0;
float max_vitesse = 0;
int etatPrecedent;
float duration_H, duration_L, FHz, Period, vitesse;
#define Perimetre 0.520 // Circumference in meters

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
    pinMode(8, INPUT); // Ensure pin 8 is set as input

    myButton.begin();
    etatPrecedent = digitalRead(8);
}

void loop() {
    ds.requestTemperatures();
    int t = ds.getTempCByIndex(0);
    int etat = digitalRead(pin);

    // Measure frequency from Hall sensor
    duration_H = pulseInLong(pin, HIGH, 100000); // 100ms timeout
    duration_L = pulseInLong(pin, LOW, 100000);

    if (duration_H == 0 || duration_L == 0) {
        vitesse = 0; // No valid pulse detected
    } else {
        Period = (duration_H + duration_L) / 1000000.0;
        FHz = 1.0 / Period;
        vitesse = Perimetre * FHz * 3.6; // Convert to Km/h
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

    switch (screen) {
        case 0:
            display.clearDisplay();
            display.setTextSize(2);
            display.setCursor(4, 0);
            display.print("Anemo-Temp");
            display.setCursor(0, 20);
            display.println(t);
            display.setCursor(60, 20);
            display.println("deg C");
            display.setCursor(0, 45);
            display.print(ceil(vitesse));
            display.setCursor(70, 45);
            display.println("Km/h");
            break;

        case 1:
            display.clearDisplay();
            display.setTextSize(2);
            display.setCursor(4, 0);
            display.print("Maximum");
            display.setCursor(0, 20);
            display.println(max_temp);
            display.setCursor(60, 20);
            display.println("deg C");
            display.setCursor(0, 45);
            display.print(max_vitesse);
            display.setCursor(70, 45);
            display.println("Km/h");
            break;

        default:
            screen = 0;
            break;
    }

    display.display(); // Only update once after switch-case
    delay(300);
}

