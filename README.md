# NES 6-Channel Music Driver

Classic NES music driver originally created by Steven Ruddy with input from Tim Follin and Geoff Follin.

## Overview

The original driver was referred to as a 6-channel system. Although the NES APU physically provides four primary sound channels, the driver implements additional logical channels through channel sharing and control handoffs.

The result is a flexible music playback system capable of handling music and sound effects simultaneously without unnecessarily interrupting music playback.

The code presented here consolidates material from multiple game implementations into one organized, commented, and readable version. The intention is to make the driver easier to explore and understand while preserving its original functionality and design. When understood, the code is very customizable.

## Repository Contents

```text
music_driver.asm   Main 6502 music driver source code, written in ca65 format.
music_data.asm	   Music data definitions and example music data.
ram.asm	           RAM allocation and definitions used by the driver.
nes.cfg	           NES linker configuration for ca65/ld65.
reference.txt	   Detailed reference documentation covering commands, music data, and driver usage.
```

An example tune from Silver Surfer is included to help demonstrate the driver's music data format and playback functionality.

## Music Data Format

Music is represented using a byte-oriented command and note format.

The driver interprets these commands during playback to control notes, timing, pitch effects, and other musical parameters.

The reference.txt document provides a detailed explanation of the available commands, their parameters, and how to use them when creating or modifying music data.

Studying the music data alongside the driver source is a good way to understand how the playback system works.

## Credits

Original Music Driver: Steven Ruddy

Original Input and Contributions: Tim Follin and Geoff Follin

Repository Presentation: Consolidation, organization, and commenting of driver implementations from multiple games into a single educational codebase.

The original authors deserve recognition for the work and techniques behind this music system.
