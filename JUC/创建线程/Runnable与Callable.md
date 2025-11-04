# 创建线程

## Runnable与Callable

* 这俩都是接口, runable的run只能返回void, callable的call方法可以返回运行结果
* Callable可以直接创建FutureTask对象, 其返回结果就是FutureTask的result, 而runnable还需要指定result

## Future接口和FutureTask

* Future: 提交一个接口, 表示未来运行完成之后可以通过这个对象get到异步运行的结果
* FutureTask: Future接口的实现, 并维护一步任务运行状态(NEW, RUNNING, COMPLETE等), 提供cancel功能
* 注意, Future接口的get方法时阻塞的