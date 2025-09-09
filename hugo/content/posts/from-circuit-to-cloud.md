+++
authors = ["Jack W R Fuller"]
title = "From Circuit to Cloud: Hosting IoT Data in Lagoon"
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


## Storing the data


## Showing the data
