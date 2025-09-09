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

## Reading the data
