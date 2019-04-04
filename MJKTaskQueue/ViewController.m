//
//  ViewController.m
//  MJKTaskQueue
//
//  Created by Ansel on 2019/4/4.
//  Copyright © 2019 Ansel. All rights reserved.
//

#import "ViewController.h"
#import "MJKTaskQueue.h"

@interface ViewController ()

@property(nonatomic, strong) NSOperationQueue *operationQueue;

@property(nonatomic, strong) MJKTaskQueue *taskQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.taskQueue = [[MJKTaskQueue alloc] initWithMaxConcurrentTaskCount:2];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    MJKTask *task = [MJKTask taskWithBlock:^{
        NSLog(@"xxxxxxxxxxx");
        
        sleep(10);
        
        NSLog(@"xxxxxx: %@", [NSThread currentThread]);
    }];
    [task setName:[NSString stringWithFormat:@"threadName_mjk"]];
    [self.taskQueue addTask:task];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.taskQueue cancelTask:task];
    });
}

@end
