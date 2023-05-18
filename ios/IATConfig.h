//
//  IATConfig.h
//  MSCDemo_UI
//
//  Created by wangdan on 15-4-25.
//  Copyright (c) 2015年 iflytek. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SuccessBlock)(NSString *outpath);
typedef void(^FailBlock)(void);

@interface IATConfig : NSObject

+(IATConfig *)sharedInstance;

+(NSString *)french;
+(NSString *)spanish;
+(NSString *)korean;
+(NSString *)japanese;
+(NSString *)russian;
+(NSString *)mandarin;
+(NSString *)cantonese;
+(NSString *)sichuanese;
+(NSString *)chinese;
+(NSString *)english;
+(NSString *)lowSampleRate;
+(NSString *)highSampleRate;
+(NSString *)isDot;
+(NSString *)noDot;
+(NSString *) getAndCreatePlayableFileFromPcmData:(NSString *)filePath withWavFilePath:(NSString *)wavFilePath;
+(void)mergeAudioPath:(NSString *)audio1 withPath:(NSString *)audio2 outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail;

+(void)convertAudioToM4AFilePath:(NSString *)audio1 outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail;

+ (void)convertM4aToWav:(NSString *)originalPath outPath:(NSString *)outPath success:(SuccessBlock)success fail:(FailBlock)fail;

@property (nonatomic, strong) NSString *speechTimeout;
@property (nonatomic, strong) NSString *vadEos;
@property (nonatomic, strong) NSString *vadBos;

@property (nonatomic, strong) NSString *language;
@property (nonatomic, strong) NSString *accent;

@property (nonatomic, strong) NSString *dot;
@property (nonatomic, strong) NSString *sampleRate;

@property (nonatomic) BOOL  isTranslate;//whether or not to open translation



@property (nonatomic, assign) BOOL haveView;
@property (nonatomic, strong) NSArray *accentIdentifer;
@property (nonatomic, strong) NSArray *accentNickName;


@end
