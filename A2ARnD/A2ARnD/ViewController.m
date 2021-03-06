//
//  ViewController.m
//  A2ARnD
//
//  Created by Ron on 10/20/14.
//  Copyright (c) 2014 Flint Mobile, Inc. All rights reserved.
//

#import "ViewController.h"
#import "ResponseViewController.h"

@interface ViewController () {
    NSInteger scrollviewFullHeight;
}

@property (weak, nonatomic) IBOutlet UITextField *descTextField;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UITextField *taxTextField;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (strong, nonatomic) NSString *resultText;
@property (weak, nonatomic) IBOutlet UITextField *partnerIdTextField;
@property (weak, nonatomic) IBOutlet UITextField *customerNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *customerPhoneTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *durationTextField;
@property (weak, nonatomic) IBOutlet UITextField *hourlyRateTextField;
@property (weak, nonatomic) IBOutlet UITextField *parametersTextField;
@property (nonatomic) CGRect scrollviewFrame;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    self.scrollviewFrame = self.scrollView.frame;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidOpenUrl:)
                                                 name:@"OPEN_URL_EVENT"
                                               object:nil];

    // Sign up for the keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uiKeyboardWillShowNotification:) name:@"UIKeyboardWillShowNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(uiKeyboardWillHideNotification:) name:@"UIKeyboardWillHideNotification"
                                               object:nil];

}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  
  [self.scrollView setContentSize:CGSizeMake(CGRectGetWidth(self.view.bounds), 700)];
  scrollviewFullHeight = self.scrollView.frame.size.height;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ToResponse"])
    {
        ResponseViewController *rvc = [segue destinationViewController];
        UIView *theView = rvc.view;  // cause the view to load
        rvc.responseTextView.text = self.resultText;
    }
}

- (void)uiKeyboardWillShowNotification:(NSNotification *)theNotification
{
    self.scrollviewFrame = self.scrollView.frame;

    NSDictionary *userInfo = theNotification.userInfo;
    
    NSValue *keyboardRectValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [keyboardRectValue CGRectValue];
    
    CGRect newFrame = self.scrollView.frame;
    newFrame.size.height = newFrame.size.height - (keyboardRect.size.height - (self.view.frame.size.height - self.scrollView.frame.size.height));
    self.scrollView.frame = newFrame;
}

- (void)uiKeyboardWillHideNotification:(NSNotification *)theNotification
{
//    CGRect newFrame = self.scrollView.frame;
//    newFrame.size.height = scrollviewFullHeight;
    self.scrollView.frame = self.scrollviewFrame;
    
}

- (void)appDidOpenUrl:(NSNotification *)notification
{
    NSURL *url = (NSURL *)notification.object;
    
    NSMutableString *str = [NSMutableString new];
    [str appendString:@"Callback URL from Flint\n\n"];

    [str appendFormat:@"url:  %@\n\n", url];
    [str appendFormat:@"url scheme:  %@\n\n", [url scheme]];
    [str appendFormat:@"url resourceSpecifier:  %@\n\n", [url resourceSpecifier]];
    [str appendFormat:@"url host:  %@\n\n", [url host]];
    [str appendFormat:@"url query:  %@\n\n", [url query]];
    [str appendFormat:@"url path:  %@\n\n", [url path]];
    
    self.resultText = str;

}

- (void)showError:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Error"
                              message:errorMessage
                              delegate:self
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
    
    [alertView show];
    
}

- (IBAction)acceptPaymentButtonTapped:(id)sender
{
    if (self.partnerIdTextField.text.length < 1) {
        [self showError:@"The Partner ID is required"];
        return;
    }
    
    if (self.urlTextField.text.length < 1) {
        [self showError:@"The Return URL Scheme is required"];
        return;
    }
  
    if (self.amountTextField.text.length < 1 && (self.durationTextField.text.length < 1 || self.hourlyRateTextField.text.length < 1)) {
      [self showError:@"Subtotal is require or combination of duration and hourly rate is required"];
      return;
    }
  
    NSNumberFormatter *numberFormater = [[NSNumberFormatter alloc] init];
    NSTimeInterval duration = [[numberFormater numberFromString:self.durationTextField.text] floatValue] * 3600;
    NSString *urlString =
        [NSString stringWithFormat:
         @"x-flint-mobile-a2a://payment?pid=%@&desc=%@&subtotal=%@&duration=%@&rate=%@&tax=%@&email=%@&url=%@&name=%@&phone=%@",
         self.partnerIdTextField.text, self.descTextField.text, self.amountTextField.text, @(duration), self.hourlyRateTextField.text, self.taxTextField.text, self.emailTextField.text, self.urlTextField.text, self.customerNameTextField.text, self.customerPhoneTextField.text];
  
    if (self.parametersTextField.text.length > 0) {
      urlString = [NSString stringWithFormat:@"%@&%@",urlString, self.parametersTextField.text];
    }
  
    NSURL *aURL = [NSURL URLWithString:
         [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  if ([[UIApplication sharedApplication] canOpenURL:aURL]) {
    [[UIApplication sharedApplication] openURL:aURL];
  } else {
    // send them to the app store
    aURL = [NSURL URLWithString:[@"https://itunes.apple.com/us/app/flint-mobile/id521597965" stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    [[UIApplication sharedApplication] openURL:aURL];
  }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    // done button was pressed - dismiss keyboard
    [textField resignFirstResponder];
    return YES;
}

@end
