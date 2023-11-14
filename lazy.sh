#!/bin/bash

# 适合懒人一键升级3D打印机控制板MCU的Klipper固件
#
# Copyright (C) 2023  Samuel Wang <imhsaw@gmail.com>
#
# https://github.com/Samuel-0-0/LazyFirmware
#
# This file may be distributed under the terms of the GNU GPLv3 license.

# 配置文件
current_dir=$(dirname "$0")
config_file="${current_dir}/config.cfg"

clear

##自定义打印信息颜色
green=$(echo -en "\e[92m")
yellow=$(echo -en "\e[93m")
red=$(echo -en "\e[91m")
default=$(echo -en "\e[39m")

##ROOT检测
[ $(id -u) -eq 0 ] || [ "$EUID" -eq 0 ] && echo -e "${red}请不要以ROOT身份或者SUDO运行本脚本！在需要的时候，脚本会请求相应的权限。${default}" && exit 1

##更新控制板固件
update_mcu() {
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
stop_klipper_service() {
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
}

##启动klipper服务
start_klipper_service() {
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
}

##获取配置
get_config() {
    section=$1
    key=$2
    #echo "参数1：$section"
    #echo "参数2：$key"
    value=`awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $config_file`
    echo "$value"
}

##检查katapult
#check_katapult

##主程序
# 先判断配置文件是否存在，如果存在统计section数量
if [ -f "$config_file" ]; then
    # 初始化数组
    declare -a sections=()
    # 逐行读取文件
    while IFS= read -r line; do
        # 如果是以 [ 开头但不以 # 开头的行，则将内容添加到数组中
        if [[ $line =~ ^\[[^\#] ]]; then
            # 去除可能存在的空格
            section=$(echo "$line" | tr -d '[]' | tr -d '\r')
            # 将内容添加到数组中
            sections+=("$section")
        fi
    done < "$config_file"
    
    echo -e "${green}当前配置共有${#sections[@]}块主板需要升级固件${default}"

    # 停止klipper服务
    stop_klipper_service

    # 依次执行升级
    for section in "${sections[@]}"; do
        echo -e ""
        echo -e "${yellow}准备升级 $section ...${default}"
        ID=`get_config $section "ID"`
        #echo "$ID"
        MODE=`get_config $section "MODE"`
        #echo "$MODE"
        CONFIG=`get_config $section "CONFIG"`
        #echo "$CONFIG"
        if [[ $MODE =~ "CAN_BRIDGE_KATAPULT" ]]; then
            KATAPULT_SERIAL=`get_config $section "KATAPULT_SERIAL"`
            #echo "$KATAPULT_SERIAL"
            update_mcu $ID $CONFIG $MODE $KATAPULT_SERIAL
        else
            echo ""
            update_mcu $ID $CONFIG $MODE
        fi
    done

    # 启动klipper服务
    start_klipper_service
    echo -e ""
    echo -e "${green}本次固件更新工作已全部完成，祝你打印顺利！${default}"
    echo -e ""
else
    echo -e "${red}${config_file} 文件不存在，请检查配置文件是否存在${default}"
    exit 1
fi
