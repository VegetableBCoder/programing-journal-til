# Paralled Old收集器

## 概述

* 收集区域: 老年代
* 算法: 标记整理
* STW: 全程STW
* 并发执行: 多线程

## 其他

* JDK4 提供Paralled Scavenge之后并不能与支持老年代并发清理的CMS处理器一起使用, 直到JDK6的Paralled Old出现才能组成新生代老年代都支持并行清理的组合
  * 注重吞吐量要求或者处理器资源较差的环境下 Paralled Scavenge + Paralled Old的效果可能比 ParNew + CMS的效果更好