# volatile实现

* 现代CPU经常都是多核的, 也就是多个线程同时在运行, 它们可能都在访问同一个变量, volatile保证的就是一个线程修改之后其他线程要立即可见
* volatile在实现时使用了两个内存屏障 StoreStore和StoreLoad屏障
  * 写操作在写前使用StoreStore屏障, 保证volatile之前的写不会下沉到volatile写之后, 然后执行volatile写的 store
  * 写后使用StoreLoad屏障, 保证写之后的后续读写不上浮到volatile之前, 同时使写的结果对其他核心可见
  * 读操作时先执行LoadLoad+LoadStore屏障, 防止volatile之前的读写操作下沉到volatile读之后; 然后执行volatile读
  * volatile读之后插入LoadStore屏障, 禁止下面的指令重排到volatile读之前 (JDK17之后如果后面没有普通读写指令就不加这个屏障)
* 关于屏障
  * StoreStore:
    * StoreStore屏障对应在X86平台上是不需要额外指令的, 因为x86架构通过写store buffer保证了写写有序行: 写入时按顺序写入store buffer, 执行volatile写(带lock前缀)会先把store buffer写入主存
      * M: 缓存行被修改了, 与主存不一致, 只在当前核心有效, 写回主存后, 其他核心才能读取
      * E: 当前核心独占缓存行, 但是与主存一致, 其他核心没有缓存行的副本
      * S: 多个核心拥有缓存行的副本, 但是都和主存一致
      * I: 缓存行无效, 需要从其他核心或者主存重新加载
    * StoreStore在ARM上需要插入额外指令
  * StoreLoad:
    * X86上的使用mfence指令:
      * 立即将写操作结果从store buffer刷新到L1缓存
      * 通过MESI的invalid消息让其他核心的缓存行失效
      * 禁止CPU乱序执行后面的load指令
* LoadLoad, LoadStore在X86上天然支持, 所以实际上不用插指令
  * 即使有LoadBuffer和StoreBuffer, MESI也保证了可见性
  * X86 CPU不会乱序执行两个Load指令

## 解释执行和JIT的不同

* 解释执行是一条一条字节码执行, 所以会严格按照JMM规则插入内存屏障
* C1编译器优化比较保守, 基本还是会按照规则生成汇编指令, 读写后面的 LoadStore, StoreLoad一样不会省掉
* C2会激进优化, 消除冗余屏障, 连续的volatile写会删除中间的storeLoad, 只保留最后一个storeload; 另外还会进行一些合并, 锁粗化, 逃逸分析的优化