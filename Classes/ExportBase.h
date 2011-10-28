// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
 * CashFlow for iOS
 * Copyright (C) 2008-2011, Takuya Murakami, All rights reserved.
 * For conditions of distribution and use, see LICENSE file.
 */

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <DropboxSDK/DropboxSDK.h>

#import "ExportServer.h"
#import "Asset.h"

#define REPLACE(from, to) \
  [str replaceOccurrencesOfString: from withString: to \
  options:NSLiteralSearch range:NSMakeRange(0, [str length])]
	
@interface ExportBase : NSObject <UIAlertViewDelegate, MFMailComposeViewControllerDelegate, DBRestClientDelegate> {
    NSDate *mFirstDate;
    NSArray *__unsafe_unretained mAssets;

    ExportServer *mWebServer;
    
    // for dropbox
    DBRestClient *mRestClient;
}

@property(nonatomic,retain) NSDate *firstDate;
@property(nonatomic,assign) NSArray *assets;

@property(nonatomic,readonly) DBRestClient *restClient;

// public methods
- (BOOL)sendMail:(UIViewController*)parent;
- (BOOL)sendToDropbox:(UIViewController*)parent;
- (BOOL)sendWithWebServer;

// You must override following methods
- (NSString *)mailSubject;
- (NSString*)fileName;
- (NSString *)mimeType;
- (NSString *)contentType;
- (NSData*)generateBody;

// internal
- (void)_sendToDropbox;
- (void)_showResult:(NSString *)message;

@end

