# broker controller

* kafka集群中的某个节点会被选举为controller, 负责在节点挂掉时为该leader在挂掉节点上的分区选择新leader

## controller的选举(ZK版本)

* 通过创建zk的/controller节点进行, 节点会尝试读取/controller节点的brokerid
* 如果都渠道的值不是-1, 说明有节点已经成功controller, 节点放弃竞选
* 如果读取不到/controller节点, 或者数据异常, 就尝试创建/controller节点, 创建成功就竞选成功
<br/>
* zk中还维护了一个controller_epoch节点, 每次选举成功这个值就自增, 与controller的交互都必须带上这个epoch, 如果小于controller自己保存的值, 则这个请求会被认为是无效请求, 如果请求的值大于controller自己保存的值, 说明新的节点被选为controller


## controller的职责

* 监听分区相关变化
  * 注册PartitionReassignmentHandler到/admin/reassign_partitions用于处理重分配
  * 注册IsrChangeNotificationHandler到/isr_change_notification, 处理isr变更
  * 注册PreferredReplicaElectionHandler到/admin/preferred-replica-election, 处理优先副本选举
* 监听topic相关变化
  * 注册TopicChangeHandler到/admin/topics, 监听topic增减
  * 注册TopicDeletionHandler到/admin/delete_topics. 处理topic删除动作
* 监听broker变化
  * 为/brokers/ids 节点注册BrokerCHangeHandler处理broker增加变化
* 从zk获取所有topic, 监听/brokers/topics/`<topic>`的分区分配变化
* 启动分区状态机， 副本状态机； 维护相关状态
* 更新集群元数据信息
* 如果开启了leader auto rebalance, 还要通过定时任务维护分区的优先副本均衡

