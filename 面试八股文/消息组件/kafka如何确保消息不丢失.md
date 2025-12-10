# kafka怎么保证消息不丢失

* 消息确认机制: 可以通过acks机制来控制; 允许通过配置同步到全部ISR之后再确认消息提交成功
* 另外ISR也可能只剩一个, 这时就需要配置至少被多少了follower才能算消息提交成功

# 内部同步过程

## 基本概念

* AR: 有这个分区的副本的所有节点构成这个分区的AR
* ISR: 保持和分区leader数据同步的节点构成ISR, ISR是AR的子集
* HW: AR里面所有副本的最新offset的最小值+1, 这也是消费者可以消费的消息上限
  * leader收到的消息, 所有ISR都拉到了, 才会更新ISR的HW
* LW: 低水位, 根消息清除有关
* LEO: 每个副本的最新offset+1

## ISR伸缩

* 正常情况下follower能维持和leader的消息同步, 保持在ISR中, 如果节点挂掉, 或者网络拥堵就可能不能及时同步leader的消息, 
  * 副本管理器定时检查follower与leader的消息的时间差值, 如果差太多, 会收缩ISR, 如果达到标准则加入ISR

## partition的LEO和HW维护

* leader收到消息之后记录本地日志, 增加自己的LEO
* follower携带自己的LEO从leader拉消息, leader根据ISR节点拉消息的时候携带的LEO
* leader维护副本的LEO列表, leader拉消息的时候会把自己的HW发给follower 
* follower写入自己的日志, 更新LEO, 副本也要维护一个HW, 取leader给的HW和自己维护的HW的较小值
* 然后携带新的LEO继续拉消息, leader就能感知到副本的LEO变化, 也就能维护整个分区的高水位

* 还是用epoch机制来避免节点挂掉的时候的丢消息  


