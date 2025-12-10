# Synchronied和Lock

## Synchronized 

* 修饰某个代码块的语法, 将其变为同步代码块, 进入同步代码块时需要获取到锁
* synchronized在方法上是不会被子类覆盖的方法继承的, 如果子类覆盖了父类的方法就必须自己决定这个方法要不要带synchronied
* 如果修饰的是静态方法, 则锁定的对象是这个类的Class对象
* 如果修饰某个类`synchronized (xxx.class)`, 锁定的也是Class对象

### wait notify等待通知模式

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class SynchronizedWaitNotify {


    private static final Object lock = new Object();
    /** volatile保证线程可见性 */
    public static volatile int counter = 1;
    private static final ExecutorService executor = Executors.newFixedThreadPool(2);

    public static void printOdd() throws Exception {
        synchronized (lock) {
            while (counter < 100) {
                if (counter % 2 == 0) {
                    lock.wait();
                }
                System.out.printf("ThreadA: %s\n", counter++);

                lock.notify();
            }
        }
    }

    public static void printEven() throws Exception {
        synchronized (lock) {
            while (counter < 100) {
                if (counter % 2 == 1) {
                    lock.wait();
                }
                System.out.printf("ThreadB: %s\n", counter++);
                lock.notify();
            }
        }
    }

    public static void main(String[] args) {
        executor.submit(() -> {
            try {
                printOdd();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
        executor.submit(() -> {
            try {
                printEven();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }
}
```

* 上面的demo代码实现了通过wait-notify两个线程轮流交替输出1-100的数字
* notify和wait只能在synchronized的代码快中使用, 否则会抛出异常
* 被唤醒之后二次检查的原因是防止虚假唤醒
* 推荐使用notifyAll


## Lock

* Lock是juc中提供的一个接口, 常见实现类有ReentrantLock, ReadWriteLock, FairLock, UnFairLock
* Lock是基于AQS实现的, 完全在用户态实现, 相比于synchroned中可能的重量级锁形态, 不需要内核态用户态切换
  * 所以可以看出在竞争并不激烈的时候synchronized的吞吐量可能高于lock, 而在高竞争烈度的情况下, Lock的吞吐量会高于synchronized

### lock unlock用法

* lock: 获取锁, 如果获取锁成功则继续执行，否则线程挂起(LockSupport.park())，进入waiting/timed_waiting
* unlock: 释放线程持有的锁(重入次数-1)

### newCondition

* 返回一个condition对象, 可以实现类似于synchronized的wait/notify机制
* wait, notify是object的方法, condition的调用方法是await/signal; 下面的代码用condition版本实现了两个线程交替打印1-100

```java
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.ReentrantLock;

public class ConditionWaitNotify {

    private static final ReentrantLock lock = new ReentrantLock();
    private static final Condition condition = lock.newCondition();
    /** volatile保证线程可见性 */
    public static volatile int counter = 1;
    private static final ExecutorService executor = Executors.newFixedThreadPool(2);

    public static void printOdd() throws Exception {
        lock.lock();
        while (counter < 100) {
            if (counter % 2 == 0) {
                condition.await();
            }
            System.out.printf("ThreadA: %s\n", counter++);
            condition.signal();
        }
        lock.unlock();
    }

    public static void printEven() throws Exception {
        lock.lock();
        while (counter < 100) {
            if (counter % 2 == 1) {
                condition.await();
            }
            System.out.printf("ThreadB: %s\n", counter++);
            condition.signal();
        }
        lock.unlock();
    }

    public static void main(String[] args) {
        executor.submit(() -> {
            try {
                printOdd();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
        executor.submit(() -> {
            try {
                printEven();
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }
}
```

### ReentrantLock

* 可重入锁, 即一个线程已经获取到锁, 再次尝试获取这个锁时不会死锁

### Read/WriteLock

* 读锁是共享的, 写锁是排他的

### 公平锁和非公平锁

* 公平锁必须老老实实丢到AQS队尾去排队, 而非公平锁可以直接尝试获取一次锁, 取不到再丢队尾

## synchronized和ReentrantLock的异同

* synchronied是java关键字, 其实现是由jvm完成的, 在竞争烈度不同的时候会有不同的实现, 其中重量级锁会涉及内核态用户态切换; Lock是AQS实现的, 完全在用户态实现, 不需要切换
* synchronized没有办法控制等锁超时机制, 而Lock可以控制等锁超时, 也可以使用tryLock仅尝试一下能不能拿到锁
* synchronized的锁释放是jvm控制的, 而lock需要自己注意异常等情况的锁释放
* 低烈度的竞争情况下synchronized性能略优于Lock, 高竞争烈度的情况下Lock的吞吐量会高于synchronized

## 其他

* 上面的demo代码实现的任务: 两个线程交替打印1-100, 还可以考虑使用信号量, BlockingQueue(size=1),LockSupport.park/unpark等方式实现; 后续可以补充实现