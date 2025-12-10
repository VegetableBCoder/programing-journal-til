# Mysql事务隔离级别实现方式

## 事务隔离级别

| 级别 | 问题 | 实现方式 |
|---- |---- |---- |
| 读未提交 | 脏读 | 不构造ReadView直接查询 |
| 读已提交 | 不可重复读 | 每次当前读创建快照 |
| 可重复读 | 幻读 | 首次当前读的时候创建ReadView |
| 序列化 | - |自动加上 lock in share mode |

## MVCC的原理 & 快照读怎么实现的

### ReadView

* 存活的事务ids: trx_ids
* 存活事务中最小的事务mid: min_trx_id
* 当前事务id:  cur_trx_id
* 创建readView时系统要分配的下一个事务id: max_trx_id

```
// trx_id = 版本链上的事务id
if (trx_id==cur_trx_id) {
    // 可以放到结果集中
}
if (trx_id< min_trx_id){
    // 事务在创建readView时已经完成, 可以放入结果集
}
if(trx_id in trx_ids){
    // 创建readView时事务还在运行, 需要沿着版本链找上一个版本进行判断
}
if(trx_id>=max_trx_id){
    // 创建readView之后生成的事务, 需要沿着版本链找上一个版本进行判断
}
```

### 版本链

* 在每一行有两个隐藏列: roll_pointer, 生成这个版本的事务id
* roll_pointer指向自己的undolog, undolog则有指针指向上一个版本的undo_log

# 不可重复读和幻读的区别

* 不可重复读强调的是两次读发现一行数据的某些字段被修改了
* 幻读强调的是两次读取的条数不一致
* mysql使用mvcc解决了大部分的幻读, 但是由于有事务id和当前事务id比较这一条规则, 仍然可以构造出幻读的场景
