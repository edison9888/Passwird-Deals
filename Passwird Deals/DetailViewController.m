//
//  DetailViewController.m
//  Passwird Deals
//
//  Created by Patrick Crager on 3/18/12.
//  Copyright (c) 2012 McCrager. All rights reserved.
//

#import "DetailViewController.h"
#import "WebViewController.h"

#import "Constants.h"
#import "Flurry.h"

#import <Twitter/Twitter.h>

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem {
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
}

#pragma mark - Managing the action sheet

- (void)openMail {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        [mailer setMailComposeDelegate:self];
        [mailer.navigationBar setTintColor:[UIColor darkGrayColor]];
        [mailer setSubject:EMAIL_SUBJECT_SHARE];
        
        NSString *emailBody = [NSString stringWithFormat:EMAIL_BODY_SHARE, self.detailItem.headline, self.detailItem.body];
        [mailer setMessageBody:emailBody isHTML:YES];
        
        [self presentModalViewController:mailer animated:YES];
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
    [Flurry logEvent:FLURRY_ACTION];
 
    if (self.actionSheet == nil) {
        UIActionSheet *sheet;

        if ([SLComposeViewController class]) {
            sheet = [[UIActionSheet alloc] initWithTitle:@"Deal Options"
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Post to Facebook", @"Tweet Deal", @"Email Deal", nil];
        }
        else {
            sheet = [[UIActionSheet alloc] initWithTitle:@"Deal Options"
                                                delegate:self 
                                       cancelButtonTitle:@"Cancel" 
                                  destructiveButtonTitle:nil
                                       otherButtonTitles:@"Tweet Deal", @"Email Deal", nil];
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
            default: //cancel button
                break;
        }
    }
}

#pragma mark - Managing the web view

- (BOOL)webView:(UIWebView*)theWebView shouldStartLoadWithRequest:(NSURLRequest*)request navigationType:(UIWebViewNavigationType)navigationType {    
    if( navigationType == UIWebViewNavigationTypeLinkClicked ) {
        [self setSelectedURL:request.URL];
        [self performSegueWithIdentifier: @"Web" sender: self];
        return NO;
    } 
    return YES; 
}

- (void)loadDealIntoWebView {    
    // Update the user interface for the detail item.
    if (self.detailItem) {
        [self.navigationItem setTitle:@"Deal"];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"EEEE, MMMM d yyyy"];
        NSString *dateAsString = [formatter stringFromDate:[self.detailItem.datePosted dateByAddingTimeInterval:60*60*24*1]];
        
        NSError *error;
        NSStringEncoding encoding;
        NSString *dealHtmlFilePath = [[NSBundle mainBundle] pathForResource: @"Deal" 
                                                                     ofType: @"html"];
        NSString *dealHtmlString = [NSString stringWithContentsOfFile:dealHtmlFilePath 
                                                   usedEncoding:&encoding 
                                                          error:&error];
        
        NSString *html = [NSString stringWithFormat:dealHtmlString, 
                            dateAsString, 
                            self.detailItem.headline, 
                            (self.detailItem.isExpired ? @"(expired)" : @""), 
                            self.detailItem.imageURL, 
                            self.detailItem.body];
        
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSURL *baseURL = [NSURL fileURLWithPath:path];
        
        [self.webView loadHTMLString:html baseURL:baseURL];
    }
}

#pragma mark - Managing the split view

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

#pragma mark - View lifecycle

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Pass selected URL and deal to web controller
    WebViewController *webController = segue.destinationViewController;
    [webController setPushedURL:self.selectedURL];
    [webController setDetailItem:self.detailItem];
}

- (void)configureView {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    [self loadDealIntoWebView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [Flurry logPageView];
    
    [self configureView];
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [self setShareButton:nil];
    [self setActionSheet:nil];
    [super viewDidUnload];
}

@end