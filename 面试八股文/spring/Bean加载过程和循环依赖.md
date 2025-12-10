# Bean加载过程

* 启动时要先把BeanDefinition注册到beanFactory
* 根据BeanName获取BeanDefinition
* 通过反射实例化bean
* 实例化的对象封装成ObjectFactory扔到三级缓存
* 执行populateBean对Bean进行属性注入
* 执行BenPostProcessor的beaforInitialize
* 执行初始化方法: 如InitializingBean,  如InitialzingBean和PostConstruct方法
* 执行BeanPostProcessor的afterInitialize
* 清理三级缓存, 二级缓存, 放入一级缓存

## 如果存在循环依赖

* 首先循环依赖是通过三级缓存和BeanFactory获取早期引用时提前进行代理实现的

* A执行 populateBean因为1,2,3级缓存都找不到B, 会去创建依赖的Bean B;
* 对B执行Populate的时候会发现需要Bean A, 这时候可以在三级缓存找到一个ObjectFactory;
* 执行这个ObjectFactory的getObject方法, 此时会对Bean A执行BeanPostProcessor的getEarlyRefrence方法, 尽量提前获取到代理对象
* getObject执行完清理A的三级缓存, 放入二级缓存中, 接着完成B的初始化, 然后执行BeforeInitialize, initialize, afterInitialize 完成B的代理
* Bean B创建完成后, 将其绑定到A的属性上
* 执行BeforeInitialize, initialize, afterInitialize; 如果这个Bean已经在getEarlyReference中代理过了, 不需要PostProcessor的代理逻辑了, 则跳过代理的步骤
* 最后还要做一次检查, 如果不允许绑定早期引用又有Bean在属性上绑定了自己的早期引用, 则Bean会创建失败, 抛出异常

