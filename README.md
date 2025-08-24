# monmon - Monitor your monitoring with a Raspberry Pi

- [What is monmon and what does it do?](#what-is-monmon-and-what-does-it-do)
- [Why did you create monmon?](#why-did-you-create-monmon)
- [See monmon in action](#see-monmon-in-action)
- [Supported Providers](#supported-providers)
- [Requirements](#requirements)
- [Tools](#tools)
- [Installation Types](#installation-types)
- [Installation](#installation)
- [Configuration Files](#configuration-files)
  * [Node File](#node-file)
  * [monmon Configuration File](#monmon-configuration-file)
  * [Monit Configuration File](#monit-configuration-file)
- [Node File Formats & Examples](#node-file-formats--examples)
  * [Healthchecks.io](#healthchecksio)
  * [Monit](#monit)
  * [Uptime Kuma](#uptime-kuma)
  * [UptimeRobot](#uptimerobot)
- [Sample Node File](#sample-node-file)
- [License](#license)

# What is monmon and what does it do?

monmon is a simple [Raspberry Pi][]-based monitoring tool that keeps an eye on your existing
monitoring systems and lets you know if any of your nodes need attention. If there's an
issue, the screen attached to your Raspberry Pi will start to flash. Optionally, you can
connect an HDMI display to the Pi and have it show the monmon status page.

monmon connects to your existing monitoring systems (*see the list of Supported Providers
below*), and checks to see if there are any issues, anywhere, if the there are, the
annoying flashing begins! Did one of your cron jobs fail to run? ***FLASH*** Is one of
your servers having a significant issue with RAM? ***FLASH*** Is one of your external
web servers down? ***FLASH*** It's both annoying **and** functional!

That's it, that's the entire point of monmon, to tell you if any of your existing
monitoring systems is reporting an issue, in a very simple but useful manner.

# Why did you create monmon?

I recently switched to [Monit][] to keep tabs on my servers, and although I really like the
idea of [M/Monit][], a paid product that lets you monitor all of your Monit instances in one
place (as well as giving you extended functionality), I just couldn't justify the cost.
So I set out to create my own super lightweight M/Monit alternative, one that would
simply alert me of any issues with my Monit instances, and then I could click though on
the monmon status page to the Monit Web UI and see what the actual issue is. Not long
after, monmon was born.

Since then I've added support for both Healthchecks.io, Uptime Kuma, and UptimeRobot, and I'll be
adding other monitoring systems as time goes on.

# See monmon in action

_Ignore the video quality, it's absolutely awful!_

[![monmon in action](https://i.imgur.com/nljuHLF.png)](https://i.imgur.com/mG9j8Hc.mp4 "monmon in action")

# Supported Providers
- [Healthchecks.io][] (hch)
- [Monit][] (mnt)
- [Uptime Kuma][] (upk)
- [UptimeRobot][] (upr)

# Requirements
- Raspberry Pi
  - monmon has been tested with the below Raspberry Pis, but I believe it should work with any
  - 4 Model B Rev 1.1
  - 3 Model B Plus Rev 1.3
  - Zero 2 W Rev 1.0
  - Zero W Rev 1.1 (_this is what I personally use for monmon_)
- Raspberry Pi Parts
  - 16+ GB SD Card 
  - Power cable
  - Headers (if you're using a Pi Zero that doesn't have existing headers)
- [Raspberry Pi OS Lite 32-bit ISO image][]
  - [Waveshare 1.3" LCD Hat][]

# Tools
  - Soldering iron, solder, etc.
  - The ability to solder (hellooo YouTube!)
  - If you don't want to solder, you could also look into hammer headers

# Installation Types
1) Flashing Waveshare 1.3" LCD  
***or***
2) External HDMI Display (CLI or GUI)  
   -- The CLI method uses the lynx text-based web browser  
   -- The GUI method uses the Midori web browser within the PIXEL desktop environment  
***or***
3) Both  
***or***
4) Neither
   - But then, you know, what's the point?

# Installation
- Flash Raspberry Pi OS lite 32-bit onto an SD card of at least 16GB
  - Must use pi / raspberry credentials
  - You can probably use other operating systems, but this is all that's been fully
  tested. The 64-bit version of Raspberry Pi OS should also work, though its performance
  on a Raspberry Pi Zero was not great. 
- Run from anywhere: `git clone https://github.com/gregdotca/monmon.git`
- Change into the monmon folder
- At the very least you should now create a custom Node file, but you can also create
custom monmon and Monit configuration files if you want to. See further down in the 
README for more information.
- If you don't create a custom Node file, the only node that will be monitored is the
instance of Monit running on your monmon Raspberry Pi, so it won't be very useful.
- Run: `./install.sh` and follow the prompts
  - **NOTE:** The installation process needs [Ansible][] installed on the local system (the
  one you cloned the git repository to), as the entire monmon system is installed and
  setup using Ansible. You don't need to install Ansible on your own though, the install
  script will do that for you, though if the Ansible installation fails you may need to
  [install it manually][].
- Further information will be given on-screen after the installation is complete

# Configuration Files

**NOTE:** The configuration files need to be created **before** you install monmon. Then
when you run the install.sh script and Ansible deploys monmon to your Raspberry Pi, your
configuration files will be deployed as well.

monmon is configured using three configuration files. A Node file, a monmon
configuration file, and a Monit configuration file. The Node file is where you list your
different monitoring systems, one per line. The default Node file will monitor nothing but
the Monit instance that runs on your monmon Raspberry Pi, so creating a custom Node file
is pretty much mandatory if you want to get any real use out of monmon.

The other two files have sane defaults, so you only need custom monmon configuration and
Monit configuration files if you need to customize something specific.

The monmon configuration file lets you set things like the colour of the LCD when
it flashes, or change the default polling interval. The Monit configuration file lets
you completely customize the Monit instance that runs on your monmon Raspberry Pi.

## Node File
If you would like to use a custom Node file, you should create a copy of the default
node file and then modify it accordingly.

Default File: *ansible/roles/monmon/templates/nodes.j2*

You should copy this file to a file called *nodes* in the main monmon folder. To do
this you can run the below command.

`cp ansible/roles/monmon/templates/nodes.j2 ./nodes`

## monmon Configuration File
If you would like to use a custom monmon configuration, you should create a copy of the
default monmon configuration file and then modify it accordingly.

Default File: *ansible/roles/monmon/templates/config.j2*

You should copy this file to a file called *config* in the main monmon folder. To do
this you can run the below command.

`cp ansible/roles/monmon/templates/config.j2 ./config`

## Monit Configuration File
If you would like to use a custom Monit configuration, you should create a copy of the
default Monit configuration file and then modify it accordingly.

Default File: *ansible/roles/monit/templates/monit.j2*

You should copy this file to a file called *monit* in the main monmon folder. To do this
you can run the below command.

`cp ansible/roles/monit/templates/monit.j2 ./monit`

# Node File Formats & Examples

## Healthchecks.io 
Format: ***TYPE:::::LABEL:::::BASE HEALTHCHECKS.IO URL:::::API KEY***  
Example: hch:::::Backups, Local (to Gitea):::::https://healthchecks.example.com:::::kd993jflsl33nfid88jfo32lksdjslf3

**NOTE:** Healthchecks.io does not have an account-wide API Key, so an API key will
need to be generated for each project group that you want to monitor.

## Monit  
Format: ***TYPE:::::LABEL:::::BASE MONIT URL:::::MONIT UI USERNAME:::::MONIT UI PASSWORD***  
Example: mnt:::::monit.example.com:::::https://monit.example.com:2812:::::username:::::password

## Uptime Kuma  
Format: ***TYPE:::::LABEL:::::BASE UK URL:::::UK UI USERNAME:::::UK UI PASSWORD***  
Example: upk:::::Uptime Kuma Self-Hosted:::::https://uptimekuma.example.com:::::username:::::password

## UptimeRobot  
Format: ***TYPE:::::LABEL:::::API KEY***  
Example: upr:::::Main UptimeRobot Account:::::dj3fsjh8df-kdk993ijkosf8838kskdldkdk38

# Sample Node File
hch:::::Backups, Local (to Gitea):::::https://healthchecks.example.com:::::kd993jflsl33nfid88jfo32lksdjslf3  
mnt:::::monit.example.com:::::https://monit.example.com:2812:::::username:::::password  
upk:::::Uptime Kuma Self-Hosted:::::https://uptimekuma.example.com:::::username:::::password  
upr:::::Main UptimeRobot Account:::::dj3fsjh8df-kdk993ijkosf8838kskdldkdk38

# License
monmon -- Monitor your monitoring with a Raspberry Pi  
Copyright (c) 2024 Greg Chetcuti <greg@chetcuti.com>

monmon is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

monmon is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with monmon. If not, see <http://www.gnu.org/licenses/>.

[Ansible]: https://www.ansible.com
[Healthchecks.io]: https://healthchecks.io
[install it manually]: https://docs.ansible.com/ansible/latest/installation_guide/index.html
[M/Monit]: https://mmonit.com
[Monit]: https://mmonit.com/monit/
[Raspberry Pi OS Lite 32-bit ISO image]: https://www.raspberrypi.com/software/
[Raspberry Pi]: https://www.raspberrypi.org
[Uptime Kuma]: https://uptime.kuma.pet
[UptimeRobot]: https://uptimerobot.com
[Waveshare 1.3" LCD Hat]: https://www.waveshare.com/wiki/1.3inch_LCD_HAT
