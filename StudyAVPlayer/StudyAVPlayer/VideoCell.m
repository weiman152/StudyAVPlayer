//
//  VideoCell.m
//  StudyAVPlayer
//
//  Created by weiman on 2016/11/29.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import "VideoCell.h"
#import "UIImageView+WebCache.h"

@interface VideoCell()
@property (weak, nonatomic) IBOutlet UIImageView *coverImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *playView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
//默认不显示，有数据才显示
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLabel;

@end

@implementation VideoCell

+(instancetype)videoCellWithTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath{
    UINib * nib=[UINib nibWithNibName:@"VideoCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:@"VideoCell"];
    VideoCell * cell=[tableView dequeueReusableCellWithIdentifier:@"VideoCell" forIndexPath:indexPath];
    return cell;
}

//初始化播放View
-(PlayerView *)myPlayView{
    if (!_myPlayView) {
        _myPlayView=[PlayerView playView];
        _myPlayView.frame=self.playView.bounds;
        [_myPlayView setUpInitSubViewsUI];
    }
    if (![self.playView.subviews containsObject:_myPlayView]) {
        [self.playView addSubview:_myPlayView];
    }
    _myPlayView.playUrl=self.dataDic[@"mp4_url"];
    _myPlayView.videoTitle=self.dataDic[@"title"];
    _myPlayView.duration=[self playLengthString:self.dataDic[@"length"]];
    _myPlayView.mySuperView=self.playView;
    return _myPlayView;
}

-(void)setDataDic:(NSDictionary *)dataDic{
    _dataDic=dataDic;
    self.titleLabel.text=dataDic[@"title"];
    [self.coverImage sd_setImageWithURL:[NSURL URLWithString:dataDic[@"cover"]]];
    NSString * totalTime=[self playLengthString:self.dataDic[@"length"]];
    if (totalTime) {
        self.totalTimeLabel.hidden=NO;
        self.totalTimeLabel.text=totalTime;
    }else{
        self.totalTimeLabel.hidden=YES;
    }
}

/**
 根据秒数转成时分秒
 */
-(NSString *)playLengthString:(NSString *)str{
    NSInteger seconds = [str integerValue];
    //format of hour
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    if ([str_hour intValue]==0) {
        format_time=[NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    }
    return format_time;
}

- (IBAction)playBtnClick:(id)sender {
    NSLog(@"playBtnClick");
    [self.delegate checkPlayingVideoAtIndexPath:self.cellIndexPath];
    [self.myPlayView play];
}



@end
