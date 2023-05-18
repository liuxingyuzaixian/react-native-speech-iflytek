//
//  SpeechRecognizerModule.m
//  RNSpeechIFlytek
//
//  Created by 张棚贺 on 2018/1/10.
//  Copyright © 2018年 zphhhhh. All rights reserved.
//

#import "SpeechRecognizerModule.h"
#import <Foundation/Foundation.h>
#import "IATConfig.h"
#import "Definition.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#define listening_pcm   @"listening_asr.pcm"
#define listening_wav   @"temp_audio.wav"
#define merge_audio     @"merge_audio.m4a"
#define result_audio    @"result_audio.m4a"

/*
 录音文件pcm格式(listening_pcm)转wav格式(listening_wav)
 如果是没有其他录音wav格式(listening_wav)转m4a格式(result_audio);
 存在录音wav格式(listening_wav)和m4a格式(result_audio)合并导出m4a格式(merge_audio),
 然后再把m4a格式(merge_audio)转m4a格式(result_audio)
 */

typedef void (^RCTPromiseResolveBlock)(id result);
typedef void (^RCTPromiseRejectBlock)(NSString *code, NSString *message, NSError *error);

@interface SpeechRecognizerModule ()

@property (nonatomic, assign) BOOL hasListeners;
@property (nonatomic, strong) NSMutableArray *contentArr;
@property (nonatomic, copy) NSString *results;
@property (nonatomic, copy) NSString *directoryCachePath;
@property (nonatomic, copy) NSString *resultAudioPath;
@property (nonatomic, copy) NSString *listeningWAVPath;
@property (nonatomic, copy) NSString *listeningPCMPath;

@property (nonatomic, copy) NSString *lastAudioPath;

@property (nonatomic, strong) AVPlayer *player;

@end

@implementation SpeechRecognizerModule{
    RCTPromiseResolveBlock _playerResolveBlock;
    RCTPromiseRejectBlock _playerRejectBlock;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _directoryCachePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
        [IFlySetting setLogFilePath:_directoryCachePath];
        NSLog(@"_directoryCachePath %@",_directoryCachePath);
        
        _resultAudioPath = [NSString stringWithFormat:@"%@/%@",_directoryCachePath,result_audio];
        _listeningWAVPath = [NSString stringWithFormat:@"%@/%@",_directoryCachePath,listening_wav];
        _listeningPCMPath = [NSString stringWithFormat:@"%@/%@",_directoryCachePath,listening_pcm];
        
        [IFlySpeechUtility createUtility: [[NSString alloc] initWithFormat: @"appid=%@", APPID_VALUE]];
        
        _contentArr = @[].mutableCopy;
        _results = @"";
        self.player = [[AVPlayer alloc] init];
        
    }
    return self;
}

RCT_EXPORT_MODULE(SpeechRecognizerModule);

- (void) startObserving {
    _hasListeners = YES;
}

- (void) stopObserving {
    _hasListeners = NO;
}

- (NSArray <NSString *> *) supportedEvents {
    return @[
        @"onRecognizerVolumeChanged",
        @"onRecognizerResult",
        @"onRecognizerError",
    ];
}

