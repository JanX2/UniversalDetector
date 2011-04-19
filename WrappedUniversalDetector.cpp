#include "WrappedUniversalDetector.h"

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



extern "C" {

void *AllocUniversalDetector()
{
	return (void *)new wrappedUniversalDetector;
}

void FreeUniversalDetector(void *detectorPtr)
{
	delete (wrappedUniversalDetector *)detectorPtr;
}

void UniversalDetectorHandleData(void *detectorPtr,const char *data,int length)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	if(detector->done()) return;
	detector->HandleData(data,length);
}

void UniversalDetectorReset(void *detectorPtr)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	detector->reset();
}

int UniversalDetectorDone(void *detectorPtr)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	return detector->done()?1:0;
}

const char *UniversalDetectorCharset(void *detectorPtr, float *confidence)
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorPtr;
	return detector->charset(*confidence);
}

}
