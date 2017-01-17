//
//  MyNetWrok.h
//  StudyAVPlayer
//
//  Created by weiman on 2016/12/2.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyNetWrok : NSObject

/**
 单例对象
 */
+(MyNetWrok*)sharedMyNetWrok;
/**
 请求视频列表
 */
+(void)requestVideoList:(void(^)(NSArray * listArr))listArrBlock;

@end
