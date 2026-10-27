#!/usr/bin/env python3
"""
Author: Greg Chetcuti <greg@chetcuti.com>
Date: 2022-06-12
Purpose: monmon alert script (alert.py)
"""

import configparser
import os.path
import time
from PIL import Image, ImageDraw, ImageFont
from waveshare import LCD_1inch3

alerts_filename = "alerts"
# check.py leaves this file after each run. /run is emptied at every boot, so it's only
# missing until the first check.py run after a boot
checked_filename = "/run/monmon-checked"
config = configparser.ConfigParser()

if os.path.exists("config.custom"):

    config.read("config.custom")

else:

    config.read("config")

polling_interval = int(config["c"]["polling_interval"])
check_text = config["c"]["check_text"]
# Older custom config files don't have starting_text
starting_text = config["c"].get("starting_text", "Starting...")
check_text_colour = config["c"]["check_text_colour"]
startup_colour = config["c"]["startup_colour"]
background_colour = config["c"]["background_colour"]
alert_colour_1 = config["c"]["alert_colour_1"]
alert_colour_2 = config["c"]["alert_colour_2"]

if polling_interval == 0 or polling_interval == "":
    exit()

RST = 27
DC = 25
BL = 18
bus = 0
device = 0

disp = LCD_1inch3.LCD_1inch3()
disp.Init()

image_base = Image.new("RGB", (disp.width, disp.height), startup_colour)
ImageDraw.Draw(image_base)
disp.ShowImage(image_base)
time.sleep(5)
image_base = Image.new("RGB", (disp.width, disp.height), background_colour)
ImageDraw.Draw(image_base)
disp.ShowImage(image_base)
time.sleep(1)

image_base = Image.new("RGB", (disp.width, disp.height), background_colour)
draw_base = ImageDraw.Draw(image_base)

image_warning_1 = Image.new("RGB", (disp.width, disp.height), alert_colour_1)
ImageDraw.Draw(image_warning_1)

image_warning_2 = Image.new("RGB", (disp.width, disp.height), alert_colour_2)
ImageDraw.Draw(image_warning_2)

Font = ImageFont.truetype("waveshare/font/Font00.ttf", 25)


def are_there_alerts(filename):

    return 1 if os.path.isfile(filename) else 0


def show_check_text():

    draw_base.text((50, 95), check_text, font=Font, fill=check_text_colour)
    disp.ShowImage(image_base)
    return


def show_starting_text():

    image_starting = Image.new("RGB", (disp.width, disp.height), background_colour)
    draw_starting = ImageDraw.Draw(image_starting)
    draw_starting.text((63, 95), starting_text, font=Font, fill=check_text_colour)
    disp.ShowImage(image_starting)
    return


def show_waiting_screen():

    image_base_waiting = Image.new("RGB", (disp.width, disp.height), background_colour)
    ImageDraw.Draw(image_base_waiting)
    disp.ShowImage(image_base_waiting)
    time.sleep(polling_interval)
    return


def show_warning():

    ImageDraw.Draw(image_warning_1)
    disp.ShowImage(image_warning_1)
    time.sleep(0.15)

    ImageDraw.Draw(image_warning_2)
    disp.ShowImage(image_warning_2)
    time.sleep(0.15)
    return


# Nothing has been checked yet after a boot until check.py's first run, so keep the
# starting text on the screen until then instead of looking for alerts
if not os.path.isfile(checked_filename):

    show_starting_text()

    while not os.path.isfile(checked_filename):
        time.sleep(1)

while True:

    show_check_text()

    if are_there_alerts(alerts_filename):

        count = 0

        while count <= polling_interval:

            show_warning()
            count += 1

        continue

    else:

        show_waiting_screen()
