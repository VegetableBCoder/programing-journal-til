# Reactor模型

* 一种事件驱动模型, 基于一个事实:是同一时刻不是所有连接都需要进行读写操作, 核心思想是通过少量线程处理多个连接, 避免每个连接创建一个线程进行处理, 提高资源利用率
  * Acceptor: 负责处理新的连接
  * Reactor: 负责事件循环和任务事件分发; 通过epoll, select等操作系统api获取io事件, 然后交给自己或者其他Reactor处理
  * Handler: 处理具体的业务内容

## 单Reactor单线程

* 一个线程不仅处理接受连接, 也处理连接的读写操作, 还处理业务逻辑
* 所有处理都在一个线程里面进行, 一个地方阻塞就会影响整个系统


## 单Reactor多线程


* 事件轮询和IO仍然由一个线程进行处理, 业务处理, 也就是handler, 交给线程池去处理
* IO不会被业务处理阻塞, 但是仍然只有一个线程负责事件轮询和IO操作

## 主从Reactor多线程

* 主Reactor负责accept连接, 并将连接交给从Reactor
* 从Reactor负责处理读写事件, 并将io得到的请求内容交给handler进行处理
* handler不做io, 执行业务逻辑, 根据输入的内容进行计算, 将计算结果输出回从reactor进行io

## Redis的Reactor

* 早期是严格的单Reacto单线程,
* Redis6.0开始变成一个Reactor负责事件轮询, 将事件交给IO线程去处理, 个人理解介于单Reactor多线程和主从Reactor之间

# Netty原理

* boss:  对应Reactor主Reactor
* Worker: 对应Reactor的从Reactor
* EventLoop: 就是线程+Selector的封装
* 通过pipeLine的责任连传递和处理
* 优化和封装nio的byteBuffer, 对一些需要拷贝的场景进行优化