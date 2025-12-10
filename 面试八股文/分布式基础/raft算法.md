# 讲讲raft算法

* raft算法是一个分布式一致性算法, 主要分为leader选举, 日志同步, 安全性保证三块

## leader选举

* Raft中有三种角色: Leader, 候选人, Follower
* Follower维持和Leader的心跳, 超过一定时间没有收到心跳回复后认为leader挂了, 将自己的term++, 成为候选人
* 发送消息给其他follower, 要求其他follower投票给自己让自己成为新leader, 同时自己也给自己投一票
* 其他节点收到后发现如果候选人的term大于等于自己, 并且自己在本term内还没有投过票, 就将票投给他
  * 如果term大于自己, 则自己会降级成为follower
* 得票过半成为leader, 未过半则随机等待一段时间后再次发起投票请求
  * 随机等待可以避免两个节点一直竞争leader, 得票无法过半的情况

## 日志复制

* 客户端向leader写入日志
* leader将写入操作追加到自己的日志中
* leader向多数follower发起日志追加调用
* 半数以上follower返回成功后,leader将数据设置为commited, 
* leader回复客户端数据提交成功
* leader在心跳中通知follower数据commited
* follower执行对应操作, 将操作设置为commited

## 安全性原则

* 如果两个节点的term相同, 那么日志完全相同
  * appendEntries时如果不同, 会删除冲突的再重写
* 一条日志被提交, 那么他会出现在未来的任意leader中, 新leader不会丢日志
  * leader投票的时候不能给日志落后于自己的节点投票