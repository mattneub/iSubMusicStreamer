//
//  CustomUITabBarController.m
//  iSub
//
//  Created by Benjamin Baron on 10/18/13.
//  Copyright (c) 2013 Ben Baron. All rights reserved.
//

#import "CustomUITabBarController.h"
#import "SavedSettings.h"
#import "ViewObjectsSingleton.h"
#import "Swift.h"

@implementation CustomUITabBarController

+ (void)customizeMoreTabTableView:(UITabBarController *)tabBarController {
    // Customize more tab
    UINavigationController* nav = tabBarController.moreNavigationController;
    CustomUINavigationControllerHelper* helper = [[CustomUINavigationControllerHelper alloc] init];
    UIViewController *moreController = nav.topViewController;
    // ...only for the "secret" view controller that is _first_ in the More view
    if ([NSStringFromClass([moreController class]) isEqualToString: @"UIMoreListController"]) {
        [helper fixNavBar: nav];
        if ([moreController.view isKindOfClass:UITableView.class]) {
            UITableView *moreTableView = (UITableView *)moreController.view;
            moreTableView.backgroundColor = [UIColor colorNamed:@"isubBackgroundColor"];
            moreTableView.rowHeight = Defines.rowHeight;
            moreTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        }
    }
}

- (BOOL)shouldAutorotate {
    if (settingsS.isRotationLockEnabled && UIDevice.currentDevice.orientation != UIDeviceOrientationPortrait) {
        return NO;
    }
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [viewObjectsS orderMainTabBarController];

    CustomUITabBarControllerHelper* helper = [[CustomUITabBarControllerHelper alloc] init];
    [helper fixTabBar: self];

    [self.class customizeMoreTabTableView:self];
}

@end
