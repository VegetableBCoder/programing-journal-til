# ParNew收集器

## 概述

* 实际上就是多线程并行版本的Serial, 其他的规则, 如STW, 收集算法, 回收策略都和Serial一致
  
## 注意

* 在单核单线程处理器 Parnew的性能绝对不会比Serial好, 即使是单核双线程的超线程处理器也不一定更好

## 其他

* 只有Serial/ParNew能够和CMS一起使用
  * JDK9开始取消了ParNew+Serial Old和Serial+CMS的组合; ParNew成为CMS的一部分
  * JDK1.4已经有Parallel Scavenge, 但是CMS不能和它配合, 随着G1的出现CMS开始没落, 所Parnew也一起没落了