//
//  PlayerView.m
//  StudyAVPlayer
//
//  Created by weiman on 2016/11/29.
//  Copyright © 2016年 weiman. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerView()
//界面相关
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIView *manageView;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIProgressView *progress;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UIButton *fullBtn;
@property (weak, nonatomic) IBOutlet UIButton *centerPlayBtn;
@property (weak, nonatomic) IBOutlet UIButton *bgBtn;
@property (weak, nonatomic) IBOutlet UIImageView *shadowImage;
@property (nonatomic, strong) UIActivityIndicatorView * activityView;//小菊花
//avplayer相关
@property (nonatomic, strong) AVPlayer * myAvPlayer;
@property (nonatomic, strong) AVPlayerItem * myplayerItem;
@property (nonatomic, strong) AVPlayerLayer * myPlayerLayer;
//其他
@property (nonatomic, assign) CGFloat totleTime;
@property (nonatomic, strong) NSTimer * slideTimer;//控制slider滑动的timer
@property (nonatomic, strong) NSTimer * hiddenTimer;//控制操作按钮是否隐藏的timer
@property (nonatomic, assign) BOOL isDrag;//slider是否滑动,slider被拖拽的时候应该停止计时器，防止拖拽的时候不平滑
@property (nonatomic, assign) BOOL isFull;

@end

@implementation PlayerView

static PlayerView * sharedInstance = nil;
+(PlayerView *)playView{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance= [[[NSBundle mainBundle]loadNibNamed:@"PlayerView" owner:nil options:nil]lastObject];
    });
    [sharedInstance.slider setThumbImage:[UIImage imageNamed:@"sliderImg"] forState:UIControlStateNormal];
    return sharedInstance;
}

-(void)setUpInitSubViewsUI{
    //手动计算frame，autolayout和frame并用的时候会出现莫名的问题，又不想使用Masonry
    self.bgBtn.frame=self.bounds;
    self.manageView.frame=self.bounds;
    self.centerPlayBtn.center=self.center;
    CGFloat manageViewWidth=self.manageView.frame.size.width;
    CGFloat manageViewHeight=self.manageView.frame.size.height;
    self.shadowImage.frame=CGRectMake(0, 0, manageViewWidth, 40);
    self.titleLabel.frame=CGRectMake(15, 0, manageViewWidth-30, 40);
    self.backBtn.frame=CGRectMake(20, 10, 25, 25);
    self.playOrPauseBtn.frame=CGRectMake(15, manageViewHeight-40, 20, 20);
    self.currentTimeLabel.frame=CGRectMake(self.playOrPauseBtn.frame.origin.x+self.playOrPauseBtn.frame.size.width, self.playOrPauseBtn.frame.origin.y, 40, 21);
    self.progress.frame=CGRectMake(self.currentTimeLabel.frame.origin.x+self.currentTimeLabel.frame.size.width+4, self.playOrPauseBtn.frame.origin.y+10, manageViewWidth-150, 3);
    self.slider.frame=CGRectMake(self.progress.frame.origin.x-5, self.progress.frame.origin.y-14, self.progress.frame.size.width-5, 30);
    self.durationLabel.frame=CGRectMake(self.progress.frame.origin.x+self.progress.frame.size.width, self.currentTimeLabel.frame.origin.y, 40, 21);
    self.fullBtn.frame=CGRectMake(self.durationLabel.frame.origin.x+self.durationLabel.frame.size.width, self.playOrPauseBtn.frame.origin.y, 20, 20);
}

#pragma mark-懒加载
-(AVPlayer *)myAvPlayer{
    if (!_myAvPlayer) {
        _myAvPlayer=[AVPlayer playerWithPlayerItem:self.myplayerItem];
    }
    return _myAvPlayer;
}

