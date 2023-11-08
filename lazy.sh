#!/bin/bash

# 适合懒人一键升级3D打印机控制板MCU的Klipper固件
#
# Copyright (C) 2023  Samuel Wang <imhsaw@gmail.com>
#
# https://github.com/Samuel-0-0/LazyFirmware
#
# This file may be distributed under the terms of the GNU GPLv3 license.

clear

##自定义打印信息颜色
green=$(echo -en "\e[92m")
yellow=$(echo -en "\e[93m")
red=$(echo -en "\e[91m")
default=$(echo -en "\e[39m")

## ROOT检测
[ $(id -u) -eq 0 ] || [ "$EUID" -eq 0 ] && echo -e "${red}请不要以ROOT身份或者SUDO运行本脚本！在需要的时候，脚本会请求相应的权限。${default}" && exit 1

##更新控制板固件
UPDATE_MCU() {
    echo -e ""
    echo -e "${yellow}准备更新klipper固件，匹配配置文件...${default}"
    echo -e "$2"
    cp -f $2 ~/klipper/.config
    if [ $? -eq 0 ]
    then
        echo -e "${green}配置文件匹配完成${default}"
    else
        echo -e ""
        echo -e "${red}配置文件匹配失败，详情请查看上方信息${default}"
        exit 1
    fi
    echo -e ""
    echo -e "${yellow}正在编译klipper固件，请耐心等待...${default}"
    cd ~/klipper
    make olddefconfig
    make clean
    make
    echo -e ""
    read -e -p "${yellow}固件编译完成，请检查上面是否有错误。 按键盘 [Enter] 继续更新固件，或者按 [Ctrl+C] 取消${default}"
    echo -e ""
    # 如果使用CAN固件
    if [ "$3" == "CAN" ]; then
        python3 ~/katapult/scripts/flashtool.py -i can0 -f ~/klipper/out/klipper.bin -u $1
    # 如果使用CAN_BRIDGE固件，并且使用DFU模式更新
    elif [ "$3" == "CAN_BRIDGE_DFU" ]; then        
        python3 ~/katapult/scripts/flashtool.py -i can0 -u $1 -r
        echo -e ""
        echo -e "${red}正在将控制板切换到DFU，请耐心等待5秒...${default}"
        echo -e ""
        # 等待5秒
        sleep 5 &
        wait
        # 进入DFU模式后的设备FLASH_DEVICE通常是0483:df11
        make flash FLASH_DEVICE=0483:df11
    # 如果使用CAN_BRIDGE固件，并且使用KATAPULT更新
    elif [ "$3" == "CAN_BRIDGE_KATAPULT" ]; then        
        python3 ~/katapult/scripts/flashtool.py -i can0 -u $1 -r
        echo -e ""
        echo -e "${red}正在将控制板切换到KATAPULT，请耐心等待5秒...${default}"
        echo -e ""
        # 等待5秒
        sleep 5 &
        wait
        # 进入KATAPULT后的设备有独立的通讯端口号
        python3 ~/katapult/scripts/flashtool.py -d $4
    # 如果使用USB固件
    elif [ "$3" == "USB" ]; then
        make flash FLASH_DEVICE=$1
    fi
    if [ $? -eq 0 ]
    then
        echo -e ""
        echo -e "${green}已完成 $1 固件更新${default}"
        cd ~
    else
        echo -e ""
        echo -e "${red}固件更新失败，详情请查看上方信息${default}"
        cd ~
        exit 1
    fi
}


##检查katapult
check_katapult() {
    cd ~
    if [ ! -d "katapult" ]; then
        echo -e ""
        echo -e "${yellow}下载katapult${default}"
        git clone https://github.com/Arksine/katapult.git
        if [ $? -eq 0 ]; then
            echo -e ""
            echo -e "${green}katapult下载完成${default}"
            echo -e ""
        else
            echo -e ""
            echo -e "${red}katapult下载失败，详情请查看上方信息${default}"
            echo -e ""
            exit 1
        fi
    else
        echo -e ""
        echo -e "${yellow}正在更新katapult，请耐心等待...${default}"
        cd ~/katapult
        git pull
        if [ $? -eq 0 ]; then
            echo -e ""
            echo -e "${green}katapult更新完成${default}"
        else
            echo -e ""
            echo -e "${red}katapult更新失败，详情请查看上方信息${default}"
            cd ~
            exit 1
        fi
    fi
}


