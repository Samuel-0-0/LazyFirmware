#!/bin/bash

# Easy klipper firmware updater script
# Klipper固件快速升级脚本
#
# Copyright (C) 2023-2025  Samuel Wang <imhsaw@gmail.com>
#
# https://github.com/Samuel-0-0/LazyFirmware
#
# This file may be distributed under the terms of the GNU GPLv3 license.

# Path to configuration file
# 配置文件路径
config_file="${HOME}/printer_data/config/lazyfirmware/config.cfg"

# Clear the terminal screen
# 清屏
clear

# Define message colors
# 定义颜色
green=$(echo -en "\e[92m")
yellow=$(echo -en "\e[93m")
red=$(echo -en "\e[91m")
default=$(echo -en "\e[39m")

# Function to get configuration value from INI-style config file
# 从配置文件中提取配置
get_config() {
    section=$1
    key=$2
    value=$(awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' $config_file | tr -d '\r')
    echo "$value"
}

# Load language setting from config (default to English)
# 加载语言配置（默认英文）
lang=$(get_config "global" "language")
[ -z "$lang" ] && lang="en"

# Define all multilingual messages
# 定义多语言
if [[ "$lang" == "zh_cn" ]]; then
    MSG_MATCHING_CONFIG="匹配配置文件..."
    MSG_CONFIG_SUCCESS="配置文件匹配完成"
    MSG_CONFIG_FAIL="配置文件匹配失败"
    MSG_COMPILING="正在编译klipper固件，请耐心等待..."
    MSG_PRESS_ENTER="固件编译完成，请检查上面是否有错误。 按 [Enter] 继续更新，或按 [Ctrl+C] 取消"
    MSG_FW_DONE="本次固件更新工作已全部完成，祝你打印顺利！"
    MSG_ROOT_WARNING="请不要以ROOT身份或SUDO运行本脚本！脚本在需要时会请求权限。"
    MSG_STOP_KLIPPER="正在停止Klipper服务..."
    MSG_START_KLIPPER="正在启动Klipper服务..."
    MSG_KLIPPER_SUCCESS="成功"
    MSG_KLIPPER_FAIL="失败"
    MSG_KATAPULT_DOWNLOADING="正在下载katapult"
    MSG_KATAPULT_SUCCESS="Katapult操作成功"
    MSG_KATAPULT_FAIL="Katapult操作失败，请查看上方信息"
    MSG_CFG_NOT_FOUND="$config_file 文件不存在，请检查配置文件是否存在"
    MSG_TOTAL_MCU="共有%s块主板需要更新固件"
    MSG_PREPARE_UPDATE="准备更新"
    MSG_UPDATE_SUCCESS="%s 固件更新完成"
    MSG_UPDATE_FAIL="%s 固件更新失败，请查看上方信息"
    MSG_SWITCHING_KATAPULT="正在将控制板切换到KATAPULT，请等待 %s 秒..."
    MSG_SWITCHING_DFU="正在将控制板切换到DFU，请等待 %s 秒..."
else
    MSG_MATCHING_CONFIG="Matching config file..."
    MSG_CONFIG_SUCCESS="Config file matched successfully"
    MSG_CONFIG_FAIL="Config file match failed"
    MSG_COMPILING="Compiling Klipper firmware, please wait..."
    MSG_PRESS_ENTER="Firmware compiled. Press [Enter] to continue or [Ctrl+C] to cancel"
    MSG_FW_DONE="All firmware updates completed. Happy printing!"
    MSG_ROOT_WARNING="Do NOT run this script as ROOT or with SUDO! It will request permissions when needed."
    MSG_STOP_KLIPPER="Stopping Klipper service..."
    MSG_START_KLIPPER="Starting Klipper service..."
    MSG_KLIPPER_SUCCESS="Done"
    MSG_KLIPPER_FAIL="Failed"
    MSG_KATAPULT_DOWNLOADING="Cloning katapult..."
    MSG_KATAPULT_SUCCESS="Katapult operation successful"
    MSG_KATAPULT_FAIL="Katapult operation failed. See messages above."
    MSG_CFG_NOT_FOUND="Config file not found: $config_file"
    MSG_TOTAL_MCU="Total %s MCUs will be updated"
    MSG_PREPARE_UPDATE="Preparing to update"
    MSG_UPDATE_SUCCESS="%s firmware update completed"
    MSG_UPDATE_FAIL="%s firmware update failed. See messages above."
    MSG_SWITCHING_KATAPULT="Switching board to KATAPULT, please wait %s seconds..."
    MSG_SWITCHING_DFU="Switching board to DFU, please wait %s seconds..."
fi

# Prevent running as root
# ROOT检测
[ $(id -u) -eq 0 ] || [ "$EUID" -eq 0 ] && echo -e "${red}${MSG_ROOT_WARNING}${default}" && exit 1

# Function to update firmware
# 更新固件
update_mcu() {
    echo -e "${yellow}${MSG_MATCHING_CONFIG} $2${default}"
    cp -f "$2" ~/klipper/.config || { echo -e "\n${red}${MSG_CONFIG_FAIL}${default}"; exit 1; }
    echo -e "${green}${MSG_CONFIG_SUCCESS}${default}\n"

    echo -e "${yellow}${MSG_COMPILING}${default}"
    pushd ~/klipper
    make olddefconfig && make clean && make
    echo -e ""

    # Wait for user confirmation before flashing
    # 刷写前用户确认
    read -e -p "${yellow}${MSG_PRESS_ENTER}${default}"
    echo -e ""

    # Select flashing method based on mode
    # 匹配刷写模式
    case "$3" in
        CAN)
            python3 ~/katapult/scripts/flashtool.py -i ${can_interface:="can0"} -f ~/klipper/out/klipper.bin -u $1;;
        CAN_BRIDGE_DFU)
            python3 ~/katapult/scripts/flashtool.py -i ${can_interface:="can0"} -u $1 -r
            echo -e "\n${red}$(printf "$MSG_SWITCHING_DFU" 5)${default}\n"
            sleep 5
            make flash FLASH_DEVICE=0483:df11;;
        CAN_BRIDGE_KATAPULT)
            python3 ~/katapult/scripts/flashtool.py -i ${can_interface:="can0"} -u $1 -r
            echo -e "\n${red}$(printf "$MSG_SWITCHING_KATAPULT" 5)${default}\n"
            sleep 5
            make flash FLASH_DEVICE=$4;;
        USB_DFU)
            make flash FLASH_DEVICE=$1;;
        USB_KATAPULT)
            python3 ~/katapult/scripts/flashtool.py -d $1 -r
            echo -e "\n${red}$(printf "$MSG_SWITCHING_KATAPULT" 2)${default}\n"
            sleep 2
            python3 ~/katapult/scripts/flashtool.py -f ~/klipper/out/klipper.bin -d $4;;
        HOST)
            make flash;;
    esac
    popd
}

