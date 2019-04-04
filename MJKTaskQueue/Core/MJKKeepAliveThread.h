//
//  KeepAliveThread.h
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^MJKKeepAliveBlock)(void);

@interface MJKKeepAliveThread : NSThread

+(MJKKeepAliveThread *)keepAliveThread;

- (void)executeTaskBlock:(MJKKeepAliveBlock)taskBlock completedBlock:(MJKKeepAliveBlock)completedBlock;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
