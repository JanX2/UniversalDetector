#import <Foundation/Foundation.h>

#import <UniversalDetector/UniversalDetector.h>

int main(int argc,char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *str = nil;
	NSError *error = nil;
	
	for (int i = 1; i < argc; i++)
	{
		// You need a new detector for each piece of data you want to examine!
		UniversalDetector *detector = [UniversalDetector new];
	
		NSString *filePath = [NSString stringWithUTF8String:argv[i]];
		NSString *fileName = [filePath lastPathComponent];
		
		NSData *data = [NSData dataWithContentsOfFile:filePath
											  options:0
												error:&error];
		if (data == nil) {
			str = [NSString stringWithFormat:@"%@\n\t%@", fileName, error];
			printf("%s", [str UTF8String]);
			continue;
		}
		
		[detector analyzeData:data];
		
		str = [NSString stringWithFormat:@"%@\n\t\"%@\" (%@) confidence: %.1f%%",
			   fileName,
			   [NSString localizedNameOfStringEncoding:[detector encoding]], 
			   [detector MIMECharset], 
			   ([detector confidence] * 100.0f) 
			   ];
		printf("%s\n\n", [str UTF8String]);
		
	
		[detector release];
	}
	
	[pool release];
	return 0;
}