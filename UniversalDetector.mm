#define uint32 CSSM_uint32
#import "UniversalDetector.h"
#undef uint32

#import "nscore.h"
#import "nsUniversalDetector.h"
#import "nsCharSetProber.h"

// You are welcome to fix this ObjC wrapper to allow initializing nsUniversalDetector with a non-zero value for aLanguageFilter!

class wrappedUniversalDetector:public nsUniversalDetector
{
	public:
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
				confidence=0;
				return "US-ASCII";
		}

		confidence=0;
		return 0;
	}

	bool done()
	{
		if(mDetectedCharset) return true;
		return false;
	}
    
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

	void reset() { Reset(); }
};



@implementation UniversalDetector

-(id)init
{
	if(self=[super init])
	{
		detectorPtr=(void *)new wrappedUniversalDetector;
		charsetName=nil;
	}
	return self;
}

-(void)dealloc
{
	delete (wrappedUniversalDetector *)detectorPtr;
	[charsetName release];
	[super dealloc];
}

-(void)finalize
{
	delete (wrappedUniversalDetector *)detectorPtr;
	[super finalize];
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;

	if(detector->done()) return;

	detector->HandleData(data,len);
	[charsetName release];
	charsetName=nil;
}

-(void)reset
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	detector->reset();
}

-(BOOL)done
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	return detector->done()?YES:NO;
}

-(NSString *)MIMECharset
{
	if(!charsetName)
	{
		wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
		const char *cstr=detector->charset(confidence);
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
	return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

-(float)confidence
{
	if(!charsetName) [self MIMECharset];
	return confidence;
}

-(void)debugDump
{
    wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
    return detector->debug();
}

+(UniversalDetector *)detector
{
	return [[[UniversalDetector alloc] init] autorelease];
}

@end