RCT_EXPORT_METHOD(initialize) {
    if (self.iFlySpeechRecognizer != nil) {
        return;
    }
    
    self.iFlySpeechRecognizer = [IFlySpeechRecognizer sharedInstance];
    self.iFlySpeechRecognizer.delegate = self;
    
    [_iFlySpeechRecognizer setParameter:@"" forKey:[IFlySpeechConstant PARAMS]];
    [_iFlySpeechRecognizer setParameter:@"wpgs" forKey:@"dwa"];
    
    //set recognition domain
    [_iFlySpeechRecognizer setParameter:@"iat" forKey:[IFlySpeechConstant IFLY_DOMAIN]];
    
    IATConfig *instance = [IATConfig sharedInstance];
    
    //set timeout of recording
    [_iFlySpeechRecognizer setParameter:instance.speechTimeout forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    //set VAD timeout of end of speech(EOS)
    [_iFlySpeechRecognizer setParameter:instance.vadEos forKey:[IFlySpeechConstant VAD_EOS]];
    //set VAD timeout of beginning of speech(BOS)
    [_iFlySpeechRecognizer setParameter:instance.vadBos forKey:[IFlySpeechConstant VAD_BOS]];
    //set network timeout
    [_iFlySpeechRecognizer setParameter:@"20000" forKey:[IFlySpeechConstant NET_TIMEOUT]];
    
    //set sample rate, 16K as a recommended option
    [_iFlySpeechRecognizer setParameter:instance.sampleRate forKey:[IFlySpeechConstant SAMPLE_RATE]];
    
    //set language
    [_iFlySpeechRecognizer setParameter:instance.language forKey:[IFlySpeechConstant LANGUAGE]];
    //set accent
    [_iFlySpeechRecognizer setParameter:instance.accent forKey:[IFlySpeechConstant ACCENT]];
    
    //set whether or not to show punctuation in recognition results
    [_iFlySpeechRecognizer setParameter:instance.dot forKey:[IFlySpeechConstant ASR_PTT]];
}

RCT_EXPORT_METHOD(start) {
    _lastAudioPath = _resultAudioPath;
    
    if ([self.iFlySpeechRecognizer isListening]) {
        [self.iFlySpeechRecognizer cancel];
    }
    _startTime = [[NSDate date] timeIntervalSince1970];
    _contentArr = @[].mutableCopy;
    
    //Set microphone as audio source
    [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];
    
    //Set result type
    [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];
    
    //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
    [_iFlySpeechRecognizer setParameter:listening_pcm forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];
    
    [_iFlySpeechRecognizer setDelegate:self];
    
    [self.iFlySpeechRecognizer startListening];
}

RCT_EXPORT_METHOD(startWithLastAudioPath: (NSString *) lastAudioPath) {
    _lastAudioPath = lastAudioPath;

    if ([self.iFlySpeechRecognizer isListening]) {
        [self.iFlySpeechRecognizer cancel];
    }
    _startTime = [[NSDate date] timeIntervalSince1970];
    _contentArr = @[].mutableCopy;

    //Set microphone as audio source
    [_iFlySpeechRecognizer setParameter:IFLY_AUDIO_SOURCE_MIC forKey:@"audio_source"];

    //Set result type
    [_iFlySpeechRecognizer setParameter:@"json" forKey:[IFlySpeechConstant RESULT_TYPE]];

    //Set the audio name of saved recording file while is generated in the local storage path of SDK,by default in library/cache.
    [_iFlySpeechRecognizer setParameter:listening_pcm forKey:[IFlySpeechConstant ASR_AUDIO_PATH]];

    [_iFlySpeechRecognizer setDelegate:self];

    [self.iFlySpeechRecognizer startListening];
}


RCT_EXPORT_METHOD(cancel) {
    if ([self.iFlySpeechRecognizer isListening]) {
        [self.iFlySpeechRecognizer cancel];
    }
}

RCT_EXPORT_METHOD(isListening: (RCTPromiseResolveBlock) resolve
                  rejecter: (RCTPromiseRejectBlock) reject) {
    @try {
        BOOL isListening = [self.iFlySpeechRecognizer isListening];
        resolve([NSNumber numberWithBool: isListening]);
    } @catch (NSException * exception) {
        reject(@"101", @"Recognizer.isListening() ", nil);
    }
}

RCT_EXPORT_METHOD(stop) {
    if ([self.iFlySpeechRecognizer isListening]) {
        [self.iFlySpeechRecognizer stopListening];
    }
}

RCT_EXPORT_METHOD(setParameter: (NSString *) parameter
                  value: (NSString *) value) {
    if ([parameter isEqualToString: IFlySpeechConstant.ASR_AUDIO_PATH]) {
        value = [self getAbsolutePath: value];
    }
    [self.iFlySpeechRecognizer setParameter: value forKey: parameter];
}

RCT_EXPORT_METHOD(getParameter: (NSString *) parameter
                  resolver: (RCTPromiseResolveBlock) resolve
                  rejecter: (RCTPromiseRejectBlock) reject) {
    @try {
        NSString * value = [self.iFlySpeechRecognizer parameterForKey: parameter];
        resolve(value);
    } @catch (NSException *exception) {
        reject(@"100", @"参数不存在", nil);
    }
}

RCT_EXPORT_METHOD(clear) {
    _results = @"";
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:_resultAudioPath error:nil];
    [fm removeItemAtPath:_listeningWAVPath error:nil];
    [fm removeItemAtPath:_listeningPCMPath error:nil];
}

RCT_EXPORT_METHOD(destroy) {
    if ([self.iFlySpeechRecognizer destroy]) {
        self.iFlySpeechRecognizer = nil;
    }
}

