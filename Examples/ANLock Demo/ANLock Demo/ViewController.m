//
//  ViewController.m
//  ANLock Demo
//
//  Created by SpringOx on 12/21/15.
//  Copyright © 2015 SpringOx. All rights reserved.
//

#import "ViewController.h"
#import <pthread.h>
#import <libkern/OSAtomic.h>
#import "ANReadWriteLock.h"
#import "ANRecursiveRWLock.h"

@interface ViewController ()
{
    dispatch_semaphore_t _semaphore;
    ANRecursiveRWLock *_rwLock;
    pthread_mutex_t _mutex;
    int _readWriteFlag;
}

@property (atomic, assign) int atomicFlag;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)didPressTestButtonAction:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    switch (btn.tag) {
        case 0:
            [self testLockList];
            break;
        case 1:
            [self test_dispatch_semaphore];
            break;
        case 2:
            [self testOSSpinLock];
            break;
        case 3:
            [self testReadWriteLock];
            break;
        case 4:
            [self testRecursiveRWLock];
            break;
        case 5:
            [self testRWReadPerformance];
            break;
        case 6:
            [self testMutexReadPerformance];
            break;
            
        default:
            break;
    }
}

#pragma mark -

- (void)testLockList
{
    CFTimeInterval timeBefore;
    CFTimeInterval timeCurrent;
    NSUInteger i;
    //一千万次的锁操作执行
    NSUInteger count = 1000*10000;
    
    //@synchronized
    id obj = [[NSObject alloc]init];;
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        @synchronized(obj){
        }
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("@synchronized used : %f\n", timeCurrent-timeBefore);
    
    //NSLock
    NSLock *lock = [[NSLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [lock lock];
        [lock unlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("NSLock used : %f\n", timeCurrent-timeBefore);
    
    //NSRecursiveLock
    NSRecursiveLock *recursiveLock = [[NSRecursiveLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [recursiveLock lock];
        [recursiveLock unlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("NSRecursiveLock used : %f\n", timeCurrent-timeBefore);
    
    //NSCondition
    NSCondition *condition = [[NSCondition alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [condition lock];
        [condition unlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("NSCondition used : %f\n", timeCurrent-timeBefore);
    
    //NSConditionLock
    NSConditionLock *conditionLock = [[NSConditionLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [conditionLock lock];
        [conditionLock unlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("NSConditionLock used : %f\n", timeCurrent-timeBefore);
    
    //ANReadWriteLock write
    ANReadWriteLock *wLock = [[ANReadWriteLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [wLock writeLock];
        [wLock writeUnlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("ANReadWriteLock write used : %f\n", timeCurrent-timeBefore);
    
    //ANReadWriteLock read
    ANReadWriteLock *rLock = [[ANReadWriteLock alloc]init];
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        [rLock readLock];
        [rLock readUnlock];
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("ANReadWriteLock read used : %f\n", timeCurrent-timeBefore);
    
    //pthread_mutex
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    /*
     pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
     pthread_mutexattr_t attr;
     pthread_mutexattr_init(&attr);
     //设置锁的属性为可递归
     pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
     pthread_mutex_init(&mutex, &attr);
     pthread_mutexattr_destroy(&attr);
     */
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        pthread_mutex_lock(&mutex);
        pthread_mutex_unlock(&mutex);
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("pthread_mutex used : %f\n", timeCurrent-timeBefore);
    
    //dispatch_semaphore
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        dispatch_semaphore_signal(semaphore);
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("dispatch_semaphore used : %f\n", timeCurrent-timeBefore);
    
    //OSSpinLockLock
    OSSpinLock spinlock = OS_SPINLOCK_INIT;
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        OSSpinLockLock(&spinlock);
        OSSpinLockUnlock(&spinlock);
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("OSSpinLock used : %f\n", timeCurrent-timeBefore);
    
    //Atomic Flag
    timeBefore = CFAbsoluteTimeGetCurrent();
    for(i=0; i<count; i++){
        self.atomicFlag = 1;
    }
    timeCurrent = CFAbsoluteTimeGetCurrent();
    printf("Atomic Set/Get used : %f\n", timeCurrent-timeBefore);
}

#pragma mark -

- (void)test_dispatch_semaphore
{
    //主线程中
    _semaphore = dispatch_semaphore_create(1);
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        [self threadMethod1];
        sleep(3);
        dispatch_semaphore_signal(_semaphore);
    });
    
    //线程2
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(1);
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        [self threadMethod2];
        dispatch_semaphore_signal(_semaphore);
    });
}

- (void)testOSSpinLock
{
    //主线程中
    __block OSSpinLock spinlock = OS_SPINLOCK_INIT;
    
    //线程1
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        OSSpinLockLock(&spinlock);
        [self threadMethod1];
        sleep(3);
        OSSpinLockUnlock(&spinlock);
    });
    
    for (int i=0; i<10; i++) {
        //线程2
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            OSSpinLockLock(&spinlock);
            [self threadMethod2];
            OSSpinLockUnlock(&spinlock);
        });
    }
}

- (void)threadMethod1
{
    // 测试可重入性
    /*
     dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
     NSLog(@"%@",NSStringFromSelector(_cmd));
     dispatch_semaphore_signal(_semaphore);
     */
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

- (void)threadMethod2
{
    NSLog(@"%@",NSStringFromSelector(_cmd));
}

#pragma mark -

- (void)testReadWriteLock
{
    ANReadWriteLock *rwLock = [[ANReadWriteLock alloc] init];
    
    //线程Write
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [rwLock writeLock];
        [self writeMethod];
        sleep(3);
        [rwLock writeUnlock];
    });
    
    for (int i=0; i<3; i++) {
        for (int j=0; j<5; j++) {
            //线程Read
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sleep(1);
                [rwLock readLock];
                [self readMethod];
                [rwLock readUnlock];
            });
        }

        //线程Write
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            [rwLock writeLock];
            [self writeMethod];
            [rwLock writeUnlock];
        });
    }
}

- (void)testRecursiveRWLock
{
    ANRecursiveRWLock *rwLock = [[ANRecursiveRWLock alloc] init];
    
    //线程Write
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [rwLock writeLock];
        [self writeMethod];
        sleep(3);
        [rwLock writeUnlock];
    });
    
    for (int i=0; i<3; i++) {
        for (int j=0; j<5; j++) {
            //线程Read
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                sleep(1);
                [rwLock readLock];
                [self readMethod];
                [rwLock readUnlock];
            });
        }
        
        //线程Write
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            sleep(1);
            [rwLock writeLock];
            [self writeMethod];
            [rwLock writeUnlock];
        });
    }
}

