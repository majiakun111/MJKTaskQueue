//
//  MJKTask.m
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import "MJKTask.h"

@interface MJKTask ()

@property(nonatomic, copy) MJKTaskBlock block;

@end

@implementation MJKTask

+ (instancetype)taskWithBlock:(MJKTaskBlock)block {
    MJKTask *task = [[self alloc] init];
    task.priority = MJKTaskPriorityForForNormal;
    task.block = block;
    return task;
}

@end
