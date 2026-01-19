# SpringBoot启动流程


* 先new一个SpringBootApplication
* 确认环境: webmvc? webflux? 非web?; 
* 获取springboot的spi spring.factories, 决定要自动装配的配置类
* 加载Environment, 解析命令参数, 加载配置文件
* 创建ApplicationContext; 根据环境选择加载什么ApplicationContex
* 走ApplicationContext的refresh流程
* 执行springboot的一些扩展点: ApplicationRunner, CommandLineRunner等















创建一个SpringApplicationContext对象
确定上下文类型, webmvc? webflux? 非web? 确认加载什么上下文类型
加载spring.factories, 决定进行spi的配置类
加载配置文件, 构建environments
创建上下文对象
执行上下文对象的refresh方法, 创建bean
执行springboot的扩展点方法, 如applicationRunner
