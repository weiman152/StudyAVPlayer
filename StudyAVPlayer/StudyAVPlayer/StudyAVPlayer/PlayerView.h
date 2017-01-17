//
//  PlayerView.h
//  StudyAVPlayer
//
//  Created by weiman on 2016/11/29.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayerView : UIView

/**
 播放的url
 */
@property (nonatomic,copy) NSString * playUrl;
/**
 播放的title
 */
@property (nonatomic,copy) NSString * videoTitle;
/**
 播放时长（时分秒），可以有，也可以没有，开始播放之前会根据playUrl链接的视频计算出来
 */
@property (nonatomic,copy) NSString * duration;
/**
 添加playview的view,用于全屏之后恢复用的,一定要用weak,防止循环引用
 */
@property (nonatomic,weak)UIView * mySuperView;

/**
 创建playView的单例

 @return playView
 */
+(PlayerView *)playView;

/**
 初始化子控件的UI
 */
-(void)setUpInitSubViewsUI;

/**
 播放
 */
-(void)play;
/**
 暂停
 */
-(void)pause;
/**
 移除
 */
-(void)remove;



@end
