# ThreadLocal

* ThreadLocal是线程私有的一块存储区域, 每个线程都有自己的, 互不干扰, 天然线程安全
* ThreadLocal持有一个ThreadLocalMap, 这个map不是普通的hashMap, 而是一个entry数组和开地址法实现的简单map
  * entry的key是ThreadLocal的弱引用, value是强引用
* ThreadLocal如果使用不正确可能会引起内存泄露
  * 如果线程死亡自然ThreadLocalMap自然也会被清理, 泄露的内存就能回收, 但是使用线程池的情况下就可能会长期存活不回收

## ThreadMap的内存泄露

* ThreadLocal中设置值后, 如果没有及时remove, value会一直存在, 直到被启发式清理
  * ThreadLocal的强引用都消失后Entry的key会被GC掉, 但是value不会被GC
  * value要GC掉就需要ThreadLocal通过检测和清理将entry移除掉
* 就需要在ThreadMap里面getEntry失败/set发现hash冲突, 扩容的时候, 对entry的key是null, value不是null的entry进行删除


## 为什么使用Entry数组, 而不是hashmap

* 一个线程的ThreadLocal数量一般比较少, hash冲突少, 使用简单的结构反而性能更好
* 方便启发式扫描的entry清理