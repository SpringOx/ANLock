//
//  ANReadWriteLock.h
//  ANLock Demo
//
//  Created by SpringOx on 12/25/15.
//  Copyright © 2015 SpringOx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANReadWriteLock : NSObject<NSLocking>

- (void)readLock;

- (void)readUnlock;

- (void)writeLock;

- (void)writeUnlock;

@end
