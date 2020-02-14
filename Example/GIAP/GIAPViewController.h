//
//  GIAPViewController.h
//  GIAP
//
//  Created by uendno on 02/07/2020.
//  Copyright (c) 2020 uendno. All rights reserved.
//

@import UIKit;

@interface GIAPViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIStackView *loginSignupStack;

@property (weak, nonatomic) IBOutlet UIButton *logoutButton;

@property (atomic, copy) NSString *userId;

@end
