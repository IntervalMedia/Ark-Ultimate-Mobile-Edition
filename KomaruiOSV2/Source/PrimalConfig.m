// PrimalConfig.m

#import "PrimalConfig.h"

// Declare external global variables if they are defined elsewhere
extern void* gLocalProfileData;
extern NSUInteger gLocalProfileSize;

void WritePrimalConfig() {
    NSData *fileData = [NSData dataWithBytesNoCopy:(void *)gLocalProfileData
                                            length:gLocalProfileSize
                                      freeWhenDone:NO];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"ShooterGame/Saved/SavedArksLocal"];
    NSString *arkprodDirectory = [directory stringByAppendingPathComponent:@"LocalPlayer.arkprod"];

    // Ensure the destination directory exists
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:directory]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"Error creating directory: %@", error.localizedDescription);
            return;
        }
    }

    // Write the data to the destination file
    BOOL success = [fileData writeToFile:arkprodDirectory options:NSDataWritingAtomic error:NULL];
    if (!success) {
        NSLog(@"Failed to write LocalPlayer.arkprod to %@", arkprodDirectory);
    } else {
        NSLog(@"Successfully wrote LocalPlayer.arkprod to %@", arkprodDirectory);
    }
}