RCT_EXPORT_METHOD(play:(NSString *) audioPath resolve: (RCTPromiseResolveBlock) resolve
                  rejecter: (RCTPromiseRejectBlock) reject) {
    NSURL *url = nil;
    if (audioPath == nil) {
        reject(@"-104", @"播放失败", nil);
        return;
    }else if ([audioPath hasPrefix:@"http://"] || [audioPath hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:audioPath];
    }else{
        url = [NSURL fileURLWithPath:audioPath];
    }
    AVPlayerItem *songItem = [[AVPlayerItem alloc] initWithURL:url];
    CMTime audioDuration = songItem.asset.duration;
    if (audioDuration.value == 0) {
        reject(@"-102", @"加载失败", nil);
    }else{
        [self.player pause];
        // 移除监听
        [self p_currentItemRemoveObserver];
        [self.player replaceCurrentItemWithPlayerItem:songItem];
        self.player.volume = 1.0;
        _playerResolveBlock = resolve;
        _playerRejectBlock = reject;
        // 添加观察者
        [self p_currentItemAddObserver];
//        [self performSelector:@selector(p_currentItemAddObserver) withObject:nil afterDelay:0.3];
    }
}

RCT_EXPORT_METHOD(stopPlay) {
    [self.player pause];
    _playerResolveBlock = nil;
    _playerRejectBlock = nil;
}

RCT_EXPORT_METHOD(getVoiceDuration:(NSString *) audioPath resolve: (RCTPromiseResolveBlock) resolve
                  rejecter: (RCTPromiseRejectBlock) reject) {
    NSURL *url = nil;
    if ([audioPath hasPrefix:@"http://"] || [audioPath hasPrefix:@"https://"]) {
        url = [NSURL URLWithString:audioPath];
    }else{
        url = [NSURL fileURLWithPath:audioPath];
    }
    AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    CMTime audioDuration = audioAsset.duration;
    resolve(@(CMTimeGetSeconds(audioDuration) * 1000));
}

#pragma makr - delegate

- (void) onError: (IFlySpeechError *) error {
    NSDictionary * result = @{
        @"errorCode": [NSNumber numberWithInt: error.errorCode],
        @"errorType": [NSNumber numberWithInt: error.errorType],
        @"errorDesc": error.errorDesc,
    };
    
    if (_hasListeners) {
        [self sendEventWithName: @"onRecognizerError" body: result];
    }
}

