//
//  ViewController.m
//  BeautifyExample
//
//  Created by LSQ on 2020/8/3.
//  Copyright © 2020 Agora. All rights reserved.
//


#import "ViewController.h"
#import <AgoraRtcKit/AgoraRtcEngineKit.h>
#import "CapturerManager.h"
#import "VideoProcessingManager.h"
#import "KeyCenter.h"

//#import <Masonry/Masonry.h>
#import "Masonry.h"
#import <AGMRenderer/AGMRenderer.h>




#import "AgoraMediaDataPlugin.h"

@interface ViewController () <AgoraRtcEngineDelegate, AgoraVideoSourceProtocol, AgoraVideoDataPluginDelegate>

@property (nonatomic, strong) AgoraMediaDataPlugin *agoraMediaDataPlugin;
@property (nonatomic, assign) NSInteger tuid;

@property (nonatomic, strong) CapturerManager *capturerManager;
@property (nonatomic, strong) VideoProcessingManager *processingManager;
@property (nonatomic, strong) AgoraRtcEngineKit *rtcEngineKit;
@property (nonatomic, strong) IBOutlet UIView *localView;

@property (weak, nonatomic) IBOutlet UIView *remoteView;

@property (nonatomic, strong) IBOutlet UIButton *switchBtn;
@property (nonatomic, strong) IBOutlet UIButton *remoteMirrorBtn;
@property (nonatomic, strong) IBOutlet UILabel *beautyStatus;
@property (nonatomic, strong) IBOutlet UIView *missingAuthpackLabel;
@property (nonatomic, strong) AgoraRtcVideoCanvas *videoCanvas;
@property (nonatomic, assign) AgoraVideoMirrorMode localVideoMirrored;
@property (nonatomic, assign) AgoraVideoMirrorMode remoteVideoMirrored;
@property (nonatomic, strong) AGMEAGLVideoView *glVideoView;


@end

@implementation ViewController
@synthesize consumer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.remoteView.hidden = YES;
    


    // 初始化 rte engine
    self.rtcEngineKit = [AgoraRtcEngineKit sharedEngineWithAppId:[KeyCenter AppId] delegate:self];
    
    [self.rtcEngineKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [self.rtcEngineKit setClientRole:AgoraClientRoleBroadcaster];
    [self.rtcEngineKit enableVideo];
    [self.rtcEngineKit setParameters:@"{\"che.video.zerocopy\":true}"];
    [self.rtcEngineKit setAudioProfile:AgoraAudioProfileMusicHighQuality scenario:AgoraAudioScenarioEducation];
    AgoraVideoEncoderConfiguration* config = [[AgoraVideoEncoderConfiguration alloc] initWithSize:AgoraVideoDimension1280x720
                                                                                        frameRate:AgoraVideoFrameRateFps30
                                                                                          bitrate:AgoraVideoBitrateStandard
                                                                                  orientationMode:AgoraVideoOutputOrientationModeFixedPortrait];
    
    [self.rtcEngineKit setVideoEncoderConfiguration:config];
    

    // init process manager
    self.processingManager = [[VideoProcessingManager alloc] init];
    
    // init capturer, it will push pixelbuffer to rtc channel
    AGMCapturerVideoConfig *videoConfig = [AGMCapturerVideoConfig defaultConfig];
    videoConfig.sessionPreset = AVCaptureSessionPreset1280x720;
    videoConfig.fps = 30;
    videoConfig.pixelFormat =  AGMVideoPixelFormatBGRA;
    self.capturerManager = [[CapturerManager alloc] initWithVideoConfig:videoConfig delegate:self.processingManager];
    
    
    [self.capturerManager startCapture];

    
    [self.localView layoutIfNeeded];
    self.glVideoView = [[AGMEAGLVideoView alloc] initWithFrame:self.localView.frame];
//    [self.glVideoView setRenderMode:(AGMRenderMode_Fit)];
    [self.localView addSubview:self.glVideoView];
    [self.capturerManager setVideoView:self.glVideoView];
    // set custom capturer as video source
    [self.rtcEngineKit setVideoSource:self.capturerManager];
    
    

    self.agoraMediaDataPlugin = [AgoraMediaDataPlugin mediaDataPluginWithAgoraKit:self.rtcEngineKit];
    
    // Register video observer
    ObserverVideoType videoType = ObserverVideoTypeCaptureVideo | ObserverVideoTypeRenderVideo;
    [self.agoraMediaDataPlugin registerVideoRawDataObserver:videoType];
    self.agoraMediaDataPlugin.videoDelegate = self;
    

    // 注册通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidChangeStatusBar) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    [self.rtcEngineKit joinChannelByToken:nil channelId:self.channelName info:nil uid:0 joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {

        
    }];
    
    
    
   
    UIButton *snapshotButton1 = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:snapshotButton1];
    snapshotButton1.backgroundColor = [UIColor redColor];
    snapshotButton1.frame = CGRectMake(100.0, 100.0, 50.0, 50.0);
    [snapshotButton1 setTitle:@"截图" forState:UIControlStateNormal];
    [snapshotButton1 addTarget:self action:@selector(tapSnapshotButton) forControlEvents:UIControlEventTouchUpInside];
        
}

