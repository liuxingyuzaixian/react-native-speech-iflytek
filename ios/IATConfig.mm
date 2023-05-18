//
//  IATConfig.m
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#define PUTONGHUA   @"mandarin"
#define YUEYU       @"cantonese"
#define ENGLISH     @"en_us"
#define CHINESE     @"zh_cn";
#define SICHUANESE  @"lmz";

#define RIYU  @"ja_jp";
#define EYU  @"ru-ru";
#define FAYU  @"fr_fr";
#define XBY  @"es_es";
#define HANYU  @"ko_kr";

#import "IATConfig.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@implementation IATConfig

-(id)init {
    self  = [super init];
    if (self) {
        [self defaultSetting];
        return  self;
    }
    return nil;
}


+(IATConfig *)sharedInstance {
    static IATConfig  * instance = nil;
    static dispatch_once_t predict;
    dispatch_once(&predict, ^{
        instance = [[IATConfig alloc] init];
    });
    return instance;
}


-(void)defaultSetting {
    _speechTimeout = @"60000";
    _vadEos = @"10000";
    _vadBos = @"10000";
    _dot = @"1";
    _sampleRate = @"16000";
    _language = CHINESE;
    _accent = PUTONGHUA;
    _haveView = NO;
    _accentNickName = [[NSArray alloc] initWithObjects:NSLocalizedString(@"K_LangCant", nil), NSLocalizedString(@"K_LangChin", nil), NSLocalizedString(@"K_LangEng", nil), NSLocalizedString(@"K_LangSzec", nil),NSLocalizedString(@"K_LangJapa", nil),NSLocalizedString(@"K_LangRuss", nil),NSLocalizedString(@"K_LangFren", nil),NSLocalizedString(@"K_LangSpan", nil),NSLocalizedString(@"K_LangKor", nil), nil];
    
    _isTranslate = NO;
}
+(NSString *)french{
    return FAYU;
}
+(NSString *)spanish{
    return XBY;
}
+(NSString *)korean{
    return HANYU;
}
+(NSString *)japanese{
    return RIYU;
}
+(NSString *)russian{
    return EYU;
}

+(NSString *)mandarin {
    return PUTONGHUA;
}
+(NSString *)cantonese {
    return YUEYU;
}
+(NSString *)chinese {
    return CHINESE;
}
+(NSString *)english {
    return ENGLISH;
}
+(NSString *)sichuanese {
    return SICHUANESE;
}

+(NSString *)lowSampleRate {
    return @"8000";
}

+(NSString *)highSampleRate {
    return @"16000";
}

+(NSString *)isDot {
    return @"1";
}

+(NSString *)noDot {
    return @"0";
}

+ (NSString *) getAndCreatePlayableFileFromPcmData:(NSString *)filePath withWavFilePath:(NSString *)wavFilePath{
    FILE *fout;
    
    short NumChannels = 1;       //录音通道数
    short BitsPerSample = 16;    //线性采样位数
    int SamplingRate = 16000;    //录音采样率(Hz)
    int numOfSamples = (int)[[NSData dataWithContentsOfFile:filePath] length];
    
    int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
    short BlockAlign = NumChannels*BitsPerSample/8;
    int DataSize = NumChannels*numOfSamples*BitsPerSample/8;
    int chunkSize = 16;
    int totalSize = 46 + DataSize;
    short audioFormat = 1;
    
    if((fout = fopen([wavFilePath cStringUsingEncoding:1], "w")) == NULL)
    {
        printf("Error opening out file ");
    }
    
    fwrite("RIFF", sizeof(char), 4,fout);
    fwrite(&totalSize, sizeof(int), 1, fout);
    fwrite("WAVE", sizeof(char), 4, fout);
    fwrite("fmt ", sizeof(char), 4, fout);
    fwrite(&chunkSize, sizeof(int),1,fout);
    fwrite(&audioFormat, sizeof(short), 1, fout);
    fwrite(&NumChannels, sizeof(short),1,fout);
    fwrite(&SamplingRate, sizeof(int), 1, fout);
    fwrite(&ByteRate, sizeof(int), 1, fout);
    fwrite(&BlockAlign, sizeof(short), 1, fout);
    fwrite(&BitsPerSample, sizeof(short), 1, fout);
    fwrite("data", sizeof(char), 4, fout);
    fwrite(&DataSize, sizeof(int), 1, fout);
    
    fclose(fout);
    
    NSMutableData *pamdata = [NSMutableData dataWithContentsOfFile:filePath];
    NSFileHandle *handle;
    handle = [NSFileHandle fileHandleForUpdatingAtPath:wavFilePath];
    [handle seekToEndOfFile];
    [handle writeData:pamdata];
    [handle closeFile];
    
    return wavFilePath;
}

