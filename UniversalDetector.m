#import "UniversalDetector.h"
#import "WrappedUniversalDetector.h"

@implementation UniversalDetector

-(id)init
{
	self = [super init];
	
	if(self)
	{
		detectorPtr = AllocUniversalDetector();
		charsetName = nil;
		confidence  = 0;
	}
	return self;
}

-(void)dealloc
{
	FreeUniversalDetector(detectorPtr);
	[charsetName release];
	[super dealloc];
}

-(void)analyzeContentsOfFile:(NSString *)path
{
	NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];

	if (data) {
		[self analyzeBytes:(const char *)[data bytes] length:[data length]];
	}
	[data release];
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	UniversalDetectorHandleData(detectorPtr, data, len);
	[charsetName release];
	charsetName=nil;
}

-(void)reset
{
	UniversalDetectorReset(detectorPtr);
}

-(BOOL)done
{
	return UniversalDetectorDone(detectorPtr);
}

-(NSString *)MIMECharset
{
	if(!charsetName)
	{
		const char *cstr=UniversalDetectorCharset(detectorPtr, &confidence);
		if(!cstr) return nil;
		charsetName=[[NSString alloc] initWithUTF8String:cstr];
	}
	return charsetName;
}

-(NSStringEncoding)encoding
{
	NSString *mimecharset=[self MIMECharset];
	if(!mimecharset) return 0;

	CFStringEncoding cfenc=CFStringConvertIANACharSetNameToEncoding((CFStringRef)mimecharset);
	if(cfenc==kCFStringEncodingInvalidId) return 0;

	// UniversalDetector detects CP949 but returns "EUC-KR" because CP949 lacks an IANA name.
	// Kludge to make strings decode properly anyway.
	if(cfenc==kCFStringEncodingEUC_KR) cfenc=kCFStringEncodingDOSKorean;
	// Something similar happens with "Shift_JIS".
	if(cfenc==kCFStringEncodingShiftJIS) cfenc=kCFStringEncodingDOSJapanese;

	NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfenc);
	
	return encoding;
}

-(float)confidence
{
	if(!charsetName) [self MIMECharset];
	return confidence;
}

@end
