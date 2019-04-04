//
//  MJKTaskQueue.m
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import "MJKTaskQueue.h"
#import "MJKKeepAliveThread.h"
#import <objc/runtime.h>

@interface MJKKeepAliveThread (Private)

@property(nonatomic, assign) BOOL isIdle;

@end

@implementation MJKKeepAliveThread (Private)

@dynamic isIdle;

- (void)setIsIdle:(BOOL)isIdle {
    objc_setAssociatedObject(self, @selector(isIdle), @(isIdle), OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)isIdle {
    return [objc_getAssociatedObject(self, @selector(isIdle)) boolValue];
}

@end


@interface MJKTask (Private)

@property(nonatomic, weak) MJKKeepAliveThread *thread;

@end

@implementation MJKTask (Private)

@dynamic thread;

- (void)setThread:(MJKKeepAliveThread *)thread {
    objc_setAssociatedObject(self, @selector(thread), thread, OBJC_ASSOCIATION_RETAIN);
}

- (MJKKeepAliveThread *)thread {
    return objc_getAssociatedObject(self, @selector(thread));
}

@end

@interface MJKTaskQueue ()

@property(nonatomic, assign) NSInteger maxConcurrentTaskCount;
@property(nonatomic, strong) NSMutableArray<MJKKeepAliveThread *> *threads;

@property(nonatomic, strong) dispatch_semaphore_t semaphore;

@property(nonatomic, strong) NSMutableArray<MJKTask *> *normalPriorityTasks;
@property(nonatomic, strong) NSMutableArray<MJKTask *> *highPriorityTasks;
@property(nonatomic, strong) NSMutableArray<MJKTask *> *executingTasks;

@end

@implementation MJKTaskQueue

- (instancetype)initWithMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount {
    self = [super init];
    if (self) {
        _maxConcurrentTaskCount = maxConcurrentTaskCount;
        
        _threads = [[NSMutableArray alloc] init];
        NSArray<MJKKeepAliveThread *> *threads = [self createThreadsWithCount:_maxConcurrentTaskCount];
        [_threads addObjectsFromArray:threads];
        
        _semaphore = dispatch_semaphore_create(1);

        _normalPriorityTasks = [[NSMutableArray alloc] init];
        _highPriorityTasks = [[NSMutableArray alloc] init];
        _executingTasks = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)addTask:(MJKTask *)task {
    [self safeAddTask:task];
    
    [self executeNextTask];
}

- (void)cancelTask:(MJKTask *)task {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    if (task.priority == MJKTaskPriorityForForNormal && [self.normalPriorityTasks containsObject:task]) {
        [self.normalPriorityTasks removeObject:task];
    } else if (task.priority == MJKTaskPriorityForForHigh && [self.highPriorityTasks containsObject:task]) {
        [self.highPriorityTasks addObject:task];
    } else {
        [task.thread stop];
        [self.threads removeObject:task.thread];
        
        [self.executingTasks addObject:task];
        
        NSArray<MJKKeepAliveThread *> *threads = [self createThreadsWithCount:1];
        [self.threads addObjectsFromArray:threads];
    }
    
    dispatch_semaphore_signal(self.semaphore);
}

- (void)cancelAllTasks {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

    [self.normalPriorityTasks removeAllObjects];
    [self.highPriorityTasks removeAllObjects];
    
    [self.executingTasks enumerateObjectsUsingBlock:^(MJKTask *  _Nonnull executingTask, NSUInteger idx, BOOL * _Nonnull stop) {
        [executingTask.thread stop];
        
        [self.threads removeObject:executingTask.thread];
    }];
    
    [self.executingTasks removeAllObjects];
    
    NSInteger needCreateThreadCount = self.maxConcurrentTaskCount - [self.threads count];
    if (needCreateThreadCount > 0) {
        NSArray<MJKKeepAliveThread *> *threads = [self createThreadsWithCount:needCreateThreadCount];
        [self.threads addObjectsFromArray:threads];
    }
    
    dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - PrivateMethod

- (NSArray<MJKKeepAliveThread *> *)createThreadsWithCount:(NSInteger)count {
    NSMutableArray<MJKKeepAliveThread *> *threads = @[].mutableCopy;
    for (NSInteger index = 0; index < count; index++) {
        MJKKeepAliveThread *thread = [MJKKeepAliveThread keepAliveThread];
        thread.isIdle = YES;
        [threads addObject:thread];
    }
    
    return threads;
}

- (MJKKeepAliveThread *)getIdleThread {
    __block MJKKeepAliveThread *thread = nil;
    [self.threads enumerateObjectsUsingBlock:^(MJKKeepAliveThread * _Nonnull  obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.isIdle) {
            return;
        }
        
        thread = obj;
        *stop = YES;
    }];
    
    return thread;
}

- (void)safeAddTask:(MJKTask *)task {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

    if (task.priority == MJKTaskPriorityForForNormal) {
        [self.normalPriorityTasks addObject:task];
    } else if (task.priority == MJKTaskPriorityForForHigh) {
        [self.highPriorityTasks addObject:task];
    }
    
    dispatch_semaphore_signal(self.semaphore);
}

- (void)executeNextTask {
    dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
    
    do {
        MJKKeepAliveThread *thread = [self getIdleThread];
        if (!thread) {
            break;
        }
        
        MJKTask *task = [self.highPriorityTasks firstObject];
        if (task) {
            [self.highPriorityTasks removeObject:task];
        }
        if (!task) {
            task = [self.normalPriorityTasks firstObject];
            [self.normalPriorityTasks removeObject:task];
        }
        if (!task) {
            break;
        }
        
        [self.executingTasks addObject:task];
        
        thread.isIdle = NO;
        thread.name = task.name;
        task.thread = thread;
        __weak typeof(self) weakSelf = self;
        __weak typeof(thread) weakThread = thread;
        __weak typeof(task) weakTask = task;
        [thread executeTaskBlock:task.block completedBlock:^{
            weakThread.isIdle = YES;
            [weakSelf.executingTasks removeObject:weakTask];
            [weakSelf executeNextTask];
        }];
    } while (0);
    
    dispatch_semaphore_signal(self.semaphore);
}

@end