+(NSString *)m4aRecordPath{
    return [NSString stringWithFormat:@"%@/merge_temp_audio.m4a",NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject];
}

+(void)mergeAudioPath:(NSString *)audio1 withPath:(NSString *)audio2 outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail{
    AVURLAsset *audioAsset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audio2]];
    AVURLAsset *audioAsset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audio1]];
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 音频通道
    AVMutableCompositionTrack *audioTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    AVMutableCompositionTrack *audioTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    // 音频采集通道
    AVAssetTrack *audioAssetTrack1 = [[audioAsset1 tracksWithMediaType:AVMediaTypeAudio] firstObject];
    AVAssetTrack *audioAssetTrack2 = [[audioAsset2 tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 音频合并 - 插入音轨文件
    [audioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset1.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero error:nil];
    // `startTime`参数要设置为第一段音频的时长，即`audioAsset1.duration`, 表示将第二段音频插入到第一段音频的尾部。
    [audioTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset2.duration) ofTrack:audioAssetTrack2 atTime:audioAsset1.duration error:nil];
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = outPath;

    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:outPutFilePath]) {
        [fm removeItemAtPath:outPutFilePath error:nil];
    }
    // 查看当前session支持的fileType类型
    NSLog(@"---%@",[session supportedFileTypes]);
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    session.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60.0, 600));
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并成功----%@", outPutFilePath);
            [fm removeItemAtPath:audio1 error:nil];
            [fm removeItemAtPath:audio2 error:nil];
            
            success(outPath);
        }else if (session.status == AVAssetExportSessionStatusFailed){
            NSLog(@"合并失败！");
            fail();
        }
    }];
    
//    if (@available(iOS 13.0, *)) {
//        [session estimateMaximumDurationWithCompletionHandler:^(CMTime estimatedMaximumDuration, NSError * _Nullable error) {
//            CMTimeShow(estimatedMaximumDuration);
//            NSLog(@"______");
//        }];
//    } else {
//        // Fallback on earlier versions
//    }
}

+(void)convertAudioToM4AFilePath:(NSString *)audio1 outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail{
    AVURLAsset *audioAsset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:audio1]];
    AVMutableComposition *composition = [AVMutableComposition composition];
    // 音频通道
    AVMutableCompositionTrack *audioTrack1 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    // 音频采集通道
    AVAssetTrack *audioAssetTrack1 = [[audioAsset1 tracksWithMediaType:AVMediaTypeAudio] firstObject];
    // 音频合并 - 插入音轨文件
    [audioTrack1 insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioAsset1.duration) ofTrack:audioAssetTrack1 atTime:kCMTimeZero error:nil];
    
    // 合并后的文件导出 - `presetName`要和之后的`session.outputFileType`相对应。
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    NSString *outPutFilePath = outPath;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if ([fm fileExistsAtPath:outPutFilePath]) {
        [fm removeItemAtPath:outPutFilePath error:nil];
    }
    // 查看当前session支持的fileType类型
    NSLog(@"---%@",[session supportedFileTypes]);
    session.outputURL = [NSURL fileURLWithPath:outPutFilePath];
    session.outputFileType = AVFileTypeAppleM4A; //与上述的`present`相对应
    session.shouldOptimizeForNetworkUse = YES;   //优化网络
    session.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60.0, 600));

    [session exportAsynchronouslyWithCompletionHandler:^{
        if (session.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"合并成功----%@", outPutFilePath);
            [fm removeItemAtPath:audio1 error:nil];
            success(outPath);
        }else if (session.status == AVAssetExportSessionStatusFailed){
            NSLog(@"合并失败！");
            fail();
        }
    }];
    
