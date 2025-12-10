# 常用JVM参数

## 标准参数

```
-server和-client: -client仅使用C1编译器, -server使用C1预热, 超过一定次数之后使用C2进行编译, java9之后这个参数取消了, 强制使用分层编译
-cp: 类路径
-Dproperty=value: 系统属性注入

```

## 内存参数
```
-Xms512m: 指定堆的初始大小
-Xmx1g: 指定堆的最大大小
-Xmn384m: 指定新生代大小
-Xss256k: 线程栈大小
-XX:MetaSpaceSize=256MB 元空间大小
-XX:SuvivorRatio=8 Eden和Suvivor的比例
-XX:NewRatio=2 新生代老年代比例
-XX:MaxDirectMemorySize=256M 直接内存大小限制
```

## K8S环境内存参数组合

```
-XX:MAXRAMPercentege=75 堆内存使用容器内存比例
-XX:+UseContainerSupport 支持容器资源限制
-XX:InitRAMPercentage=50 堆内存初始使用的内存比例
-XX:NewRatio=2 新生代老年代比例
```

## GC参数

```
-XX:+UseG1GC 使用GC收集器
-XX:NewRatio 新生代老年代比例
-XX:MaxTenuringThreshold 新生代晋升来年代的存活轮数阈值
-XX:PretenureSizeThreshold 对象直接进老年代的大小阈值

-Xloggc:gc.log 记录gc日志
-XX:HeapDumpPath=/path/to/dump.hprof 堆dump路径
-XX:+PrintGCDetails 堆GC日志详情
-XX:+PringGCTimestamps 打印GC时间
-XX:+PringTenutingDistribution: 打印对象年龄分布

```

## G1 GC参数 (研究下推荐值)

```
-XX:+UseG1GC
-XX:MaxGCPauseMs=200ms # 目标暂停时间
-XX:G1RegionSize=4M    # g1 region大小
-XX:InitialHeapOccupancyPercent=45 # 堆使用45%才开始标记
## 容器环境下需要显式指定, 避免读取了物理机的信息而使用错误线程数
-XX:ConcGCThreads=4    # 并发标记线程数
-XX:ParallGCThreads=8  # 最终标记, 并发回收阶段的线程数
```

## 实验参数

```
-XX:UseCompressedOops 压缩指针(默认开启)
-XX:UseCompressedClassPointers 压缩类指针
-XX:HeapDumpOnOutOfMemory oom时生成堆内存dump
-XX:+UseTLAB 使用tlab加快对象分配
-XX:DisableExplicticGC 禁用System.gc()
```


## TLAB是什么?

* TLAB是给线程分配新对象的私有内存区域, 用来加速对象的内存分配
* 不使用TLAB会在共享的Eden区使用指针碰撞+CAS来处理多个线程竞争堆内存分配的情况
* 使用TLAB时线程会向Eden区申请一块内存来做自己的换冲区
  * 对象分配时通过指针碰撞找一块能容纳对象的内存区域给新对象使用
  * 如果缓冲区不够用则把剩余的空间返还给堆内存成为碎片, 申请新的缓冲区
  * Eden满了不能申请到缓冲区就触发YoungGC