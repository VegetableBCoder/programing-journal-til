# RDB持久化

## 实现方式

* 定时将内存中的数据dump到磁盘中

## BGSAVE执行期间的处理

* 拒绝新的SAVE, BGSAVE指令
* BGREWRITEAOF会被延迟到BGSAVE完成之后再执行

## 自动保存

### 自动保存策略

* 允许设置多条规则, 在多长时间内有多少次操作就触发自动保存

### 自动保存实现

* 在redisServer对象上有dirty计数器和lastsave属性记录上次保存时间
  * dirty计数器表示上次执行save之后执行的命令条数
* serverCron每100ms检查一下dirty计数器和lastsave是否符合某一个条件

## RDB文件

### 组成部分

* 魔法字符REDIS\0, 作为RDB文件标记
* db_version: 4字节, 表示RDB文件版本
* databases数据
* EOF
* CHECKSUM

### databases部分

* 魔法字符 SELECTDB
* db_number
* key_value_pairs