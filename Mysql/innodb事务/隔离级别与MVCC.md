# 数据库隔离级别和

## 事务并发过程中的一致性问题

### 脏写

* 两个事务同时修改一份数据, 会破坏事务的原子性
  * 脏写的影响过于恶劣, 数据库即使需要牺牲一致性换取性能也不会考虑忽略脏写问题

### 脏读

* 一个事务读取到了另一个事务未提交的内容

### 不可重复读

* 一个事务内, 两次读取同一条数据, 并且自己没有修改这条数据, 发现前后读取的数据不一样
  * 不可重复读强调的是读取到的数据被其他事务修改了

### 幻读

* 一个事务前后两次使用相同的条件查询数据, 发现第二次查询多出了数据

## 隔离级别和存在的一致性问题

| 隔离级别 | 是否解决脏读 | 是否解决不可重复读 | 是否解决幻读 |
|---|---|---|---|
| 读未提交| 否 | 否 | 否 |
| 读已提交| 是 | 否 | 否 |
| 可重复读| 是 | 是 | 否 |
| 序列化 | 是 | 是 | 是 |

* innodb依靠mvcc + next-key lock在可重复读的隔离级别下防止了大部分情况的幻读

## innodb对四种隔离级别的实现方式

### 读未提交

* 跳过RC/RR的readview过程, 直接读取行记录的最新版本

### 序列化

* 查询语句都会自动加上 LOCK IN SHARE MODE带上共享锁排斥其他写操作
* 写语句都会加上排他锁, 写操作会阻塞其他事务的读写操作

### 读已提交

* 查询开始时生成一个readview, 查询数据时, 判断行的所属事务是否已提交, 吴国未提交则按照roll_pointer从undo_log读取旧版本

### 可重复读

* 事务内的第一次快照读时建立read-view

## 当前读与快照读

* 快照读: 在一个事务内按照一致性读取版本视图数据
  * RC/RR模式下的普通select
* 当前读: 直接读取最新版本数据
  * 所有的update, delete, in share mode, for update

## MVCC

* 用快照读解决部分隔离性问题的手段

### 版本链

* 通过记录的隐藏字段roll_pointer指向自己的undo_log, undolog_也有自己的roll_pointer指向上一个版本的undolog, 这样就形成了一个从最新版本指向最旧版本的链表

### ReadView

* 设计ReadView的目的时为了快速判断一个事务id是否在生成ReadView时就已经完成
  * 生成快照时正在进行的事务修改过的数据应该展示旧版本
  * 生成快照之后新生成的事务修改过的数据应该展示旧版本
  * 当前事务变更的数据应当展示
  * 在生成ReadView生成时已经完成的事务最终修改的数据直接展示最新版本


#### 组成部分

* m_ids: 在生成ReadView时, 系统中正在活跃的事务id
* min_trx_id: m_ids里面最小的id
* max_trx_id: 系统分配给下一个事务的id
* creator_trx_id: 当前事务的事务id, 如果还没有执行写操作, 则id为0

### ReadView的使用

```
if (trx_ix == creatod_trx_id) {
    // 当前事务
}
if (trx_id < min_trx_id) {
    // 事务在readview生成时已经完成
} else if (trx_id >= max_trx_id) {
    // 事务在ReadView生成之后才发生
} else if (m_ids.contains(trx_id)) {
    // ReadView创建时事务正在运行
} else {
    // 事务在readview生成时已经完成
}
```

### RC和RR对ReadView使用的不同

* RR: 第一次执行**快照读**时生成ReadView
  * RR隔离级别可以使用 start transaction with CONSITENT SNAPSHOT 在事务开始时立即生成ReadView
* RC: 每次快照读都生成ReadView

## 案例1: ReadView生成时机验证

|事务1 |事务2 |
|----| ---|
| begin | |
| | begin |
| | insert into college (id, name , description, establish_year) value(23, 'ceshi', '', 2025);|
| | commit |
| select * from college c  where id > 20; | |
| rollback| |

* 由于事务1的Read view是在执行select时才会


## 案例2: InnoDB RR级别下的幻读(应该算吧)

| 事务1 | 事务2 |
|----| ---|
| begin | |
| | begin |
| | (1) insert into college (id, name , description, establish_year) value(23, 'ceshi', '', 2025);|
| (2) select * from college c  where id > 20; | |
| | commit |
| update college set name='ceshi1' where id=23; | |
| select * from college c  where id > 20; | |
| rollback| |

* 执行会发现两次查询的结果条数不一样, 因为23这条记录最新版本上修改这条记录的事务id就是自己, 所以符合readview规则
* 如果事务在序列化级别下执行, 由于写操作会阻塞读操作, 事务1的第一次select操作会被阻塞
  * 如果交换1/2两句在时间上的顺序, 则事务2的写操作会被事务1查询时的共享锁阻塞

