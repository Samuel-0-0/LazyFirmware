主板进DFU方法：

1、短接BOOT0，通电，之后可以释放短接

2、主板通电状态短接BOOT0，然后按一下RESET按钮，之后可以释放短接


将bootloader写入MCU方法：

dfu-util -a 0 -D ~/LazyFirmware/config/btt-octopus-pro-f446/OctoPus-F446-bootloader-32KB.bin -s 0x08000000:mass-erase:force:leave

之后需要重写klipper固件

----------------------------------------------------------

将hex转换为bin方法：

1、使用命令
objdump -h bootloader.hex
查看VMA和LMA，确定偏移量

2、使用命令
objcopy -Iihex -Obinary bootloader.hex bootloader.bin
将hex的文件转换成bin文件