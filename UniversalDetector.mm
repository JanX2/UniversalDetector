#define uint32 CSSM_uint32
#import "UniversalDetector.h"
#undef uint32

#include "nscore.h"
#include "nsUniversalDetector.h"
#include "nsCharSetProber.h"

// You are welcome to fix this ObjC wrapper to allow initializing nsUniversalDetector with a non-zero value for aLanguageFilter!

class wrappedUniversalDetector:public nsUniversalDetector
{
public:
	wrappedUniversalDetector():nsUniversalDetector(NS_FILTER_ALL) {}
	
	void Report(const char* aCharset) {}
	
	const char *charset(float &confidence)
	{
		if(!mGotData)
		{
			confidence=0;
			return 0;
		}
		
		if(mDetectedCharset)
		{
			confidence=1;
			return mDetectedCharset;
		}
		
		switch(mInputState)
		{
			case eHighbyte:
			{
				float proberConfidence;
				float maxProberConfidence = (float)0.0;
				PRInt32 maxProber = 0;
				
				for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
				{
					if (mCharSetProbers[i])
					{
						proberConfidence = mCharSetProbers[i]->GetConfidence();
						if (proberConfidence > maxProberConfidence)
						{
							maxProberConfidence = proberConfidence;
							maxProber = i;
						}
					}
				}
				
				if (mCharSetProbers[maxProber]) {
					confidence=maxProberConfidence;
					return mCharSetProbers[maxProber]->GetCharSetName();
				}
			}
				break;
				
			case ePureAscii:
				confidence=1.0;
				return "UTF-8";
			default:
				break;
		}
		
		confidence=0;
		return 0;
	}
	
	bool done()
	{
		if(mDetectedCharset) return true;
		return false;
	}
	
	/*
	 void debug()
	 {
	 for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
	 {
	 // If no data was received the array might stay filled with nulls
	 // the way it was initialized in the constructor.
	 if (mCharSetProbers[i])
	 mCharSetProbers[i]->DumpStatus();
	 }
	 }
	 */
	
	void reset() { Reset(); }
};

@implementation UniversalDetector
{
	wrappedUniversalDetector *detectorPtr;
}

@synthesize MIMECharset = charsetName;
@synthesize confidence;

+(instancetype)detector
{
	return [[self alloc] init];
}

+(NSArray *)possibleMIMECharsets
{
	static NSArray *array=nil;
	
	if(!array) array=[[NSArray alloc] initWithObjects:
					  @"UTF-8",@"UTF-16BE",@"UTF-16LE",@"UTF-32BE",@"UTF-32LE",
					  @"ISO-8859-2",@"ISO-8859-5",@"ISO-8859-7",@"ISO-8859-8",@"ISO-8859-8-I",
					  @"windows-1250",@"windows-1251",@"windows-1252",@"windows-1253",@"windows-1255",
					  @"KOI8-R",@"Shift_JIS",@"EUC-JP",@"EUC-KR"/* actually CP949 */,@"x-euc-tw",
					  @"ISO-2022-JP",@"ISO-2022-CN",@"ISO-2022-KR",
					  @"Big5",@"GB2312",@"HZ-GB-2312",@"gb18030",@"GB18030",
					  @"IBM855",@"IBM866",@"TIS-620",@"X-ISO-10646-UCS-4-2143",@"X-ISO-10646-UCS-4-3412",
					  @"x-mac-cyrillic",@"x-mac-hebrew",
					  nil];
	
	return array;
}


-(id)init
{
	self = [super init];
	
	if(self)
	{
		detectorPtr = new wrappedUniversalDetector();
		charsetName = nil;
		confidence  = 0;
	}
	return self;
}

-(void)dealloc
{
	delete detectorPtr;
}

-(void)analyzeContentsOfFile:(NSString *)path
{
	NSData *data = [[NSData alloc] initWithContentsOfMappedFile:path];

	if (data) {
		[self analyzeBytes:(const char *)[data bytes] length:(int)[data length]];
	}
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:(int)[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	if (detectorPtr->done()) {
		return;
	}
	detectorPtr->HandleData(data, len);
	charsetName=nil;
}

-(void)reset
{
	detectorPtr->reset();
}

-(BOOL)isDone
{
	return detectorPtr->done();
}

-(BOOL)done
{
	//deprecated, do not use
	return [self isDone];
}

-(NSString *)MIMECharset
{
	if(!charsetName)
	{
		const char *cstr=detectorPtr->charset(confidence);
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

	return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

-(float)confidence
{
	if(!charsetName) [self MIMECharset];
	return confidence;
}

@end
