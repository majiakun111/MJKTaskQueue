//
//  MJKTaskQueue.h
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJKTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface MJKTaskQueue : NSObject

- (instancetype)initWithMaxConcurrentTaskCount:(NSInteger)maxConcurrentTaskCount NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
@property(nonatomic, assign, readonly) NSInteger maxConcurrentTaskCount;

- (void)addTask:(MJKTask *)task;

- (void)cancelTask:(MJKTask *)task;

- (void)cancelAllTasks;

@end

NS_ASSUME_NONNULL_END
