# LazyFirmware
适合懒人一键升级3D打印机控制板MCU的Klipper固件

## 使用方法

### 一、下载LazyFirmware
```
cd ~
git clone https://github.com/Samuel-0-0/LazyFirmware
```

### 二、安装依赖
```
pip3 install pyserial
```

### 三、修改lazy.sh文件
找到下面的内容
```
##############################################################################################
#  >>>用户配置区域<<<
#  请根据自己的实际情况依次更新下方1、2、3的内容
#---------------------------------------------------------------------------------------------
#  1、主板CAN UUID或者通讯端口
#---------------------------------------------------------------------------------------------
#  USB固件(包括使用USB通讯的KATAPULT固件)使用命令： "ls -l /dev/serial/by-id/" 获取通讯端口号填入下方
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

```
分别修改其中的1、2、3，案例如上所示。

如果没有符合你的主板的配置文件，第一次使用请自己手动到klipper进行配置
```
cd ~/klipper
make menuconfig
```
设置完成后，按键盘ESC键，看到弹出窗口按键盘Y键。

然后执行
```
cp .config ~/LazyFirmware/config/你的主板名字/配置文件名字
```

遵循下列命名规则，便于区分各型号主板：
```
btt-manta-m8p-h723/can_bridge_1m.config
厂商-主板系列-主板型号-主控型号/固件类型_速率.config

固件类型：can/can_bridge/usb
速率：250k/500k/1m
```

### 四、更新MCU固件
执行
```
cd ~
./LazyFirmware/lazy.sh
```

## 共享配置文件
如果需要在本项目中增加配置文件，请提交issues并将配置文件内容完整提供，同时提供分类及命名。
