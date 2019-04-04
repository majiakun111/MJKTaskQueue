//
//  KeepAliveThread.m
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import "MJKKeepAliveThread.h"

@interface MJKKeepAliveBlockWrapper : NSObject

@property(nonatomic, copy) MJKKeepAliveBlock taskBlock;
@property(nonatomic, copy) MJKKeepAliveBlock completedBlock;

@end

@implementation MJKKeepAliveBlockWrapper

@end

@interface MJKKeepAliveThread ()

@property(nonatomic, assign) BOOL isStop;

@end

@implementation MJKKeepAliveThread

+(MJKKeepAliveThread *)keepAliveThread {
    __block MJKKeepAliveThread *thread = nil;
    void (^block)(void) = ^{
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
            while (!thread.isStop) {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
        }
    };
    
    thread = [[MJKKeepAliveThread alloc] initWithTarget:self selector:@selector(run:) object:block];
    thread.isStop = NO;
    return thread;
}

- (void)executeTaskBlock:(MJKKeepAliveBlock)taskBlock completedBlock:(MJKKeepAliveBlock)completedBlock {
    if (!self.isExecuting) {
        [self start];
    }
    
    MJKKeepAliveBlockWrapper *wrapper = [[MJKKeepAliveBlockWrapper alloc] init];
    wrapper.taskBlock = taskBlock;
    wrapper.completedBlock = completedBlock;
    [self performSelector:@selector(coreExecuteTaskWithWrapper:) onThread:self withObject:wrapper waitUntilDone:NO];
}

- (void)stop {
    [self performSelector:@selector(coreStop) onThread:self withObject:nil waitUntilDone:NO];
}

#pragma mark - PrivateMethod
//线程启动
+ (void)run:(void (^)(void))block {
    if (block) {
        block();
    }
}

- (void)coreExecuteTaskWithWrapper:(MJKKeepAliveBlockWrapper *)wrapper {
    if (wrapper.taskBlock) {
        wrapper.taskBlock();
        wrapper.taskBlock = nil;
    }
    
    if (wrapper.completedBlock) {
        wrapper.completedBlock();
        wrapper.completedBlock = nil;
    }
}

- (void)coreStop {
    self.isStop = YES;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

@end
