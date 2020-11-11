#import "UniversalDetector.h"
#import "WrappedUniversalDetector.h"


NSString * const	UniversalDetectorUseMacRomanHeuristic			= @"UniversalDetectorUseMacRomanHeuristic";


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
    NSData *data = [[NSData alloc] initWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL];

	if (data) {
		[self analyzeBytes:(const char *)[data bytes] length:(int)[data length]];
	}
	[data release];
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:(int)[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	UniversalDetectorHandleData(detectorPtr, data, len);
	
	BOOL useMacRomanHeuristic = [[NSUserDefaults standardUserDefaults] boolForKey:UniversalDetectorUseMacRomanHeuristic];

	if (useMacRomanHeuristic) {
		// Search for a carriage return (cr) without a following newline.
		// We do this to determine, if the data could possibly be MacRoman.
		const size_t searchWindowSize = 4096;
		char *crPtr = memchr(data, '\r', MIN(len, searchWindowSize));
		if (crPtr == NULL) {
			possiblyMacRoman = NO;
		}
		else {
			const int lastIndex = len - 1;
			int crIndex = (crPtr - data);
			
			// Check, if we are at least one byte before the end.
			if (crIndex < lastIndex) {
				if (data[crIndex+1] == '\n') {
					possiblyMacRoman = NO;
				}
				else {
					possiblyMacRoman = YES;
				}
			}
			else {
				possiblyMacRoman = YES;
			}
		}
	}
	else {
		possiblyMacRoman = NO;
	}
	
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
	
	if (possiblyMacRoman &&
		(encoding == NSWindowsCP1252StringEncoding ||
		 encoding == NSShiftJISStringEncoding)) {
			encoding = NSMacOSRomanStringEncoding;
	}
	
	return encoding;
}

-(float)confidence
{
	if(!charsetName) [self MIMECharset];
	return confidence;
}

@end
