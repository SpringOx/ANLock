//
//  ANReadWriteLock.m
//  ANLock Demo
//
//  Created by SpringOx on 12/25/15.
//  Copyright © 2015 SpringOx. All rights reserved.
//

#import "ANReadWriteLock.h"
#include <pthread.h>

@interface ANReadWriteLock()
{
@private
    int _readCount;
    pthread_mutex_t _readMutex;
    pthread_mutex_t _writeMutex;
}

@end

@implementation ANReadWriteLock

- (void)dealloc
{
    pthread_mutex_destroy(&_readMutex);
    pthread_mutex_destroy(&_writeMutex);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
        _readCount = 0;
        
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        //经压力测试，递归方式可能会导致锁一直wait，SpringOx
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
        pthread_mutex_init(&_readMutex, &attr);
        pthread_mutex_init(&_writeMutex, &attr);
        pthread_mutexattr_destroy(&attr);
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
    pthread_mutex_lock(&_readMutex);
    if (_readCount >= 0 && ++_readCount == 1) {
        pthread_mutex_lock(&_writeMutex);
    }
    pthread_mutex_unlock(&_readMutex);
}

- (void)readUnlock
{
    pthread_mutex_lock(&_readMutex);
    if (_readCount > 0 && --_readCount == 0) {
        pthread_mutex_unlock(&_writeMutex);
    }
    pthread_mutex_unlock(&_readMutex);
}

- (void)writeLock
{
    pthread_mutex_lock(&_writeMutex);
}

- (void)writeUnlock
{
    pthread_mutex_unlock(&_writeMutex);
}

@end
