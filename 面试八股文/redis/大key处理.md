# 大key处理

* 大key不能直接删, 否则可能会导致节点卡住不能对外提供服务, 从库同步这个命令时也会卡住
* 如果卡住了, sentinel/cluster-slave会误判主节点挂掉了, 然后可能出现主从切换

## 大Key的预警

* 通过promethus监控hashkey的大小, 设置告警规则, 比如string, hash的内存大小, zset的大小之类的

## 大key的删除

* String 底层是SDS, 一般直接删没问题
* Hash类型建议通过HSCAN一次删几百个
* List通过LMPOP一次移除一批
* SET, ZSET通过scan+rem

## 大key预防

* 通过自定义的cacheManager自己实现分片, 对于spring-cache那种依赖hash结构的可以根据hashkey和配置的分片数在cacheName上把序号拼上去, 这样就可以将一个hash拆成多个key分布在集群的不同节点


## 大list的处理

* 分场景: 队列/缓存
* 作为消息队列的场景首先个人不太喜欢用redis作为消息队列, 另外使用消息队列建议使用Stream而不是list
  * 堆积太多的话得检查消费者性能, 另外建议换用专门的消息中间件
* 作为缓存的化首先是要从业务上考量有没有必要缓存太多条, 因为list缓存很多时候是缓存的前N条
* 另外可以把一个list拆成多个, 分段缓存到redis中, 这样也可以在一定程度上避免lrange性能退化的问题

