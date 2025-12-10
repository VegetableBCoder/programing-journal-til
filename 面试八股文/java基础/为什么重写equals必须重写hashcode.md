# 为什么重写equals必须重写hashcode

## 可能会导致的问题

```java
// 假如Person只有name一个属性, equals重写为name的equalsIgnoreCase判断
Set<Person> set=new HashMap();
set.add(new Person("Tom"));
set.add(new Person("tom"));
// 此时正确逻辑是set里面有一个person元素, 因为他俩是equals的, 实际上会有两个, 因为他俩的hashcode不同
```

## 重写hashcode和equals可能的问题

```java
Set<Person> set=new HashMap();
// 假设Person自己实现了equals和hashcode, 按照name计算hashcode
Person p=new Person("Tom");
set.add(p);

p.setName("张三");

boolean b=set.contains(p);

// 正确的逻辑应该是true, 但是实际上得到的很可能是false, 因为contains的时候计算得到的hash确定的slot很可能不是add时确定的slot, 自然就没法找到原来的对象
```

## 最佳实践

* 重写hashcode尽量选择final的属性, 对象变更时hashcode不变, hash相关容器的get, contains保证slot不变, 能通过相同对象或equals判断能正确处理逻辑

## 其他

* 当自己实现了hashcode时, 对象头上的hashcode就没用了, 使用时需要计算

### 没有重载时是怎么进行equals和hashcode的?

* 第一次调用hashcode时随机生成的int值, 放入对象头里面, 生成之后不会变
* 没有重载的equals只能判断引用是否指向同一个对象