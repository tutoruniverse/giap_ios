//
//  GIAPViewController.m
//  GIAP
//
//  Created by uendno on 02/07/2020.
//  Copyright (c) 2020 uendno. All rights reserved.
//

#import "GIAPViewController.h"
#import "GIAP/GIAP.h"

@implementation GIAPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [GIAP initWithToken:@"thang" serverUrl:[NSURL URLWithString:@"http://localhost:8080"]];
    [GIAP sharedInstance].delegate = self;
    
    [self changeState:NO];
    
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
        
        [self changeState:YES];
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
        
        [self changeState:YES];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)didClickLogout:(id)sender {
    [[GIAP sharedInstance] reset];
    
    [self changeState:NO];
}

- (IBAction)didClickVisit:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Visit"
                                                                              message: @"Properties"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Economy group";
        textField.textColor = [UIColor blueColor];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * userIdTextField = textfields[0];
        NSNumber *economyGroup = [[[NSNumberFormatter alloc] init] numberFromString:userIdTextField.text];
        
        [[GIAP sharedInstance] track:@"Visit" properties:@{
            @"economy_group": economyGroup
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)didClickAsk:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Ask"
                                                                              message: @"Properties"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Text";
        textField.textColor = [UIColor blueColor];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * userIdTextField = textfields[0];
        NSString *text = userIdTextField.text;
        
        [[GIAP sharedInstance] track:@"Ask" properties:@{
            @"problem_text": text
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)didClickSetFullName:(id)sender {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: @"Full name"
                                                                              message: nil
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Text";
        textField.textColor = [UIColor blueColor];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleRoundedRect;
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField * userIdTextField = textfields[0];
        NSString *name = userIdTextField.text;
        
        [[GIAP sharedInstance] setProfileProperties:@{
            @"full_name": name
        }];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)changeState:(BOOL)loggedIn
{
    if (loggedIn) {
        self.loggedInStack.hidden = NO;
        self.notLoggedInStack.hidden = YES;
    } else {
        self.loggedInStack.hidden = YES;
        self.notLoggedInStack.hidden = NO;
    }
}

- (void)giap:(GIAP *)giap didResetWithDistinctId:(NSString *)distinctId
{
    
}

- (void)giap:(GIAP *)giap didEmitEvents:(NSArray *)events withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didEmitEvent:\n%@", events);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didUpdateProfile:(NSString *)distinctId withProperties:(NSDictionary *)properties withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didUpdateProfile:\n%@ withProperties:%@", distinctId, properties);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didCreateAliasForUserId:(NSString *)userId withDistinctId:(NSString *)distinctId withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didCreateAliasForUserId:\n%@ withDistinctId:%@", userId, distinctId);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

- (void)giap:(GIAP *)giap didIdentifyUserId:(NSString *)userId withCurrentDistinctId:(NSString *)distinctId withResponse:(NSDictionary *)response andError:(NSError *)error
{
    NSLog(@"GIAP didIdentifyUserId:\n%@ withCurrentDistinctId:%@", userId, distinctId);
    if (error) {
        NSLog(@"%@", error);
    } else {
        NSLog(@"%@", response);
    }
}

@end
