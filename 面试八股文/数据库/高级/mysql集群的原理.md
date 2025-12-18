# mysql集群的原理

## 主从同步的原理, 集群的基础: binlog同步->relaylog->从库写入

* 首先mysql的binlog同步是pull模型, 也就是从节点主动从主节点拉取日志
* 从库发送请求拉取从某个位置之后的binlog
* 主库将binlog发给从库
* 从库写本地的relaylog, 准备进行重放
* 从库根据relaylog重放结果写入自己的库, 完成一次写入的同步
   
### 半同步复制

* 主库需要等待至少一个从库确认写入了数据才回复客户端事务提交成功
* 增加了可靠性, 但是TPS会受影响, 只会在某些可靠性要求非常高的场景使用半同步

## 首先我们要考虑做集群的目的

* 高可用?
* 读写分离?
* 负载均衡?


## 高可用

* 首先是简单的主从复制+虚拟IP实现故障切换; (看起来怎么像MHA的方案???)
  * 主库对外提供服务, 从库同步主库的数据; 
  * 主库使用VIP对外提供写服务, 应用通过直连读节点做读写分离, 但是这样就需要对应用做处理, 要么部署一些应用只做查询直连读库, 要么在代码或代码框架层面侵入
  * 搭配中间件做读写分离, 比如使用ProxySQL配置读写转发规则, 服务连接统一连接proxySQL,由其将sql转发到VIP或者直接到从库
  * 缺点就是多个从节点时如果主节点挂了proxysql没法直接取消掉转发给新主库的读流量
* mysql mgr集群
  * 一般选用单主模式, 多主模式每个节点都可以写反而会因为认证降低QPS
  * 单主模式基于类paxos协议的方式进行选举leader节点
  * 写请求走leader节点, 通过原子广播传递事务; 半数以上同一才算事务提交成功
  * 挂掉的节点恢复时通过binlog拉平和其他节点的差距
  * 再搭配proxySQL之类的中间件做读写分离; 让proxysql监控performance_schema里面的replication_group_members表

### mgr单主模式

* 客户端将事务写请求发给Primary
* primary修改BufferPool, 生成redo & undo log, 准备binlog; 此时事务尚未提交
* 广播事务内容到其他节点(GCS): GTID,  write set, 
* Sencondary节点接收并根据write set判断是否有事务冲突
* sencondary返回primary ack/failed
* primary接收并计数, 自己计算为认证成功, 如果总共有一半的节点认证成功则事务可以提交
* primary提交事务
* 广播事务提交通知
* secondary提交事务, 更新自己已执行的事务列表
* primary响应客户端事务提交成功

## 读写分离

* 我们目前是用ProxySQL配置规则去做的
  * AWS并没有提供一个地址进行全自动的读写分离; clusterEndPoint读请求也会转发去主节点
  * 所以自己搞了ProxySql

## 负载均衡

* 业务分库缓解压力

