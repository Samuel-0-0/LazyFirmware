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

### 三、配置config.cfg文件
```
mkdir ${HOME}/printer_data/config/lazyfirmware
touch ${HOME}/printer_data/config/lazyfirmware/config.cfg
```
修改config.cfg文件，文件内容示例：
```
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
配置项说明
```
[主板名字]
ID=主板的UUID或者/dev/serial/by-id/*路径，如果是上位机填NULL
    获取方法：
    控制板通过USB连接并且klipper固件通讯接口为USB，使用命令 ls /dev/serial/by-id/* 获取
    CAN或者CAN_BRIDGE固件，使用命令 ~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 获取
MODE=从CAN/USB_DFU/USB_KATAPULT/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT/HOST中选择1个，其中
     - CAN表示控制板通过CAN总线连接，klipper固件通讯接口为CAN，
           BootLoader为katapult，且katapult编译时的通讯接口选择的是CAN；
     - USB_DFU表示控制板通过USB连接，klipper固件通讯接口为USB，
           BootLoader为官方自带；
     - USB_KATAPULT表示控制板通过USB连接，klipper固件通讯接口为USB，
           BootLoader为katapult，且katapult编译时的通讯接口选择的是USB；
     - CAN_BRIDGE_DFU表示控制板通过USB连接，klipper固件通讯接口为USB to CAN bus bridge，
           BootLoader为官方自带；
     - CAN_BRIDGE_KATAPULT表示控制板通过USB连接，klipper固件通讯接口为USB to CAN bus bridge，
           BootLoader使用katapult，且katapult编译时的通讯接口选择的是USB；
     - HOST表示上位机；
CONFIG=编译klipper固件的配置文件路径。不能是~/开头，必须使用如/home/biqu/这样的绝对路径
KATAPULT_SERIAL=katapult激活时的/dev/serial/by-id/*路径
    KATAPULT_SERIAL获取方法：
    katapult固件在编译时需要选中Support bootloader entry on rapid double click of reset button，
    katapult写入MCU后，按2下主板上的reset键，使用命令 ls /dev/serial/by-id/* 获取

```

如果config文件夹中没有符合你的主板的配置文件，第一次使用请自己手动到klipper进行配置
```
cd ~/klipper
make menuconfig
```
设置完成后，按键盘ESC键，看到弹出窗口按键盘Y键。

然后执行
```
cp .config ${HOME}/printer_data/config/lazyfirmware/你的主板名字/配置文件名字
```

配置文件名字遵循下列命名规则，便于区分各型号主板：
```
btt-manta-m8p-h723/klipper_can_bridge_1m.config
厂商-主板系列-主板型号-主控型号/固件系统_连接类型_速率.config

固件系统：klipper/katapult
连接类型：CAN/USB_DFU/USB_KATAPULT/CAN_BRIDGE_DFU/CAN_BRIDGE_KATAPULT
速率（使用CAN连接时）：250k/500k/1m
```

### 四、更新MCU固件
执行
```
cd ~
./LazyFirmware/lazy.sh
```

## 共享配置文件
如果需要在本项目中增加配置文件，请提交issues并将配置文件内容完整提供，同时提供分类及命名。
