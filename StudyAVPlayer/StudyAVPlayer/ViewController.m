//
//  ViewController.m
//  StudyAVPlayer
//
//  Created by weiman on 2016/11/29.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import "ViewController.h"
#import "VideoCell.h"
#import "MyNetWrok.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,VideoCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *videoTableView;
//视频列表数据
@property (nonatomic, strong) NSArray * videoListArray;
@property (nonatomic, strong) NSIndexPath * oldIndexPath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.oldIndexPath=[NSIndexPath indexPathForRow:-1 inSection:0];
    //获取视频列表的数据
    [MyNetWrok requestVideoList:^(NSArray *listArr) {
        //这里不会产生内存泄露，因为viewController并没有引用block
        self.videoListArray=listArr;
        [self.videoTableView reloadData];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark-UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.videoListArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    VideoCell * cell=[VideoCell videoCellWithTableView:tableView andIndexPath:indexPath];
    cell.dataDic=self.videoListArray[indexPath.row];
    cell.cellIndexPath=indexPath;
    cell.delegate=self;
    return cell;
}

#pragma mark-UITableViewDelegate
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 180*ScreenHeight/667.0;
}

//控制不在当前屏幕中的视频结束
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{

    CGRect scrollRect=scrollView.frame;
    scrollRect.origin.y=scrollView.contentOffset.y;
    if (self.oldIndexPath.row>-1) {
        VideoCell * cell=[self.videoTableView cellForRowAtIndexPath:self.oldIndexPath];
        CGRect viewrect=cell.frame;
        BOOL isIntersection=CGRectIntersectsRect(viewrect, scrollRect);
        if (!isIntersection) {
            self.oldIndexPath=[NSIndexPath indexPathForRow:-1 inSection:0];
            [cell.myPlayView remove];
        }
    }
}

#pragma mark-VideoCellDelegate
-(void)checkPlayingVideoAtIndexPath:(NSIndexPath *)indexPath{
    VideoCell * cell=[self.videoTableView cellForRowAtIndexPath:indexPath];
    if (self.oldIndexPath.row!=indexPath.row) {
        //移除之前的播放器
        [cell.myPlayView remove];
    }
    self.oldIndexPath=indexPath;
}

@end
