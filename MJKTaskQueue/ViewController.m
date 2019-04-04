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

//@property(nonatomic, strong) NSOperationQueue *operationQueue;

@property(nonatomic, strong) MJKTaskQueue *taskQueue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.operationQueue = [[NSOperationQueue alloc] init];
//    [self.operationQueue setMaxConcurrentOperationCount:2];
    
    self.taskQueue = [[MJKTaskQueue alloc] initWithMaxConcurrentTaskCount:2];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    MJKTask *task = [MJKTask taskWithBlock:^{
        NSLog(@"xxxxxxxxxxx");
        NSLog(@"xxxxxx: %@", [NSThread currentThread]);
    }];
    [task setName:[NSString stringWithFormat:@"threadName_mjk"]];
    [self.taskQueue addTask:task];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.taskQueue cancelTask:task];
    });
    
//    NSBlockOperation *task = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"xxxxxxxxxxx");
//
//        sleep(6);
//
//        NSLog(@"xxxxxx: %@", [NSThread currentThread]);
//    }];
//    [self.operationQueue addOperation:task];
//
//
//    NSBlockOperation *task1 = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"xxxxxxxxxxx1111");
//
//        sleep(6);
//
//        NSLog(@"xxxxxx111: %@", [NSThread currentThread]);
//    }];
//    [self.operationQueue addOperation:task1];
//
//    NSBlockOperation *task2 = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"xxxxxxxxxxx222");
//
//        sleep(3);
//
//        NSLog(@"xxxxxx222: %@", [NSThread currentThread]);
//    }];
//    [self.operationQueue addOperation:task2];
//
//    NSBlockOperation *task3 = [NSBlockOperation blockOperationWithBlock:^{
//        NSLog(@"xxxxxxxxxxx333");
//
//        sleep(3);
//
//        NSLog(@"xxxxxx333: %@", [NSThread currentThread]);
//    }];
//    [self.operationQueue addOperation:task3];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        [task cancel];
//        [task1 cancel];
//    });
}

@end
