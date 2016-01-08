//
//  RootViewController.m
//  DrawerController
//
//  Created by Federico Saldarini on 12/2/15.
//  Copyright © 2015 0XFEDE. All rights reserved.
//

#import "RootViewController.h"
#import "ViewController.h"

static NSInteger kButtonTag = 99;

@interface RootViewController () <F3DEDrawerDelegate>
@property (nonatomic, assign) BOOL shouldHideStatusBar;
@property (nonatomic, strong) F3DEDrawer *drawer;
@property (nonatomic, strong) ViewController *drawerContent;
@end

@implementation RootViewController

- (void)viewWillAppear:(BOOL)animated {    
    [super viewWillAppear:animated];
    self.navigationController = (UINavigationController*)self.childViewControllers.firstObject;
    
    UIButton *toggle = (UIButton*)[self.navigationController.viewControllers.firstObject.view viewWithTag:kButtonTag];
    [toggle addTarget:self action:@selector(toggleDrawer) forControlEvents:UIControlEventTouchUpInside];
    
    self.drawer = [F3DEDrawer new];
    self.drawer.container = self;
    self.drawerContent = [[UIStoryboard storyboardWithName:@"MainScene" bundle:nil]
                          instantiateViewControllerWithIdentifier:@"DrawerContentController"];
    self.drawer.content = self.drawerContent;
    self.drawer.delegate = self;
}

- (void)toggleDrawer {
    self.drawer.open = !self.drawer.open;
}

- (BOOL)prefersStatusBarHidden {
    return self.shouldHideStatusBar;
}

//- (BOOL)drawerShouldBeginPanning:(F3DEDrawer *)drawer {
//    return NO;
//}

- (void)drawerDidBeginPanning:(F3DEDrawer *)drawer {
    if (!self.drawer.open) {
        self.shouldHideStatusBar = YES;
        [UIView animateWithDuration:.25 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
}

- (void)drawerDidEndPanning:(F3DEDrawer *)drawer {
    if (!self.drawer.open) {
        self.shouldHideStatusBar = NO;
        [UIView animateWithDuration:.25 animations:^{
            [self setNeedsStatusBarAppearanceUpdate];
        } completion:^(BOOL finished) {
            [self.drawerContent drawerDidClose];
        }];
    }
}

@end

