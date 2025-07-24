# LazyFirmware
A one-click solution for lazy people to upgrade 3D printer mainboard MCU Klipper firmware

## Usage Guide

### 1. Download LazyFirmware
```
cd ~
git clone https://github.com/Samuel-0-0/LazyFirmware
```

### 2. Install Dependencies
```
pip3 install pyserial
```

### 3. Configure config.cfg File
```
mkdir ${HOME}/printer_data/config/lazyfirmware
touch ${HOME}/printer_data/config/lazyfirmware/config.cfg
```
Edit the config.cfg file with content similar to this example:
```
# Global config
[global]
can_interface=can0
language=en

# MCU config
[EBB]
ID=c5360983cdc4
MODE=CAN
CONFIG=/home/samuel/LazyFirmware/config/btt-ebb-g0/can_1m.config

[M8P]
ID=962b136468fc
MODE=CAN_BRIDGE_KATAPULT
CONFIG=/home/samuel/LazyFirmware/config/btt-manta-m8p-h723/can_bridge_1m.config
KATAPULT_SERIAL=/dev/serial/by-id/usb-katapult_stm32h723xx_38000A001851313434373135-if00

[HOST]
ID=NULL
MODE=HOST
CONFIG=/home/samuel/LazyFirmware/config/linux_process/linux.config

#[OCTOPUS_PRO]
#ID=fea6ca620740
#MODE=CAN_BRIDGE_DFU
#CONFIG=/home/samuel/LazyFirmware/config/btt-octopus-pro-f446/can_bridge_1m.config

#[OCTOPUS_PRO]
#ID=/dev/serial/by-id/usb-Klipper_stm32...
#MODE=USB_DFU
#CONFIG=/home/samuel/LazyFirmware/config/btt-octopus-pro-f446/usb.config

#[OCTOPUS_PRO]
#ID=/dev/serial/by-id/usb-Klipper_stm32...
#MODE=USB_KATAPULT
#CONFIG=/home/samuel/LazyFirmware/config/btt-octopus-pro-f446/usb.config
#KATAPULT_SERIAL=/dev/serial/by-id/usb-katapult_stm32...

```
Configuration Item Explanation
```
[Board Name]
ID= Board UUID or /dev/serial/by-id/* path (for host use NULL)
    How to obtain:
    - For USB-connected boards with Klipper firmware communication interface as USB:
      Use command: ls /dev/serial/by-id/*
    - For CAN or CAN_BRIDGE firmware:
      Use command: ~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0

MODE= Select one from CAN/USB_DFU/USB_KATAPULT/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT/HOST:
     - CAN: Board connected via CAN bus, Klipper firmware communication interface is CAN,
           BootLoader is katapult, and katapult was compiled with CAN communication interface selected;
     - USB_DFU: Board connected via USB, Klipper firmware communication interface is USB,
           BootLoader is official;
     - USB_KATAPULT: Board connected via USB, Klipper firmware communication interface is USB,
           BootLoader is katapult, and katapult was compiled with USB communication interface selected;
     - CAN_BRIDGE_DFU: Board connected via USB, Klipper firmware communication interface is USB to CAN bus bridge,
           BootLoader is official;
     - CAN_BRIDGE_KATAPULT: Board connected via USB, Klipper firmware communication interface is USB to CAN bus bridge,
           BootLoader uses katapult, and katapult was compiled with USB communication interface selected;
     - HOST: Host computer;

CONFIG= Path to the klipper firmware configuration file. Cannot start with ~/, must use absolute path like /home/biqu/
KATAPULT_SERIAL= katapult activation path /dev/serial/by-id/*
    How to obtain KATAPULT_SERIAL:
    When compiling katapult firmware, select "Support bootloader entry on rapid double click of reset button".
    After writing katapult to MCU, press the reset button on the board twice, then use command: ls /dev/serial/by-id/*

```

If there is no suitable configuration file for your board in the config folder, you need to manually configure it in klipper for the first use:
```
cd ~/klipper
make menuconfig
```
After completing the settings, press ESC, then press Y when the pop-up window appears.

Then execute:
```
cp .config ${HOME}/printer_data/config/lazyfirmware/your_board_name/config_file_name
```

Configuration file names follow these naming conventions for easy identification of different board models:
```
btt-manta-m8p-h723/klipper_can_bridge_1m.config
Manufacturer-BoardSeries-BoardModel-MCUModel/FirmwareSystem_ConnectionType_Speed.config

FirmwareSystem: klipper/katapult
ConnectionType: CAN/USB_DFU/USB_KATAPULT/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT
Speed (when using CAN connection): 250k/500k/1m
```

### 4. Update MCU Firmware
Execute:
```
cd ~
./LazyFirmware/lazy.sh
```

## Sharing Configuration Files
If you want to add configuration files to this project, please submit issues and provide the complete configuration file content, along with classification and naming.
