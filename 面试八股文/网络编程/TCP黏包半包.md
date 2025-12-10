# TCP黏包半包

* 由于TCP是面向字节流的协议, 本层只负责把字节流发给目标, 不管上层怎么在字节流中划定的消息边界
* 粘包: TCP底层也会为了节省包的发送次数(毕竟每次发送都要带协议头), 会尝试把上层要发送的多条消息合并成一条发送, 接收端没有及时读取, 也会把多个包合在一起等待处理;
* 半包: MTU/MSS的限制, 一次可能不能把上层要发的一条消息通过一个包发给目标, 需要分多次发;
  * MTU是二层限制, MSS是四层的限制 MSS=TMU - 二层占用(VLAN tag) - IP Header Size - TCP Header Size

## 解决方式

* 本质是应用层协议设计问题, 可以选择定长或变长编码方式
  * 定长就是循环读取固定长度的内容进行解析, 长度不足则等待
  * 变长就是循环读取header的定长部分获取协议, 判断剩下的能否组成完整的消息
* NIO下手动处理
  * 粘包: 从channel读取到buffer之后根据长度信息读取获得的长度的数据内容
  * 半包: 先mark一下buffer的position, 获取长度后发现剩余的内容不足, 恢复buffer的position继续等待
* Netty下内置解码器
  * 定长编码: FixedLengthFrameDecoder
  * 变长编码: LengthFieldBasedFrameDecoder
