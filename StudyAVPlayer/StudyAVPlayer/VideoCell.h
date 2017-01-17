//
//  VideoCell.h
//  StudyAVPlayer
//
//  Created by weiman on 2016/11/29.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayerView.h"

@protocol VideoCellDelegate <NSObject>
/**
 检查当前正在播放的视频和点击的视频是否是同一个视频

 @param indexPath 被点击的cell的indexpath
 */
-(void)checkPlayingVideoAtIndexPath:(NSIndexPath *)indexPath;

@end

@interface VideoCell : UITableViewCell
@property (nonatomic,strong)PlayerView * myPlayView;
@property (nonatomic, strong) NSDictionary * dataDic;
@property (nonatomic, strong) NSIndexPath * cellIndexPath;
@property (nonatomic,weak)id<VideoCellDelegate>delegate;
+(instancetype)videoCellWithTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath;

@end