-(UIActivityIndicatorView *)activityView{
    if (!_activityView) {
        _activityView=[[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        _activityView.center=self.center;
        [self addSubview:_activityView];
        _activityView.hidden=YES;
    }
    return _activityView;
}

//slider滑动控制
-(NSTimer *)slideTimer{
    if (!_slideTimer) {
        __weak PlayerView * weakSelf=self;
        _slideTimer=[NSTimer scheduledTimerWithTimeInterval:0.1 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if (weakSelf.isDrag) {
                return ;//如果当前的slider正在被拖拽，就应该停止定时器
            }
            CMTime time=[weakSelf.myAvPlayer currentTime];
            CGFloat timeFloat=time.value/time.timescale;
            NSString * currentTime=[weakSelf changeTimeToHMSWithTime:timeFloat];
            weakSelf.currentTimeLabel.text=currentTime;
            if (weakSelf.totleTime>0) {
                CGFloat sliderValue=timeFloat/weakSelf.totleTime;
                weakSelf.slider.value=sliderValue;
            }
        }];
    }
    return _slideTimer;
}

-(NSTimer *)hiddenTimer{
    if (!_hiddenTimer) {
        __weak PlayerView * weakSelf=self;
        __block int timerCount=0;
        _hiddenTimer=[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            timerCount++;
            //NSLog(@"------- %d",timerCount);
            if (timerCount>3) {
                //停止timer,隐藏操作按钮
                [weakSelf hiddenManagerButtons];
                [_hiddenTimer invalidate];
                _hiddenTimer=nil;
            }
        }];
    }
    return _hiddenTimer;
}

#pragma mark-set方法
-(void)setVideoTitle:(NSString *)videoTitle{
    _videoTitle=videoTitle;
    self.titleLabel.text=videoTitle;
}

-(void)setDuration:(NSString *)duration{
    _duration=duration;
    self.durationLabel.text=duration;
}

#pragma mark-自定义方法
-(void)play{
    self.activityView.hidden=NO;
    [self.activityView startAnimating];
    [self initAvPlayer];
    [self setPlayUIStatus];
    //[self.myAvPlayer play];
}

-(void)pause{
    NSLog(@"暂停");
    [self.myAvPlayer pause];
}

