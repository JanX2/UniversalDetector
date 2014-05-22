#import <Foundation/Foundation.h>

// You can enable this heuristic by setting the BOOL with that key in NSUserDefaults -standardUserDefaults to YES.
// In this case, only -encoding wll be valid and -MIMECharset will be invalid.
extern NSString * const	UniversalDetectorUseMacRomanHeuristic;

@interface UniversalDetector:NSObject
{
	void *detectorPtr;
	NSString *charsetName;
	float confidence;
	BOOL possiblyMacRoman;
}

-(void)analyzeContentsOfFile:(NSString *)path;
-(void)analyzeData:(NSData *)data;
-(void)analyzeBytes:(const char *)data length:(int)len;
-(void)reset;

-(BOOL)done;
-(NSString *)MIMECharset;
-(NSStringEncoding)encoding;
-(float)confidence;

@end
