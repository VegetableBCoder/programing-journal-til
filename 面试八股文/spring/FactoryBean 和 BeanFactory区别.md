# BeanFactory和factoryBean的区别

* BeanFactory是容器的顶层接口, 典型的像DefaultListableBeanFactory, ApplicationContext这些实现, FactoryBean的本质是Bean, 允许我们通过自己的代码逻辑去创建bean, 直接控制一个Bean的创建
* 使用 &beanName的方法可以获取到FactoryBean