#ifndef __WrappedUniversalDetector_h__
#define __WrappedUniversalDetector_h__

#ifdef __cplusplus
extern "C" {
#endif

void *AllocUniversalDetector(void);
void FreeUniversalDetector(void *detectorPtr);
void UniversalDetectorHandleData(void *detectorPtr,const char *data,int length);
void UniversalDetectorReset(void *detectorPtr);
int UniversalDetectorDone(void *detectorPtr);
const char *UniversalDetectorCharset(void *detectorPtr,float *confidence);


#ifdef __cplusplus
}
#endif

#endif
