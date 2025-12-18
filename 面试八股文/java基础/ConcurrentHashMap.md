# 讲讲ConcurrenthashMap

* ConcurrentMap是线程安全的HashMap, 通过CAS和锁机制实现线程安全

## 插入操作

* 根据hashcode计算出slot后, 如果slot是null, 则通过CAS将节点设置到slot中, 如果节点有值, 则通过synchronized锁住节点, 然后往链表的尾部插入元素

## GET

* 无锁操作, 即使是在扩容期间也能通过FowardNode找到所在的位置

### get put并发

* 非链表态, 要么读到旧的值, 要么是新值, 没有中间态, 所以正常
* 链表态遍历链表和在链表尾部插入数据没有影响
* 开始/退化树状态: 树的构建是构建成功再设置到slot中
* 树状态时, TreeBin使用了读写锁防止树的旋转影响GET操作, 如果有写锁, 则退化到链表方式进行遍历

### get remove并发

* 基本和put一样

### get resize并发
  
* 当出现hash<0时, 说明正在迁移, 调用ForwardNodef的ind方法进行处理, 跳去新表找

## 扩容

* concurrentHashMap使用sizeCtl来标记是否正在进行容量变化
* 将map分成多个段, 由多个线程并发搬迁; 确定每个线程负责的段数: coresize>1 ? n/8 * coresize : n; 单个线程最少负责16个段; 然后计算最多需要多少个线程进行扩容
* 如果已经有线程在扩容, 当前线程会根据正在进行扩容的线程数判断是否协助扩容

## CHM 在java7和java8的区别

* Java8之前是将一个map分成16个段, 每段一个锁, 操作的时候锁对应的段, 扩容的时候分段扩容
* Java8使用CAS+每个slot单独的锁缩小了锁的粒度, 扩容时使用了多线程协同扩容