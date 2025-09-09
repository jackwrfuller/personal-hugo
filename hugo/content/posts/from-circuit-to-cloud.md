+++
authors = ["Jack W R Fuller"]
title = "From circuits to the cloud: hosting IoT data in Lagoon"
date = "2025-09-09"
description = "A journey through every software layer"
tags = [
    "lagoon",
    "embedded",
    "linux",
    "raspberry pi",
    "adafruit"
]
categories = [
    "lagoon",
]
series = ["Lagoon"]
+++

In this article I explain how I used Lagoon, an open-source application delivery platform, to store and deliver temperature and humidity sensor data. 

## Introduction

About a year ago now I was completing a computer organisation course at my local university.
This got me obsessed for a short while with embedded devices and the software associated with it.
Orthogonal to my usual engineering work, it was [this article](https://dri.es/building-my-own-temperature-and-humidity-monitor) by the creator of Drupal, Dries Buytaert, that introduced me to my first IoT project.

In short, Dries built a simple temperature monitoring system based around the [Adafruit Sensirion SHT4x](https://www.adafruit.com/product/5776) sensor.
Dries' solution makes use of an ESP32 microcontroller to read from the sensor, however at that point I already owned everyone's first single-board computer, the Raspberry Pi (model 4B, to be precise).
Rather than purchase an additional component, I figured I could use that instead.

The sensor itself spoke I2C, and Adafruit exposes this via a Qwiic connector.
The Raspberry Pi 4B does not comes support Qwiic out of the box, but it does provide a 40-pin GPIO header.
Using this [Qwiic HAT](https://www.adafruit.com/product/4688) ("Hardware Attached on Top"), we can connect the sensor to the Pi via a [JST 4-pin cable](https://www.adafruit.com/product/4399).
It looks pretty much exactly like this:

{{< portrait width="400" image="/images/sht-to-pi.jpg" alt="SHT4x connected to Raspberry Pi" >}}

In his article, Dries publishes the sensor data to his Drupal website.
I thought, perhaps I can do the same?
However, this opened a bigger can of worms since I didn't yet have a website, nor had I figured out where such a website would be hosted.
This article explains how the entire process I ended up taking.

In short, the workflow looks something like this:

1. Read the sensor data using a hardware driver
2. Post the data to a microservice hosted in Lagoon that stores it
3. Poll the microservice for the data from (for example) my personal website

## Reading the data

At the time when I was first investigating this project, I was doing a lot of systems programming in C for one of my university courses.
This was quite fortunate, as anyone with embedded experience knows that most drivers are written in C.
The Sensirion SHT4x is no exception.
Sensirion helpfully provided an excellent driver called [raspberry-pi-i2c-sht4x](https://github.com/Sensirion/raspberry-pi-i2c-sht4x) that fitted my use case perfectly.
With this in hand, I came up with what I felt was the simplest possible design to get sensor readings up to the internet: a binary that takes a single reading from the sensor, constructs a basic JSON payload, and posts it to the provided endpoint.
This binary could then be run at regular intervals, for example via a cron schedule.

I first defined a basic interface that covered my needs:

```c title="reading.h"
#include <inttypes.h>

typedef struct {
    uint32_t serial_number;
    float temp;
    float humidity;
} Reading;

void takeReading(Reading *);
void printReading(Reading *);
char* readingToJSON(Reading *);
```

Then, following the Sensirion's example program fairly closely, I created the function to read from the sensor:

```c
void takeReading(Reading* reading) {
    int16_t error = NO_ERROR;
    uint32_t serial_number = 0;
    float a_temperature = 0.0;
    float a_humidity = 0.0;
    
    sensirion_i2c_hal_init();
    sht4x_init(SHT40_I2C_ADDR_44);
    sht4x_soft_reset();
    sensirion_i2c_hal_sleep_usec(10000);

    error = sht4x_serial_number(&serial_number);
    if (error != NO_ERROR) {
        printf("error executing serial_number(): %i\n", error);
        return;
    }
    reading->serial_number = serial_number;

    sensirion_i2c_hal_sleep_usec(20000);
    error = sht4x_measure_lowest_precision(&a_temperature, &a_humidity);
    if (error != NO_ERROR) {
        printf("error executing measure_lowest_precision(): %i\n", error);
    }
    reading->temp = a_temperature;
    reading->humidity = a_humidity;
}
```

On reflection, the sleeps are probably not necessary, but the example program used them and it seemed to work, so I didn't think too hard about it at the time.

Next, I had to marshal this data into JSON format.
Considering the simplicity, I should have just created the JSON manually via a `Sprintf()` call.
Younger me, however, decided that a JSON library was called for!
Unlike modern languages, C does not have a defacto module/package system.
I found this "ultralightweight JSON parser in ANSI C" called [cJSON](https://github.com/DaveGamble/cJSON).
The cool thing about this library is that it is contained entirely within one C and one header file, meaning that linking it in my makefile was dead simple.

My overengineered marshalling function used it as follows:

```c 

/*
 * Construct a JSON string representation of a Reading struct.
 *
 * Return char* must be deallocated by function caller.
 */
char* readingToJSON(Reading* reading) {
    char* json_string;
    cJSON* temp;
    cJSON* humidity;

    cJSON* reading_json = cJSON_CreateObject();
    
    temp = cJSON_CreateNumber(reading->temp);
    humidity = cJSON_CreateNumber(reading->humidity);

    cJSON_AddItemToObject(reading_json, "temp", temp);
    cJSON_AddItemToObject(reading_json, "humidity", humidity);

    json_string = cJSON_PrintUnformatted(reading_json);

    cJSON_Delete(reading_json);
    
    return json_string;
};
```

## Storing the data


## Showing the data
