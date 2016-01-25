//
//  ANRecursiveRWLock.m
//  ANLock Demo
//
//  Created by SpringOx on 12/21/15.
//  Copyright © 2015 SpringOx. All rights reserved.
//

#import "ANRecursiveRWLock.h"
#include <pthread.h>

@interface ANRecursiveRWLock()
{
@private
    int _state;
    pthread_mutex_t _mutex;
    pthread_cond_t _cond;
}

@end

@implementation ANRecursiveRWLock

- (void)dealloc
{
    pthread_mutex_destroy(&_mutex);
    pthread_cond_destroy(&_cond);
}

- (instancetype)init
{
    self = [super init];
    if (self) {

        _state = 0;
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        //设置锁的属性为可递归
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&_mutex, &attr);
        pthread_mutexattr_destroy(&attr);
        
        pthread_cond_init(&_cond, NULL);
    }
    return self;
}

- (void)lock
{
    [self writeLock];
}

- (void)unlock
{
    [self writeUnlock];
}

- (void)readLock
{
    pthread_mutex_lock(&_mutex);
    while (_state < 0) {
        pthread_cond_wait(&_cond, &_mutex);
    }
    ++_state;
    pthread_mutex_unlock(&_mutex);
}

- (void)readUnlock
{
    pthread_mutex_lock(&_mutex);
    if (--_state == 0) {
        pthread_cond_signal(&_cond);
    }
    pthread_mutex_unlock(&_mutex);
}

- (void)writeLock
{
    pthread_mutex_lock(&_mutex);
    while (_state != 0) {
        pthread_cond_wait(&_cond, &_mutex);
    }
    _state = -1;
    pthread_mutex_unlock(&_mutex);
}

- (void)writeUnlock
{
    pthread_mutex_lock(&_mutex);
    _state = 0;
    pthread_cond_broadcast(&_cond);
    pthread_mutex_unlock(&_mutex);
}

@end