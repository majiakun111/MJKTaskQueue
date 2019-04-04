//
//  MJKTask.h
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MJKTaskBlock)(void);

typedef NS_ENUM(NSInteger, MJKTaskPriority) {
    MJKTaskPriorityForUnknow = -1,
    MJKTaskPriorityForForNormal = 0,
    MJKTaskPriorityForForHigh = 1
};

@interface MJKTask : NSObject

@property(nonatomic, assign) MJKTaskPriority priority;
@property(nonatomic, copy) NSString *name;
@property(nonatomic, copy, readonly) MJKTaskBlock block;

+ (instancetype)taskWithBlock:(MJKTaskBlock)block;

@end

NS_ASSUME_NONNULL_END
