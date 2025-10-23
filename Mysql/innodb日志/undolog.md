# undo log

## 作用

* 事务需要回滚时, 确定将哪些页面回滚到什么状态

## 前置要点

* 事务id全局唯一, 在系统表空间中维护了一个max_trx_id, 启动时加载到内存中+256作为新的全局变量, 随事务的进行不断自增
* 数据记录的行有隐藏字段trx_id和roll_pointer, delete_flag属性这些隐藏列
  * roll_pointer就是指向其对应undo_log的 指针

## 日志内容

* undo_no: 同一个事务内的多条操作的编号, 从0开始递增
* end_of_record, 日志结束, 下一条undo日志的位置

### insert的操作

* 记录某个表id(表的表示)中插入的数据内容
* 将脏页放在Flush链表上

### delete的操作

* 记录undolog, 表id为xxx主键为xxx的数据被删除以及影响的索引信息, 将脏页放在flush链表
* 第一阶段: 先把记录的delete_flag记录为已删除状态
  * trx_id, roll_pointer这些自然也应该变化
* 第二阶段: purge时将记录从正常记录链表中移除, 移到垃圾链表, 注意: 由于有MVCC, 事务提交时不一定符合purge执行的条件
  * 附带调整页面的头部信息, 如记录条数等信息

### 更新主键的update语句

* 旧记录一阶段标记删除
* 类似insert新记录
* 提交时二阶段处理旧数据的链表信息

### 不更新主键的update语句

* 就地更新时只需要记录更新的逻辑信息
* 不能就地更新和更新主键的时候一样'

## undo_log的持久化

### 为啥需要持久化

* mvcc
  * 数据库事务提交之后其他隔离级别为RR的事务可能还需要访问这条记录的旧版本数据
* 崩溃恢复
  * redo_log执行完之后, 没有提交的事务的redolog可能也被执行了 也要按照undo_log回滚回去
  * 如果不安这种方式执行, 就需要对每一个事务都找一遍是否有事务提交的记录


### 关于mvcc对undo日志的释放的影响和purge时机

* insert 的undolog在事务提交之后就能释放掉了, 因为它没有旧版本数据
* 删除/修改的undolog不能马上就释放, 因为可能还有别的事务要使用旧版本的内容, 需要等到这些事务都完成再释放

#### 如何确定update/delete的undo_log可以释放

* ReadView也能按照生成的顺序组成一个链表, ReadView的内容详见[MVCC部分](../innodb事务/隔离级别与MVCC.md)
* 后台执行purge的线程在处理时按顺序从链表上取出readview, 比较这个readview 的所 属no和回滚段的history链表上no值较小的各组undolog, 如果一组undolog的事务no小于readview的no, 说明undolog可以释放
  * 删除操作还需要在这里执行二阶段删除: 把数据行从页内的数据链表移动到垃圾链表