- (void) onResults: (NSArray *) results isLast: (BOOL) isLast {
    self.endTime = [[NSDate date] timeIntervalSince1970];
    NSNumber * duration = [NSNumber numberWithDouble: self.endTime - self.startTime];
    
    NSMutableString * resultString = [NSMutableString new];
    NSDictionary * dic = results[0];
    
    for (NSString * key in dic) {
        [resultString appendFormat:@"%@",key];
    }
    
    NSDictionary *resultDic  = [NSJSONSerialization JSONObjectWithData:
                                [resultString dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    
    NSString * resultFromJson = [self stringFromDic:resultDic];
    
    NSString *pgs = [resultDic objectForKey:@"pgs"];
    if ([pgs isEqualToString:@"apd"]) {
        [_contentArr addObject:resultFromJson];
    }else if ([pgs isEqualToString:@"rpl"]) {
        [_contentArr removeLastObject];
        [_contentArr addObject:resultFromJson];
    }
    
    NSString *_content = [_contentArr componentsJoinedByString:@""];
    NSString *result = [NSString stringWithFormat:@"%@%@",_results,_content];

    NSString *resultPath = _resultAudioPath;
    if (isLast) {
        _results = [NSString stringWithFormat:@"%@%@",_results,_content];
        NSString *wavFilePath =  [IATConfig getAndCreatePlayableFileFromPcmData:_listeningPCMPath withWavFilePath:_listeningWAVPath];
        NSFileManager *fm = [NSFileManager defaultManager];
        if ([fm fileExistsAtPath:_lastAudioPath]) {
            __weak __typeof(self) weakSelf = self;
            NSString *outPath = [NSString stringWithFormat:@"%@/%@",_directoryCachePath,merge_audio];
            [IATConfig mergeAudioPath:wavFilePath withPath:_lastAudioPath outPath:outPath success:^(NSString *outpath) {
                [fm moveItemAtPath:outpath toPath:resultPath error:nil];
                [weakSelf onRecognizerResult:@{
                    @"text": _content,
                    @"result": result,
                    @"isLast": [NSNumber numberWithBool: isLast],
                    @"duration": duration,
                    @"audioPath":resultPath,
                    @"jointAudio":[NSNumber numberWithBool: YES]
                }];
            } fail:^{
                [weakSelf onRecognizerResult:@{
                    @"text": _content,
                    @"result": result,
                    @"isLast": [NSNumber numberWithBool: isLast],
                    @"duration": duration,
                    @"audioPath":wavFilePath,
                    @"jointAudio":[NSNumber numberWithBool: NO]
                }];
            }];
            return;
        }else{
            __weak __typeof(self) weakSelf = self;
            [IATConfig convertAudioToM4AFilePath:wavFilePath outPath:resultPath success:^(NSString *outpath) {
                [weakSelf onRecognizerResult:@{
                    @"text": _content,
                    @"result": result,
                    @"isLast": [NSNumber numberWithBool: isLast],
                    @"duration": duration,
                    @"audioPath":resultPath,
                    @"jointAudio":[NSNumber numberWithBool: YES]
                }];
            } fail:^{
                [weakSelf onRecognizerResult:@{
                    @"text": _content,
                    @"result": result,
                    @"isLast": [NSNumber numberWithBool: isLast],
                    @"duration": duration,
                    @"audioPath":wavFilePath,
                    @"jointAudio":[NSNumber numberWithBool: NO]
                }];
            }];
            return;
        }
    }
    [self onRecognizerResult:@{
        @"text": _content,
        @"result": result,
        @"isLast": [NSNumber numberWithBool: isLast],
        @"duration": duration,
    }];
}

- (void) onRecognizerResult: (NSDictionary *)result {
    if (_hasListeners) [self sendEventWithName: @"onRecognizerResult" body: result];
}

- (void) onVolumeChanged: (int)volume {
    NSDictionary * result = @{
        @"volume": [NSNumber numberWithInt: volume]
    };
    if (_hasListeners) {
        [self sendEventWithName: @"onRecognizerVolumeChanged" body: result];
    }
}

#pragma makr -- method

- (NSString *) stringFromDic: (NSDictionary *) resultDic {
    if (resultDic == NULL) {
        return nil;
    }
    
    NSMutableString *tempStr = [[NSMutableString alloc] init];
    if (resultDic!= nil) {
        NSArray *wordArray = [resultDic objectForKey:@"ws"];
        
        for (int i = 0; i < [wordArray count]; i++) {
            NSDictionary *wsDic = [wordArray objectAtIndex: i];
            NSArray *cwArray = [wsDic objectForKey:@"cw"];
            
            for (int j = 0; j < [cwArray count]; j++) {
                NSDictionary *wDic = [cwArray objectAtIndex:j];
                NSString *str = [wDic objectForKey:@"w"];
                [tempStr appendString: str];
            }
        }
    }
    return tempStr;
}

- (NSString *) getAbsolutePath: (NSString *) path {
    NSString * homePath = NSHomeDirectory();
    path = [path stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"/"]];
    return [NSString stringWithFormat:@"%@/%@", homePath, path];
}

- (void)p_currentItemRemoveObserver {
    @try {
        [self.player.currentItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    } @catch (NSException *excepiton){
        NSLog(@"exc == %@",excepiton);
        @try {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        } @catch (NSException *excepiton){
            NSLog(@"exc == %@",excepiton);
        }
    }
}

- (void)p_currentItemAddObserver {
    //监控状态属性，注意AVPlayer也有一个status属性，通过监控它的status也可以获得播放状态
    [self.player.currentItem addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew) context:nil];
    //监控播放完成通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
}

#pragma mark - KVO ios AVPlayer 播放本地音频 https://www.jianshu.com/p/bb2060fe6d5e

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus status = [change[@"new"] integerValue];
        switch (status) {
            case AVPlayerItemStatusReadyToPlay:{
                // 开始播放
                [self.player play];
            }
                break;
            case AVPlayerItemStatusFailed:{
                NSLog(@"加载失败");
                _playerRejectBlock(@"-102", @"加载失败", nil);
                _playerRejectBlock = nil;
            }
                break;
            case AVPlayerItemStatusUnknown:{
                NSLog(@"未知资源");
                _playerRejectBlock(@"-103", @"未知资源", nil);
                _playerRejectBlock = nil;
            }
                break;
            default:
                break;
        }
    }
}

- (void)playbackFinished:(NSNotification *)notifi {
    _playerResolveBlock ? _playerResolveBlock(@(YES)) : nil;
    _playerResolveBlock = nil;
}

@end
