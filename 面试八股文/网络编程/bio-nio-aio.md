# 关于IO

* 首先 BIO, NIO, AIO对应的是三种模型: 阻塞, 非阻塞多路复用, 异步

## BIO

* 阻塞式IO, 一个连接一个线程, read, write都会阻塞
* 线程资源消耗大, 扩展性不好

## NIO

* NIO使用的是同步非阻塞+多路复用
* NIO的核心是Channel, Selector, Buffer
  * Channel用来描述文件通道(everything is file), 并负责真正的首发字节内容
  * Selector用来轮询哪些连接已就绪, 可以读出数据, 可以写入数据
  * Buffer作为channel读写交互的间接交互对象
* 通过selector使用epoll管理事件, read write是非阻塞的, 但是仍然是同步的

## AIO

* 用户发起IO之后立即返回, IO完成后进行回调, 是真正的异步IO模型
* 在linux环境下 java的AIO是通过线程池模拟+epoll的异步, 目前还没有使用io_uring这种真正的异步io api

### io_uring是啥