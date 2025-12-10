# SpringBoot启动流程


* 先new一个SpringBootApplication
* 确认环境: webmvc? webflux? 非web?; 
* 获取springboot的spi spring.factories, 决定要自动装配的配置类
* 加载Environment, 解析命令参数, 加载配置文件
* 创建ApplicationContext; 根据环境选择加载什么ApplicationContex
* 走ApplicationContext的refresh流程
* 执行springboot的一些扩展点: ApplicationRunner, CommandLineRunner等