- (void)tapSnapshotButton {

    // 截图远端用户
//    [self.agoraMediaDataPlugin remoteSnapshotWithUid:_tuid image:^(AGImage * _Nonnull image) {
//
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
//
//    }];
//
    // 截图本地用户
    [self.agoraMediaDataPlugin localSnapshot:^(AGImage * _Nonnull image) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
    }];

    
}




//!!!!: <AgoraVideoDataPluginDelegate>
- (AgoraVideoRawData *)mediaDataPlugin:(AgoraMediaDataPlugin *)mediaDataPlugin didCapturedVideoRawData:(AgoraVideoRawData *)videoRawData {
    
    return videoRawData;
}

- (AgoraVideoRawData * _Nonnull)mediaDataPlugin:(AgoraMediaDataPlugin * _Nonnull)mediaDataPlugin willRenderVideoRawData:(AgoraVideoRawData * _Nonnull)videoRawData ofUid:(uint)uid {
    return videoRawData;
}


- (void)applicationDidChangeStatusBar {
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    switch (orientation) {
        
        case UIDeviceOrientationPortrait:
            
            break;
            
            
        default:
            break;
    }
    
}


- (void)viewDidLayoutSubviews {
    self.glVideoView.frame = self.view.bounds;
}



/// release
- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
//    [[FUManager shareManager] destoryItems];
    
    [self.capturerManager stopCapture];
    [self.rtcEngineKit leaveChannel:nil];
    [self.rtcEngineKit stopPreview];
    [self.rtcEngineKit setVideoSource:nil];
    [AgoraRtcEngineKit destroy];
   
    
}


- (IBAction)switchCamera:(UIButton *)button
{
    [self.capturerManager switchCamera];
    
 
    
}

- (IBAction)toggleRemoteMirror:(UIButton *)button
{
    self.remoteVideoMirrored = self.remoteVideoMirrored == AgoraVideoMirrorModeEnabled ? AgoraVideoMirrorModeDisabled : AgoraVideoMirrorModeEnabled;
    AgoraVideoEncoderConfiguration* config = [[AgoraVideoEncoderConfiguration alloc] initWithSize:CGSizeMake(720, 1280) frameRate:30 bitrate:0 orientationMode:AgoraVideoOutputOrientationModeAdaptative];
    config.mirrorMode = self.remoteVideoMirrored;
    [self.rtcEngineKit setVideoEncoderConfiguration:config];
}


- (IBAction)backBtnClick:(UIButton *)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

/// firstRemoteVideoDecoded
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size: (CGSize)size elapsed:(NSInteger)elapsed {

    if (self.remoteView.hidden) {
        self.remoteView.hidden = NO;
    }
    
    AgoraRtcVideoCanvas *videoCanvas = [[AgoraRtcVideoCanvas alloc] init];
    videoCanvas.uid = uid;
    // Since we are making a simple 1:1 video chat app, for simplicity sake, we are not storing the UIDs. You could use a mechanism such as an array to store the UIDs in a channel.
    
    videoCanvas.view = self.remoteView;
    videoCanvas.renderMode = AgoraVideoRenderModeHidden;
    [self.rtcEngineKit setupRemoteVideo:videoCanvas];
    // Bind remote video stream to view
    

   _tuid = uid;
    
}

-(void)rtcEngine:(AgoraRtcEngineKit *_Nonnull)engine localAudioMixingStateDidChanged:(AgoraAudioMixingStateCode)state errorCode:(AgoraAudioMixingErrorCode)errorCode {
    NSLog(@"status is :%ld,errorcode is %ld",(long)state,(long)errorCode);
}

#pragma mark - AgoraVideoSourceProtocol
- (AgoraVideoBufferType)bufferType {
    return AgoraVideoBufferTypePixelBuffer;
}

- (void)shouldDispose {
    
}

- (BOOL)shouldInitialize {
    return YES;
}

- (void)shouldStart {
    
}

- (void)shouldStop {
    
}


- (AgoraVideoCaptureType)captureType {
    return AgoraVideoCaptureTypeCamera;
}

@end
