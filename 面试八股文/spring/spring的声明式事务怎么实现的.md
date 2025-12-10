# 声明式事务

* 通过spring的AOP实现, 实际上是一个Around切面
* TransactionInteceptor首先根据@Transactional注解的内容读取TransactionAttribute, 获取事务的传播性等属性
  * Inteceptor负责AOP
* 根据Attribute从transactionManager获取事务状态, 可能会创建事务或者加入当前事务, 这一步有可能因为事务的传播性原因执行失败
  * Manager负责传播性解析, save_point, 隔离级别, 超时, 只读, 回滚条件等信息, 并负责存储线程当前的事务状态, 结合事务属性和当前事务状态决定事务内的方法要在新事务执行还是原来的事务内运行
* 执行事务内的方法代码
* 根据异常情况, 决定是提交事务还是回滚事务