- (int)readMethod
{
    NSLog(@"%@ flag %d",NSStringFromSelector(_cmd), _readWriteFlag);
    return _readWriteFlag;
}

- (void)writeMethod
{
    ++_readWriteFlag;
    NSLog(@"%@ flag %d",NSStringFromSelector(_cmd), _readWriteFlag);
}

#pragma mark -

- (void)testRWReadPerformance
{
    _rwLock = [[ANRecursiveRWLock alloc] init];

    int count = 1000;
    for (int i=0; i<count; i++) {
        [NSThread detachNewThreadSelector:@selector(rwReadTest)
                                 toTarget:self
                               withObject:nil];
    }
}

- (void)rwReadTest
{
    [_rwLock readLock];
    usleep(100);
    NSLog(@"%@ flag %d",NSStringFromSelector(_cmd), _readWriteFlag);
    [_rwLock readUnlock];
}

- (void)testMutexReadPerformance
{
     pthread_mutexattr_t attr;
     pthread_mutexattr_init(&attr);
     //设置锁的属性为可递归
     pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
     pthread_mutex_init(&_mutex, &attr);
     pthread_mutexattr_destroy(&attr);

    int count = 1000;
    for (int i=0; i<count; i++) {
        [NSThread detachNewThreadSelector:@selector(mutexReadTest)
                                 toTarget:self
                               withObject:nil];
    }
}

- (void)mutexReadTest
{
    pthread_mutex_lock(&_mutex);
    usleep(100);
    NSLog(@"%@ flag %d",NSStringFromSelector(_cmd), _readWriteFlag);
    pthread_mutex_unlock(&_mutex);
}

@end