-(void)remove{
    NSLog(@"移除播放器");
    [[NSNotificationCenter defaultCenter]postNotificationName:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

//隐藏操作按钮
-(void)hiddenManagerButtons{
    self.manageView.hidden=YES;
}

//设置播放状态的UI并且播放,点击了中间的播放按钮或者点击了左下角的播放状态的按钮的时候
-(void)setPlayUIStatus{
    [self.playOrPauseBtn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
    self.centerPlayBtn.hidden=YES;
    [self.myAvPlayer play];
    [self.hiddenTimer fire];
}

//计算总时间
-(void)computeTotalTime{
    //给总时间label赋值
    self.durationLabel.text=[self changeTimeToHMSWithTime:self.totleTime];
}

//转化时间的格式
-(NSString *)changeTimeToHMSWithTime:(CGFloat)time{
    NSDate * date=[NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter * format=[[NSDateFormatter alloc]init];
    if (time/3600>=1) {
        [format setDateFormat:@"HH:mm:ss"];
    }else{
        [format setDateFormat:@"mm:ss"];
    }
    NSString * showTime=[format stringFromDate:date];
    return showTime;
}

//设置全屏状态下的UI
-(void)setFullVideoUI{
    //下面通过相对计算来设置布局，为了达到不使用任何第三方控件的目的
    self.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    self.myPlayerLayer.frame=CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    self.manageView.frame=self.bounds;
    self.bgBtn.frame=self.bounds;
    self.centerPlayBtn.center=self.manageView.center;
    self.shadowImage.frame=CGRectMake(0, 0, self.manageView.frame.size.width, 40);
    self.titleLabel.frame=CGRectMake(55, 15, self.manageView.frame.size.width-30, 15);
    self.playOrPauseBtn.frame=CGRectMake(15, [UIScreen mainScreen].bounds.size.width-50, 30, 40);
    self.currentTimeLabel.frame=CGRectMake(self.playOrPauseBtn.frame.origin.x+self.playOrPauseBtn.frame.size.width-10, self.playOrPauseBtn.frame.origin.y+10, 50, 21);
    self.progress.frame=CGRectMake(self.currentTimeLabel.frame.origin.x+self.currentTimeLabel.frame.size.width, self.currentTimeLabel.frame.origin.y+10, self.manageView.frame.size.width-165, 3);
    self.slider.frame=self.progress.frame;
    self.durationLabel.frame=CGRectMake(self.manageView.frame.size.width-80, self.currentTimeLabel.frame.origin.y, 50, 21);
    self.fullBtn.frame=CGRectMake(self.manageView.frame.size.width-35, self.playOrPauseBtn.frame.origin.y, 20, 40);
}

//把视频转换成全屏形式
-(void)turnVideoToFull{
    self.isFull=YES;
    self.backBtn.hidden=NO;
    [self.fullBtn setImage:[UIImage imageNamed:@"cancelFull"] forState:UIControlStateNormal];
    
    [[UIApplication sharedApplication].keyWindow addSubview:self];
    self.transform=CGAffineTransformMakeRotation(M_PI/2);
    [self setFullVideoUI];
}

//把视频转成正常形式
-(void)turnVideoToNormal{
    self.isFull=NO;
    self.backBtn.hidden=YES;
    [self.fullBtn setImage:[UIImage imageNamed:@"full"] forState:UIControlStateNormal];
    
    [self.mySuperView addSubview:self];
    self.transform=CGAffineTransformIdentity;
    self.frame=CGRectMake(0, 0, self.mySuperView.frame.size.width, self.mySuperView.frame.size.height);
    self.myPlayerLayer.frame=self.bounds;
    [self setUpInitSubViewsUI];
}

#pragma mark-click方法
- (IBAction)bgBtnClick:(id)sender {
    NSLog(@"bgBtnClick");
   //能点击到这个button，说明managerView已经隐藏了
    self.manageView.hidden=NO;
    [self.hiddenTimer fire];
}

- (IBAction)backBtnClick:(id)sender {
    NSLog(@"backBtnClick");
    [self turnVideoToNormal];
}

- (IBAction)playOrPauseBtnClick:(id)sender {
    NSLog(@"playOrPauseBtnClick");
    if (self.playOrPauseBtn.currentImage.CGImage==[UIImage imageNamed:@"start"].CGImage) {
        //开始按钮
        [self setPlayUIStatus];
    }else{
        //暂停状态下，不隐藏操作按钮，停止定时器
        [_hiddenTimer invalidate];
        _hiddenTimer=nil;
        self.manageView.hidden=NO;
        [self.playOrPauseBtn setImage:[UIImage imageNamed:@"start"] forState:UIControlStateNormal];
        self.centerPlayBtn.hidden=NO;
        [self.myAvPlayer pause];
    }
}

- (IBAction)fullBtnClick:(id)sender {
    NSLog(@"fullBtnClick");
    if (self.isFull) {
        [self turnVideoToNormal];
    }else{
        [self turnVideoToFull];
    }
}

- (IBAction)playBtnClick:(id)sender {
    NSLog(@"playBtnClick");
    [self setPlayUIStatus];
}

//滑动结束的时候调用
- (IBAction)sliderTouchUpInside:(id)sender {
    self.isDrag=NO;
    UISlider * slider=(UISlider *)sender;
    int timeF=slider.value*self.totleTime;
    CMTime changeTime=CMTimeMakeWithSeconds(timeF, 1);
    [self.myAvPlayer seekToTime:changeTime completionHandler:^(BOOL finished) {
        
    }];
}

- (IBAction)sliderTouchDown:(id)sender {
    //当slider被点击的时候
    _isDrag=YES;
}

/**
 初始化avplayer
 */
-(void)initAvPlayer{
    if (!_myPlayerLayer) {
        [self initMyPlayerItem];
        [self.myAvPlayer replaceCurrentItemWithPlayerItem:self.myplayerItem];
        [self initMyPlayerLayer];
    }
    //添加播放完成的通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerItemDidFinish:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playerItemFailed) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    //设置更新slide的定时器
    if (self.slideTimer) {
       [self.slideTimer fire];
    }
}

/**
 初始化MyPlayerItem
 */
-(void)initMyPlayerItem{
    NSURL * url=[NSURL URLWithString:self.playUrl];
    if (_myplayerItem) {
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
        [self.myplayerItem removeObserver:self forKeyPath:@"status"];
        [self.myplayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    }
    AVPlayerItem * item=[AVPlayerItem playerItemWithURL:url];
    _myplayerItem=item;
    //观察playerItem的状态变化
    [_myplayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //加载缓存
    [_myplayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

/**
 初始化MyPlayerLayer
 */
-(void)initMyPlayerLayer{
    _myPlayerLayer=[AVPlayerLayer playerLayerWithPlayer:self.myAvPlayer];
    _myPlayerLayer.frame=self.bounds;
    _myPlayerLayer.videoGravity=AVLayerVideoGravityResizeAspect;
    _myPlayerLayer.backgroundColor=[UIColor blackColor].CGColor;
    [self.layer insertSublayer:_myPlayerLayer atIndex:0];
}

#pragma mark-播放完成的通知
/**
 播放完成的通知
 @param finishN 通知
 */
-(void)playerItemDidFinish:(NSNotification *)finishN{
    NSLog(@"播放完成");
    if (self.isFull) {
        self.isFull=NO;
        [self turnVideoToNormal];
    }
    [self.myPlayerLayer removeFromSuperlayer];
    if (_myPlayerLayer) {
        _myPlayerLayer=nil;
    }
    [_slideTimer invalidate];
    _slideTimer=nil;
    AVPlayerItem * item=[finishN object];
    [item seekToTime:kCMTimeZero];
    [self.myAvPlayer replaceCurrentItemWithPlayerItem:nil];
    [self removeFromSuperview];
}

-(void)playerItemFailed{
    NSLog(@"播放失败");
}

#pragma mark-KVO监听播放状态
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    AVPlayerItem * playerItem=object;
    if ([keyPath isEqualToString:@"status"]) {
        //状态
        AVPlayerStatus status=[[change objectForKey:@"new"] intValue];
        if (status==AVPlayerStatusReadyToPlay) {
            //停止转圈圈
            [self.activityView stopAnimating];
            [self.activityView setHidden:YES];
            //计算视频总时间
            CMTime totalTimeM=playerItem.duration;
            self.totleTime=(CGFloat)totalTimeM.value/totalTimeM.timescale;
            [self computeTotalTime];
            //启动隐藏操作按钮的定时器
            [self.hiddenTimer fire];
        }else{
            NSLog(@"播放错误");
        }
        
    }else if([keyPath isEqualToString:@"loadedTimeRanges"]){
        //加载时间
        NSArray * array=playerItem.loadedTimeRanges;
        //本次缓冲时间范围
        CMTimeRange timeRange=[array.firstObject CMTimeRangeValue];
        float start=CMTimeGetSeconds(timeRange.start);
        float duration=CMTimeGetSeconds(timeRange.duration);
        //缓冲总长
        NSTimeInterval totalBuffer=start+duration;
        //更新进度条
        CGFloat pro=totalBuffer*1.0/self.totleTime;
        if (pro>0&&pro<1) {
            [self.progress setProgress:pro animated:YES];
        }
    }
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    //释放掉对playItem的观察
    [self.myplayerItem removeObserver:self forKeyPath:@"status" context:nil];
    [self.myplayerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
}

@end