# Function to check and update/clone katapult
# 检查katapult
check_katapult() {
    cd ~
    if [ ! -d "katapult" ]; then
        echo -e "\n${yellow}${MSG_KATAPULT_DOWNLOADING}${default}"
        git clone https://github.com/Arksine/katapult.git && echo -e "\n${green}${MSG_KATAPULT_SUCCESS}${default}\n" || { echo -e "\n${red}${MSG_KATAPULT_FAIL}${default}\n"; exit 1; }
    else
        echo -e "\n${yellow}Updating katapult...${default}"
        pushd ~/katapult && git pull && echo -e "\n${green}${MSG_KATAPULT_SUCCESS}${default}" || { echo -e "\n${red}${MSG_KATAPULT_FAIL}${default}"; exit 1; }
        popd
    fi
}

# Function to stop Klipper service
# 停止klipper服务
stop_klipper_service() {
    echo -e "\n${yellow}${MSG_STOP_KLIPPER}${default}"
    sudo service klipper stop && echo -e "${green}${MSG_KLIPPER_SUCCESS}${default}" || { echo -e "\n${red}${MSG_KLIPPER_FAIL}${default}"; exit 1; }
}

# Function to start Klipper service
# 启动klipper服务
start_klipper_service() {
    echo -e "\n${yellow}${MSG_START_KLIPPER}${default}"
    sudo service klipper start && echo -e "${green}${MSG_KLIPPER_SUCCESS}${default}" || { echo -e "\n${red}${MSG_KLIPPER_FAIL}${default}"; exit 1; }
}

# Check/clone/update katapult before flashing
# 检查katapult
check_katapult

# Main routine: parse config, update each section
# 主程序，分析配置文件
if [ -f "$config_file" ]; then
    declare -a sections=()
    while IFS= read -r line; do
        [[ $line =~ ^\[[^#] ]] && section=$(echo "$line" | tr -d '[]' | tr -d '\r') && sections+=("$section")
    done < "$config_file"

    # Display number of MCUs to update
    # 显示需要更新的MCU数量
    printf "${green}${MSG_TOTAL_MCU}${default}\n" "$(( ${#sections[@]} - 1 ))"

    # Stop klipper before update
    # 更新前需停止klipper服务
    stop_klipper_service

    # Iterate over each section and update firmware
    # 依次执行更新
    for section in "${sections[@]}"; do
        if [[ $section == "global" ]]; then
            can_interface=$(get_config "global" "can_interface")
        else
            echo -e "\n${yellow}${MSG_PREPARE_UPDATE} ${section} ...${default}"
            ID=$(get_config $section "ID")
            MODE=$(get_config $section "MODE")
            CONFIG=$(get_config $section "CONFIG")
            if [[ "$MODE" == *"KATAPULT"* ]]; then
                KATAPULT_SERIAL=$(get_config $section "KATAPULT_SERIAL")
                update_mcu $ID $CONFIG $MODE $KATAPULT_SERIAL
            else
                update_mcu $ID $CONFIG $MODE
            fi
            # Show success/failure
            # 显示成功/失败
            if [ $? -eq 0 ]; then
                printf "\n${green}${MSG_UPDATE_SUCCESS}${default}\n" "$section"
            else
                printf "\n${red}${MSG_UPDATE_FAIL}${default}\n" "$section"
                exit 1
            fi
        fi
    done

    # Restart klipper after update
    # 更新后启动klipper服务
    start_klipper_service
    echo -e "\n${green}${MSG_FW_DONE}${default}\n"
else
    echo -e "${red}${MSG_CFG_NOT_FOUND}${default}"
    exit 1
fi

