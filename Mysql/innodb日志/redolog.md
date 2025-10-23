# redo日志

## 格式

* type: redo日志的类型
* space id: 修改的表空间id
* page number: 修改的页号
* data: 日志内容

## 日志类型

* MLOG_(X)BYTE: 往页的某个偏移位写入X字节数据
* MLOG_REC_INSERT: 页中插入一条REDUNDANT格式的数据
* MLOG_COMP_REC_INSERT: 插入一条COPACT格式的数据
* ... 大概有几十种类型, 大致可以分为物理层面的日志和逻辑层面的日志, 不一一列举
  * 崩溃后可以直接按照页内容写入磁盘的时物理层面日志
  * 需要先调用一些函数进行预处理再写入的时逻辑层面日志

## Mini-Transaction

* 把对底层页面的一次原子性访问视为一个Mini-Transaction
  * 比如涉及页分裂的一个insert, 需要申请新的数据页, 分裂旧页, 新页写数据等
* 一次原子性访问的日志为一组, 组的末尾是一个只有type的特殊redo日志
* 数据库崩溃恢复时, 如果redo日志的后面没有结束标志, 则视为redo日志不完整, 应当丢弃

## redolog的记录

* redolog放在大小为512B的页中, 称为block
* redo日志在写入时也不是直接落盘, 而是先写入缓冲区(log buffer, 默认16MB)
  * 通过bug_free指针确定写入位置的偏移量
  * 事务中产生的Mini-Transaction先暂存, 再连续的写入log buffer
* 待合适的时机将redolog记录到磁盘

## redolog 刷盘时机

* log_buffer空间不足时
* 由于数据页不是实时刷新回磁盘, 事务提交时, 没有对redo日志进行吃就话就提交事务, 持久性无法保证
* **脏页刷新到磁盘前, 需要保证redolog已经刷新到磁盘**
* 定时刷新
* checkpoint

### lsn和刷盘lsn

* redolog有序列号, 初始值为8704
* mysql系统第一次运行时, 最新的lsn和已经刷盘的lsn都是8704
* 系统运行一段时间, redolog不断产生, 两个lsn都会增大, 如果刷盘的lsn小于最新lsn说明有日志还没有刷盘
  * 被修改的数据页会记录最后一次修改这个页的lsn

### 变量innodb_flush_log_at_trx_commit

* 0: 事务提交时redolog不立即刷盘 而是交给异步线程, 崩溃时的部分事务没有持久性保证
* 1: 默认值, 事务提交时redolog立即刷盘
* 2: 事务提交时将redolog写到操作系统的缓冲区, 数据库挂了能正常落盘, 操作系统挂了事务持久性就会出问题

## Checkpoint

* 由于redo日志仅用于系统崩溃的恢复, 所以已经刷盘的脏页对应的日志时无用的, 可以循环利用这些日志占用的空间
* 从flush链表尾部取oldest_modification即可, 这个值记为checkpoint_lsn


## 事务回滚与redolog

* 修改了数据页都会记录redolog, 因此事务过程中在内存修改数据页也会产生redolog
* 事务回滚时, 不记录这个事务的TRX_COMMIT标记即可
  * 崩溃恢复时, 从最后一个checkpoint开始扫描日志, 如果这个事务没有 TRX_COMMIT 标记, 说明事务没有被提交, 不应该根据日志恢复数据页

## 崩溃恢复过程

* 确定恢复的redolog的起点
  * checkpoint_lsn之前的数据都已经刷盘了, 肯定不需要判断, 所以从最新的checkpoint开始
* 确定恢复的redolog的终点
  * 大小不是512B的block说明block没有满, 是崩溃发生时的最后一个block
* 开始恢复数据
  * 从最新的checkpoint开始处理, 判断redolog的lsn是否大于页面的newest_modification值, 如果更大则按照日志中记录的操作修改磁盘中的页面, 如果不比它大则说明脏页在崩溃前就已经落盘了