##停止klipper服务
echo -e ""
echo -e "${yellow}正在停止klipper服务...${default}"
sudo service klipper stop
if [ $? -eq 0 ]; then
    echo -e "${green}完成${default}"
else
    echo -e ""
    echo -e "${red}klipper服务停止失败，详情请查看上方信息${default}"
    exit 1
fi

##检查katapult
#check_katapult

##############################################################################################
#  >>>用户配置区域<<<
#  请根据自己的实际情况依次更新下方1、2、3的内容
#---------------------------------------------------------------------------------------------
#  1、主板CAN UUID或者通讯端口
#---------------------------------------------------------------------------------------------
#  USB固件使用命令： "ls -l /dev/serial/by-id/" 获取通讯端口号填入下方
#  CAN或者CAN Bridge固件使用命令：
#  "~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0" 获取CAN UUID

EBB_UUID=c5360983cdc4
M8P_UUID=962b136468fc
M8P_KATAPULT_SERIAL=/dev/serial/by-id/usb-katapult_stm32h723xx_38000A001851313434373135-if00
#M8P_SERIAL=/dev/serial/by-id/usb-Klipper_stm32...
#OCTOPUS_PRO_SERIAL=/dev/serial/by-id/usb-Klipper_stm32...

#---------------------------------------------------------------------------------------------
#  2、主板klipper配置文件路径
#---------------------------------------------------------------------------------------------
EBB_CONFIG=~/LazyFirmware/config/btt-ebb-g0/can_1m.config
M8P_CAN_BRIDGE_CONFIG=~/LazyFirmware/config/btt-manta-m8p-h723/can_bridge_1m.config
#M8P_USB_CONFIG=~/LazyFirmware/config/btt-manta-m8p-h723/usb.config
#OCTOPUS_PRO_CAN_BRIDGE_CONFIG=~/LazyFirmware/config/btt-octopus-pro-f446/can_bridge_1m.config

#---------------------------------------------------------------------------------------------
#  3、更新方案
#---------------------------------------------------------------------------------------------
#  使用方法：
#  UPDATE_MCU [MCU] [MCU_CONFIG] [CAN/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT/USB] [KATAPULT_SERIAL]
#  其中[MCU]表示主板的UUID或者通讯端口，[MCU_CONFIG]表示对应主板klipper配置文件路径，
#  [CAN/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT/USB]分别对应不同的更新方式，
#  CAN_BRIDGE_KATAPULT方式需要附带主板在进入KATAPULT状态后的通讯端口

UPDATE_MCU $EBB_UUID $EBB_CONFIG CAN
UPDATE_MCU $M8P_UUID $M8P_CAN_BRIDGE_CONFIG CAN_BRIDGE_KATAPULT $M8P_KATAPULT_SERIAL
#UPDATE_MCU $M8P_SERIAL $M8P_USB_CONFIG USB
#UPDATE_MCU $OCTOPUS_PRO_SERIAL $OCTOPUS_PRO_CAN_BRIDGE_CONFIG CAN_BRIDGE_DFU

##############################################################################################


##启动klipper服务
echo -e ""
echo -e "${yellow}正在启动klipper服务...${default}"
sudo service klipper start
if [ $? -eq 0 ]; then
    echo -e "${green}完成${default}"
else
    echo -e ""
    echo -e "${red}klipper服务启动失败，详情请查看上方信息${default}"
    exit 1
fi


echo -e ""
echo -e "${green}本次固件更新工作已全部完成，祝你打印顺利！${default}"
echo -e ""
