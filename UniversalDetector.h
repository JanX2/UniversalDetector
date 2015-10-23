#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UniversalDetector:NSObject

+(instancetype)detector;
+(NSArray<NSString*> *)possibleMIMECharsets;

-(instancetype)init NS_DESIGNATED_INITIALIZER;

-(void)analyzeContentsOfFile:(NSString *)path;
-(void)analyzeData:(NSData *)data;
-(void)analyzeBytes:(const char *)data length:(int)len;
-(void)reset;

@property (nonatomic, readonly, getter=isDone) BOOL done;
@property (nonatomic, copy, readonly, nullable) NSString *MIMECharset;
@property (readonly, nonatomic) NSStringEncoding encoding;
@property (readonly) float confidence;

@end

NS_ASSUME_NONNULL_END
