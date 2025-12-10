# 事务传播方式

* REQUIRED: 没有就创建一个, 有就加入
* REQUIRED_NEW: 不管有没有, 都创建一个新的事务
* NESTED: 没有就创建, 有就通过SAVEPOINT嵌套
* NOT_SUPPORT: 非事务执行, 有事务就挂起事务
* NEVER: 不能在事务里面执行, 有事务就报错
* MADATORY: 有事务加入, 没事务就报错
* SUPPORT: 有就加入, 没有就算了


## 树化记忆

- 外层没有事务?
  - 创建一个
    - 外层有事务?
      - SAVEPOINT嵌套: NESTED
      - 创建新的: REQUIRED_NEW
      - 加入: REQUIRED
      - 挂起: NOT_SUPPORT 
  - 无事务方式运行
    - 外层有事务?
      - 报错: NEVER
      - 加入: SUPPORT
  - 报错
    - MANDATORY

- 可以以无事务方式运行
  - 外层有事务则报错: NEVER
  - 外层有事务则挂起: NOT_SUPPORT
  - 加入外层事务: SUPPORT
- 必须有事务
  - 无论如何自己创建: REQUIRED_NEW
  - SAVEPOINT嵌套: NESTED
  - 有就加入: REQUIRED
  - 没有就报错: MANDATORY