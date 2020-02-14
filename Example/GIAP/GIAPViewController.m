//
//  GIAPViewController.m
//  GIAP
//
//  Created by uendno on 02/07/2020.
//  Copyright (c) 2020 uendno. All rights reserved.
//

#import "GIAPViewController.h"
#import "GIAP/GIAP.h"

@interface GIAPViewController ()

@end

@implementation GIAPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [GIAP initWithToken:@"Token" serverUrl:[NSURL URLWithString:@"https://giap.got-it.ai"]];
    self.logoutButton.hidden = YES;
}

- (IBAction)didClickLogin:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Login"
                                                                                     message: @"User ID"
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
           textField.placeholder = @"User ID";
           textField.textColor = [UIColor blueColor];
           textField.clearButtonMode = UITextFieldViewModeWhileEditing;
           textField.borderStyle = UITextBorderStyleRoundedRect;
       }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * userIdTextField = textfields[0];
        self.userId = userIdTextField.text;
        [[GIAP sharedInstance] identify:self.userId];
        self.loginSignupStack.hidden = YES;
        self.logoutButton.hidden = NO;
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)didClickSignUp:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Signup"
                                                                                     message: @"User ID"
                                                                                 preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
           textField.placeholder = @"User ID";
           textField.textColor = [UIColor blueColor];
           textField.clearButtonMode = UITextFieldViewModeWhileEditing;
           textField.borderStyle = UITextBorderStyleRoundedRect;
       }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * userIdTextField = textfields[0];
        self.userId = userIdTextField.text;
        [[GIAP sharedInstance] alias:self.userId];
        self.loginSignupStack.hidden = YES;
        self.logoutButton.hidden = NO;
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)didClickLogout:(id)sender {
    [[GIAP sharedInstance] reset];
    
    self.loginSignupStack.hidden = NO;
    self.logoutButton.hidden = YES;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
