#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import <UniversalDetector/UniversalDetector.h>

int main(int argc,char **argv)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
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
			NSLog(@"%@", error);
			continue;
		}
		
		NSString *str = nil;

		if (data == nil) {
			str = [NSString stringWithFormat:@"%@\n\t%@", fileName, error];
		}

		if (data.length == 0) {
			str = [NSString stringWithFormat:@"%@\n\t%@", fileName, @"Error: empty file!"];
		}
		
		if (str) {
			printf("%s\n\n", [str UTF8String]);
			continue;
		}

		[detector analyzeData:data];
		NSString *MIMECharsetName = [detector MIMECharset];
		NSStringEncoding encoding = [detector encoding];
		NSStringEncoding appKitEncoding = 0;
		
		//if (encoding == NSWindowsCP1252StringEncoding || encoding == NSShiftJISStringEncoding)
		{
			NSDictionary *documentAttributes = nil;
			
			// UniversalDetector does not differentiate between Windows Latin 1 and Mac Roman
			// while AppKit has an apparent Mac Roman bias.
			NSAttributedString *text = [[NSAttributedString alloc] initWithData:data
																		options:nil
															 documentAttributes:&documentAttributes
																		  error:&error];
			
			if (text == nil) {
				NSLog(@"%@", error);
				continue;
			}
			else {
				[text release];
				
				NSNumber *encodingNumber = documentAttributes[NSCharacterEncodingDocumentAttribute];
				appKitEncoding = [encodingNumber intValue];
			}
		}
		
		NSString *appKitResultString = nil;
		if (appKitEncoding != 0) {
			if (appKitEncoding != encoding) {
				appKitResultString = [NSString stringWithFormat:@"\"%@\"",
									  [NSString localizedNameOfStringEncoding:appKitEncoding]
									  ];
			}
			else {
				appKitResultString = @"(same result)";
			}
		}
		
		str = [NSString stringWithFormat:
			   @"%@\n"
			   "\t" "\"%@\" (%@)\n"
			   "\t" "confidence:% 6.1f%%"
			   @"\n"
			   "\t" "AppKit: %@",
			   fileName,
			   (encoding != 0) ? [NSString localizedNameOfStringEncoding:encoding] : @"UNKNOWN",
			   (MIMECharsetName != nil) ? MIMECharsetName : @"UNKNOWN",
			   ([detector confidence] * 100.0f),
			   (appKitResultString != nil) ? appKitResultString : @"UNDEFINED"
			   ];
		
			
		
		printf("%s\n\n", [str UTF8String]);
		
	
		[detector release];
	}
	
	[pool release];
	
	return EXIT_SUCCESS;
}