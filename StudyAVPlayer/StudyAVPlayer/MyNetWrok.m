//
//  MyNetWrok.m
//  StudyAVPlayer
//
//  Created by weiman on 2016/12/2.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import "MyNetWrok.h"
#import "AFNetworking.h"

@implementation MyNetWrok

+(MyNetWrok *)sharedMyNetWrok{
    static MyNetWrok * shared=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared=[[MyNetWrok alloc]init];
    });
    return shared;
}

static AFHTTPSessionManager * manager;
/**
 为了防止AFHTTPSessionManager创建的时候导致的内存泄露问题
 */
+(AFHTTPSessionManager *)sharedHttpSession{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[AFHTTPSessionManager manager];
        manager.requestSerializer.timeoutInterval = 10;
    });
    return manager;
}

/**
 请求视频列表
 */
+(void)requestVideoList:(void(^)(NSArray * listArr))listArrBlock{
    NSString * strUrl=@"http://c.m.163.com/nc/video/home/0-10.html";
    //AFHTTPSessionManager * manager=[AFHTTPSessionManager manager];
    AFHTTPSessionManager * manager=[MyNetWrok sharedHttpSession];
    manager.responseSerializer=[AFHTTPResponseSerializer serializer];
    [manager GET:strUrl parameters:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary * jsonDic=[NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        NSArray * videoList=jsonDic[@"videoList"];
        listArrBlock(videoList);
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
    }];
}

@end
