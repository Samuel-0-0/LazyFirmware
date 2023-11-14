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

### 三、修改config.cfg文件
配置文件示例
```
[EBB]
ID=c5360983cdc4
MODE=CAN
CONFIG=~/LazyFirmware/config/btt-ebb-g0/can_1m.config

[M8P]
ID=962b136468fc
MODE=CAN_BRIDGE_KATAPULT
CONFIG=~/LazyFirmware/config/btt-manta-m8p-h723/can_bridge_1m.config
KATAPULT_SERIAL=/dev/serial/by-id/usb-katapult_stm32h723xx_38000A001851313434373135-if00

#[OCTOPUS_PRO]
#ID=fea6ca620740
#MODE=CAN_BRIDGE
#CONFIG=~/LazyFirmware/config/btt-octopus-pro-f446/can_bridge_1m.config

#[OCTOPUS_PRO]
#ID=/dev/serial/by-id/usb-Klipper_stm32...
#MODE=USB
#CONFIG=~/LazyFirmware/config/btt-octopus-pro-f446/usb.config

```
配置说明
```
[主板名字]
ID=主板的UUID或者/dev/serial/by-id/*
     获取方法：
     控制板通过USB连接并且klipper固件通讯接口为USB，使用命令 ls /dev/serial/by-id/* 获取
     其他情况，使用命令 ~/klippy-env/bin/python ~/klipper/scripts/canbus_query.py can0 获取
MODE=从CAN/USB/CAN_BRIDGE/CAN_BRIDGE_KATAPULT中选择1个，其中
     CAN表示控制板通过CAN总线连接，klipper固件通讯接口为CAN；
     USB表示控制板通过USB连接，klipper固件通讯接口为USB；
     CAN_BRIDGE表示控制板通过USB连接，klipper固件通讯接口为USB to CAN bus bridge；
     CAN_BRIDGE_KATAPULT表示控制板通过USB连接，klipper固件通讯接口为USB to CAN bus bridge，
     但是BootLoader使用katapult且katapult的通讯接口为USB
CONFIG=编译klipper固件的配置文件路径
KATAPULT_SERIAL=katapult激活时的/dev/serial/by-id/*
     获取方法：
     写入的katapult固件在编译时需要选中Support bootloader entry on rapid double click of reset button，
     按2下主板上的reset键，使用命令 ls /dev/serial/by-id/* 获取
```

如果config文件夹中没有符合你的主板的配置文件，第一次使用请自己手动到klipper进行配置
```
cd ~/klipper
make menuconfig
```
设置完成后，按键盘ESC键，看到弹出窗口按键盘Y键。

然后执行
```
cp .config ~/LazyFirmware/config/你的主板名字/配置文件名字
```

配置文件名字遵循下列命名规则，便于区分各型号主板：
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
