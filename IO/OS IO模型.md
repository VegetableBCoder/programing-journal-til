# OS IO模型


* 应用调用C lib IO: 应用程序buffer -> CLib Buffer -> 文件系统页缓存 -> 磁盘IO
* 应用调用文件IO: 应用buffer-> 文件系统页缓存 -> 磁盘IO
* 应用使用O_DIRECT/dd工具: 绕过页缓存直接磁盘IO

## 内核层

## 块层

## 设备层