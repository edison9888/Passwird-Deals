//
//  WebViewController.m
//  Passwird Deals
//
//  Created by Patrick Crager on 3/18/12.
//  Copyright (c) 2012 McCrager. All rights reserved.
//

#import "WebViewController.h"

#import "Constants.h"
#import "Flurry.h"

#import <Twitter/Twitter.h>

@implementation WebViewController

#pragma mark - Managing the action sheet

- (void)openMail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        [mailer setMailComposeDelegate:self];
        [mailer.navigationBar setTintColor:[UIColor darkGrayColor]];
        [mailer setSubject:EMAIL_SUBJECT_SHARE];

        NSString *emailBody = [NSString stringWithFormat:EMAIL_SUBJECT_SHARE, self.detailItem.headline, self.detailItem.body];
        [mailer setMessageBody:emailBody isHTML:YES];
        
        [self presentModalViewController:mailer animated:YES];
        
        mailer = nil;
    } else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ERROR_TITLE
                                                            message:ERROR_MAIL_SUPPORT
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
        [alertView show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller 
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError*)error {
    if (result) {
        //error occured sending mail
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ERROR_TITLE
                                                            message:ERROR_MAIL_SEND
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles: nil];
        [alertView show];
    } else {
        // Remove the mail view
        [self dismissModalViewControllerAnimated:YES];
    }
}

- (void)copyURL {
    NSURL *currentURL = [self.webView.request URL];
    [[UIPasteboard generalPasteboard] setString: [currentURL absoluteString]];
}

- (void)openInSafari {
    NSURL *currentURL = [self.webView.request URL];
    [[UIApplication sharedApplication] openURL:currentURL];
}

- (void)tweetDeal {
    NSError *error;
    NSStringEncoding encoding;
    NSString *tweetFilePath = [[NSBundle mainBundle] pathForResource: @"Tweet" 
                                                              ofType: @"txt"];
    NSString *tweetString = [NSString stringWithContentsOfFile:tweetFilePath 
                                                  usedEncoding:&encoding 
                                                         error:&error];
    NSString *tweet = [NSString stringWithFormat:tweetString, self.detailItem.headline];
    
    if ([SLComposeViewController class]) {
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
            SLComposeViewController *share = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
            [share setInitialText:tweet];
            [self presentViewController:share animated:YES completion:nil];
            
            return;
        }
    } else {
        if ([TWTweetComposeViewController canSendTweet]) {
            TWTweetComposeViewController *tweetSheet = [[TWTweetComposeViewController alloc] init];
            [tweetSheet setInitialText:tweet];
            [self presentModalViewController:tweetSheet animated:YES];
            
            tweetSheet = nil;
            return;
        }
    }
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ERROR_TITLE
                                                        message:ERROR_TWITTER
                                                       delegate:self                                              
                                              cancelButtonTitle:@"OK"                                                   
                                              otherButtonTitles:nil];
    [alertView show];
}

- (void)postToFacebook {
    if ([SLComposeViewController class]) {
        NSError *error;
        NSStringEncoding encoding;
        NSString *facebookFilePath = [[NSBundle mainBundle] pathForResource: @"Facebook"
                                                                     ofType: @"txt"];
        NSString *facebookString = [NSString stringWithContentsOfFile:facebookFilePath
                                                         usedEncoding:&encoding 
                                                                error:&error];
        NSString *facebook = [NSString stringWithFormat:facebookString, self.detailItem.headline];
        
        if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
            SLComposeViewController *share = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
            
            [share setInitialText:facebook];
            
            [self presentViewController:share animated:YES completion:nil];
        }
        else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:ERROR_TITLE
                                                                message:ERROR_FACEBOOK
                                                               delegate:self                                              
                                                      cancelButtonTitle:@"OK"                                                   
                                                      otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (IBAction)showActionSheet:(id)sender {
    [Flurry logEvent:@"Action Sheet"];
    
    if (self.actionSheet == nil) {
        UIActionSheet *sheet;
        
        if ([SLComposeViewController class]) {
            sheet = [[UIActionSheet alloc] initWithTitle:@"Deal Options"
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Post to Facebook", @"Tweet Deal", @"Email Deal", @"Copy URL", @"Open in Safari", nil];
        }
        else {
            sheet = [[UIActionSheet alloc] initWithTitle:@"Deal Options"
                                                delegate:self
                                       cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Tweet Deal", @"Email Deal", @"Copy URL", @"Open in Safari", nil];
        }
        
        [sheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];

        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            [sheet showFromBarButtonItem:sender animated:YES];
        }
        else {
            [sheet showInView:self.parentViewController.view];
        }
        
        [self setActionSheet:sheet];
    } else {
        [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([SLComposeViewController class]) {
        switch (buttonIndex) {
            case 0:
                [Flurry logEvent:FLURRY_FACEBOOK];
                [self postToFacebook];
                break;
            case 1:
                [Flurry logEvent:FLURRY_TWITTER];
                [self tweetDeal];
                break;
            case 2:
                [Flurry logEvent:FLURRY_EMAIL];
                [self openMail];
                break;
            case 3:
                [Flurry logEvent:FLURRY_COPY];
                [self copyURL];
                break;
            case 4:
                [Flurry logEvent:FLURRY_SAFARI];
                [self openInSafari];
                break;
            default: //cancel button
                break;
        }
    }
    else {
        switch (buttonIndex) {
            case 0:
                [Flurry logEvent:FLURRY_TWITTER];
                [self tweetDeal];
                break;
            case 1:
                [Flurry logEvent:FLURRY_EMAIL];
                [self openMail];
                break;
            case 2:
                [Flurry logEvent:FLURRY_COPY];
                [self copyURL];
                break;
            case 3:
                [Flurry logEvent:FLURRY_SAFARI];
                [self openInSafari];
                break;
            default: //cancel button
                break;
        }
    }
}

#pragma mark - Managing the web view

- (IBAction)goBack:(id)sender {
    [self.webView goBack]; 
}

- (IBAction)goForward:(id)sender {
    [self.webView goForward]; 
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self.activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self.activityIndicator stopAnimating];
    
    if ([self.webView canGoBack])
        [self.backButton setEnabled:YES];
    else
        [self.backButton setEnabled:NO];  
    
    if ([self.webView canGoForward])
        [self.forwardButton setEnabled:YES];   
    else
        [self.forwardButton setEnabled:NO];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - View lifecycle

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Flurry logPageView];
    
    NSLog(@"Pushed URL: %@", self.pushedURL);
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.pushedURL]];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setActivityIndicator:nil];
    [self setBackButton:nil];
    [self setForwardButton:nil];
    [self setActionSheet:nil];
    [super viewDidUnload];
}

@end