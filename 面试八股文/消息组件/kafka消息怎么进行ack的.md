# ACK

* 生产者的消息ack
* 消费者的消息ack

## 生产者

* 根据配置有多种确认方式: 只要leader确认发送成功, 就算发送成功; 所有isr确认收到才算发送成功; 可以辅助要求至少多少个副本收到才算发送成功;
* leader收到消息后先自己记录日志, 如果只要求leader收到就返回, 那么就可以返回生产者发送成功了; 或者isr只有一个副本, 也没要求至少同步多个副本, 也可以直接返回; 如果还要等同步给其他follower, leader会进入超时等待, 等follower把消息拉走
* follower拉消息会携带自己的LEO, leader收到请求时各follower的LEO
* leader把消息下发给follower, 同时携带当前的HW
* follower收到消息后记录到日志中, 同时更新自己的LEO和自己维护的HW
* follower继续携带LEO找leader拉消息, leader更新follower的leader信息
* 此时如果确认isr的LEO都超过了之前生产者发送的消息, 并且达到了要拉的分区数, leader就可以回复客户端确认了

## 消费者ack

* 自动ack: 默认5s在poll的时候提交上一次拉取到的最大offset; 如果消费者没有异步处理的逻辑可以认为不会丢消息
* 手动ack: 自己去调用commitSync/commitAsync