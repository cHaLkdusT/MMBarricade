//
//  ViewController.m
//  BarricadeExample
//
//  Created by John McIntosh on 5/8/15.
//  Copyright (c) 2015 Mutual Mobile. All rights reserved.
//

#import "ViewController.h"
#import "MMBarricade.h"
#import "MMBarricadeViewController.h"


@interface ViewController () <MMBarricadeViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *statusCodeLabel;
@property (nonatomic, weak) IBOutlet UITextView *responseHeadersTextView;
@property (nonatomic, weak) IBOutlet UITextView *responseTextView;

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureBarricade];
}

- (void)configureBarricade {
    [MMBarricade setupWithInMemoryResponseStore];
    [MMBarricade enable];
    
    MMBarricadeResponseSet *responseSet = [MMBarricadeResponseSet responseSetForRequestName:@"Search" respondsToRequest:^BOOL(NSURLRequest *request, NSURLComponents *components) {
        return [components.path hasSuffix:@"search/repositories"];
    }];
    
    [responseSet addResponseWithName:@"success"
                                file:MMPathForFileInMainBundleDirectory(@"search.success.json", @"LocalServerFiles")
                          statusCode:200
                         contentType:@"application/json"];
    
    [responseSet addResponseWithName:@"no results"
                                file:MMPathForFileInMainBundleDirectory(@"search.empty.json", @"LocalServerFiles")
                          statusCode:200
                         contentType:@"application/json"];
    
    [responseSet addResponseWithName:@"rate limited"
                                file:MMPathForFileInMainBundleDirectory(@"search.ratelimited.json", @"LocalServerFiles")
                          statusCode:403
                             headers:@{
                                       @"X-RateLimit-Limit": @"60",
                                       @"X-RateLimit-Remaining": @"0",
                                       @"X-RateLimit-Reset": @"1377013266",
                                       MMBarricadeContentTypeHeaderKey: @"application/json",
                                       }];
    
    [MMBarricade registerResponseSet:responseSet];
}


#pragma mark - IBActions

- (IBAction)openBarricadeButtonPressed:(id)sender {
    MMBarricadeViewController *viewController = [[MMBarricadeViewController alloc] init];
    viewController.barricadeDelegate = self;
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)triggerRequestButtonPressed:(id)sender {
    // Fetch the top 5 most starred Objective-C repositories on Github
    NSURL *URL = [NSURL URLWithString:@"https://api.github.com/search/repositories?q=language:Objective-C&sort=stars&order=desc&per_page=5"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL];
    
    [NSURLConnection
     sendAsynchronousRequest:request
     queue:[NSOperationQueue mainQueue]
     completionHandler:^(NSURLResponse *URLResponse, NSData *data, NSError *connectionError) {
         NSHTTPURLResponse *response = (NSHTTPURLResponse *)URLResponse;
         self.statusCodeLabel.text = [NSString stringWithFormat:@"%li", (long)response.statusCode];
         self.responseHeadersTextView.text = response.allHeaderFields.description;
         self.responseTextView.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
     }];
}


#pragma mark - MMBarricadeViewControllerDelegate

- (void)barricadeViewControllerTappedDone:(MMBarricadeViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
