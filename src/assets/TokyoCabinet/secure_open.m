//
//  secure_open.m
//  TSDocDB
//
//  Created by Daniel Persinger on 10/31/12.
//  Copyright (c) 2012 Ticklespace.com. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "UIKit/UIDevice.h"

#import "secure_open.h"
#import "fcntl.h"
#import <sys/xattr.h>

void sec_disablePathForCloudBackup(NSString *path);

int secure_open(const char* path, int mode, int HDBFILEMODE) {
    NSString *objc_path = [[NSString alloc] initWithCString:path encoding:NSASCIIStringEncoding];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:objc_path]) {
        NSDictionary* attrs = [NSDictionary dictionaryWithObject:NSFileProtectionComplete forKey:NSFileProtectionKey];
        NSLog(@"TCDB, setting encryption flag on path: %@", objc_path);
    
        [[NSFileManager defaultManager] createFileAtPath:objc_path contents:[NSData data] attributes:(NSDictionary *)attrs];
        sec_disablePathForCloudBackup(objc_path);
    }
    
    return open(path, mode, HDBFILEMODE);
}

void sec_disablePathForCloudBackup(NSString *path) {
    NSString *os5 = @"5.0";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    NSError *error;
    
    NSURL *URL = [NSURL fileURLWithPath:path];
    
    // Mark files to not backup to iCloud.
    if ([currSysVer compare:@"5.0.1" options:NSNumericSearch] == NSOrderedDescending) {
        // Later than 5.0.1
        NSLog(@"For ios later than 5.0.1, excluding file from backup: %@", path);
        BOOL bSuccess = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                       forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!bSuccess){
            NSLog(@"Error excluding %@ from backup %@", path, error);
        }
        
    } else {
        // Handle 5.0.1
        NSLog(@"For ios EQUAL to 5.0.1, excluding file from backup: %@", path);
        const char* attrName = "com.apple.MobileBackup";
        u_int8_t attrValue = 1;
        
        const char* filePath = [[URL path] fileSystemRepresentation];
        
        if (setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0) != 0) {
            NSLog(@"Error excluding %@ from backup on iOS 5.0.1", path);
        }
    }
    
}
