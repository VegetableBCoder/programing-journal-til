# Sentinel

* 由一个或多个哨兵监控多个主服务器和它们下属的从服务器, 当主服务器下线时, 将某个从节点自动升级为主节点

## Sentinel与节点的通信

* 每10s一次 向主节点发送INFO命令, 获取信息
  * 获取主服务器自己的信息, 还有下面的从节点信息
* 与从节点创建命令连接和订阅连接， 10S一次向从节点发送INFO命令, 获取从节点的复制偏移量和其他信息
* 通过PUBLISH命令向主服务器的__sentinel__:hello频道发送sentinel自己的节点信息
* 持续订阅__sentinel__:hello频道, 接受其他sentinel广播的信息, 更新自己的sentinels字典信息

## 与其他sentinel的通信

* 从订阅的频道上发现新的sentinel之后, 创建一个与这个sentinel的命令连接

## 下线检测

* sentinel每秒一次向连接的节点发送PING命令, 如果没有收到PONG回复则主观认为其已经下线
* 向其他sentinel确认这个节点是否已经下线, 如果认为其已经下线的节点个数达到了阈值, 则认为此节点客观上已经下线
  * 这里使用的命令是SENTINEL is-master-down-by-addr
  * 不同sentinel载入的配置不一样, 可能客观下线判断的阈值不一样

## sentinel leader选举

* 所有sentinel都可以被选为leader
* 每次选举, 所有sentinel都将自己的配置纪元自增一次
* 每个纪元中, 所有sentinel都有一次将某个节点设置为leader的机会
* 发现主服务器进入客观下线的节点会发起投票, 要求其他节点将自己设置为leader
  * 向其他sentinel发送SENTINEL is-master-down-by-addr, 并且其中的run-id不是*
* leader资格先到先得, 节点收到同一纪元内的第一个请求会被同意, 后续的请求都被拒绝
  * 其他节点收到后, 如果没有设置局部leader, 将请求的节点设置为局部leader, 回复自己的配置纪元和局部leader run-id(再次收到其他节点的请求时不会变)
  * 源节点收到回复后如果检查回复中的epoch是否和自己一致, 然后按照run-id是否是自己给自己计票
* 如果sentinel被半数以上节点设置为leader则称为全局的leader
* 如果在规定时限内没有sentinel得票超过一半, 过一段时间再选举

## 故障转移过程

* 选出新的主节点 Raft
  * 排除已经下线, 断线的从节点
  * 排除5s内没有回复过Sentinel leader节点INFO命令的节点
  * 排除所有与主节点断线时间超过 down-after-millseconds * 10 ms的从节点, 保证剩下的节点都是没有过早与主节点断开的节点
  * 按照优先级排序, 选出优先级最高的节点
  * 如果有多个数据优先级相同的节点, 选择复制偏移量最大的节点(数据最新的)
  * 如果有多个偏移量相同的最新节点, 则按运行id选最小的
* 向选出的节点发送slave of no one, 使其变为主节点
* 将其他从节点变为新的主节点的从节点, 即修改复制目标
* 将旧的主服务器设置为从节点, 上线时发送SLAVE OF命令变为新的主节点的从节点