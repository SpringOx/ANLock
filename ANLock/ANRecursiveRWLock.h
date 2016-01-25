//
//  ANRecursiveRWLock.h
//  ANLock Demo
//
//  Created by SpringOx on 12/21/15.
//  Copyright © 2015 SpringOx. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ANRecursiveRWLock : NSObject<NSLocking>

- (void)readLock;

- (void)readUnlock;

- (void)writeLock;

- (void)writeUnlock;

@end