//    if (@available(iOS 13.0, *)) {
//        [session estimateMaximumDurationWithCompletionHandler:^(CMTime estimatedMaximumDuration, NSError * _Nullable error) {
//            CMTimeShow(estimatedMaximumDuration);
//            NSLog(@"______");
//        }];
//    } else {
//        // Fallback on earlier versions
//    }
}

+ (void)convertM4aToWav:(NSString *)originalPath outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail{
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:outPath]) {
        [fm removeItemAtPath:outPath error:nil];
    }
    NSURL *originalUrl = [NSURL fileURLWithPath:originalPath];
    NSURL *outPutUrl = [NSURL fileURLWithPath:outPath];
    AVURLAsset *songAsset = [AVURLAsset URLAssetWithURL:originalUrl options:nil];    //读取原始文件信息
    NSError *error = nil;
    AVAssetReader *assetReader = [AVAssetReader assetReaderWithAsset:songAsset error:&error];
    if (error) {
        NSLog (@"error: %@", error);
        fail();
        return;
    }
    AVAssetReaderOutput *assetReaderOutput = [AVAssetReaderAudioMixOutput                                                assetReaderAudioMixOutputWithAudioTracks:songAsset.tracks                                                audioSettings: nil];
    if (![assetReader canAddOutput:assetReaderOutput]) {
        NSLog (@"can't add reader output... die!");
        fail();
        return;
    }
    [assetReader addOutput:assetReaderOutput];
    
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outPutUrl                                                            fileType:AVFileTypeCoreAudioFormat error:&error];
    if (error) {
        NSLog (@"error: %@", error);
        fail();
        return;
    }
    AudioChannelLayout channelLayout;
    memset(&channelLayout, 0, sizeof(AudioChannelLayout));
    channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    
    /** 配置音频参数 */
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,                                     [NSNumber numberWithFloat:44100.0], AVSampleRateKey,                                     [NSNumber numberWithInt:2], AVNumberOfChannelsKey,                                     [NSData dataWithBytes:&channelLayout length:sizeof(AudioChannelLayout)], AVChannelLayoutKey,[NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,                                     [NSNumber numberWithBool:NO],AVLinearPCMIsFloatKey,                                     [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey,                                    nil];
    AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio                                                                                outputSettings:outputSettings];
    if ([assetWriter canAddInput:assetWriterInput]) {
        [assetWriter addInput:assetWriterInput];
    } else {
        NSLog (@"can't add asset writer input... die!");
        fail();
        return;
    }
    assetWriterInput.expectsMediaDataInRealTime = NO;
    [assetWriter startWriting];
    [assetReader startReading];
    AVAssetTrack *soundTrack = [songAsset.tracks objectAtIndex:0];
    CMTime startTime = CMTimeMake (0, soundTrack.naturalTimeScale);
    [assetWriter startSessionAtSourceTime:startTime];
    __block UInt64 convertedByteCount = 0;
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    [assetWriterInput requestMediaDataWhenReadyOnQueue:mediaInputQueue  usingBlock: ^      {
        while (assetWriterInput.readyForMoreMediaData) {
            CMSampleBufferRef nextBuffer = [assetReaderOutput copyNextSampleBuffer];
            if (nextBuffer) {
                // append buffer
                [assetWriterInput appendSampleBuffer: nextBuffer];
                convertedByteCount += CMSampleBufferGetTotalSampleSize (nextBuffer);
            } else {
                [assetWriterInput markAsFinished];
                [assetWriter finishWritingWithCompletionHandler:^{
                }];
                [assetReader cancelReading];
                
                NSDictionary *outputFileAttributes = [[NSFileManager defaultManager]                                                        attributesOfItemAtPath:[outPutUrl path]                                                        error:nil];
                NSLog (@"FlyElephant %lld",[outputFileAttributes fileSize]);
                if ([fm fileExistsAtPath:originalPath]) {
                    [fm removeItemAtPath:originalPath error:nil];
                }
                success(outPath);
                break;
            }
        }
    }];
}

@end
