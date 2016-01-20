//
//  ViewController.m
//  DrawerController
//
//  Created by Federico Saldarini on 12/2/15.
//  Copyright © 2015 0XFEDE. All rights reserved.
//

#import "ViewController.h"
#import "OXFEDEDrawer.h"
#import "RootViewController.h"

typedef NS_ENUM(NSInteger, CellType) {
    CellTypeContainer,
    CellTypeEdge,
    CellTypeWidthFactor,
    CellTypePush
};

static NSInteger kCellTitleTag = 99;

@interface ViewController ()
@property (nonatomic, weak) OXFEDEDrawer *drawer;
@property (nonatomic, weak) RootViewController *rootController;
@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, strong) void(^action)();
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didMoveToParentViewController:(UIViewController *)parent {
    if ([parent isKindOfClass:OXFEDEDrawer.class]) {
        self.drawer = (OXFEDEDrawer*)parent;
        self.rootController = (RootViewController*)[[UIApplication sharedApplication].delegate window].rootViewController;
        self.navigationController = self.rootController.childViewControllers.firstObject;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        [self.view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
    }
}

- (void)dealloc {
    [self.view removeObserver:self forKeyPath:@"hidden"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"hidden"]) {
        if (!self.view.hidden) {
            [self.tableView reloadData];
        }
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.navigationController.viewControllers.count == 1) {
        return 4;
    }
    else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =  [super tableView:tableView cellForRowAtIndexPath:indexPath];
    UILabel *title = (UILabel*)[cell.contentView viewWithTag:kCellTitleTag];
    CellType cellType = [tableView numberOfRowsInSection:0] == 4 ? indexPath.row : indexPath.row + 1;
    switch (cellType) {
        case CellTypeContainer: {
            if (self.drawer.container == self.rootController) {
                title.text = @"Contain drawer in: 'welcome' controller";
            }
            else {
                title.text = @"Contain drawer in: root controller";
            }
            
            break;
        }
            
        case CellTypeEdge: {
            if (self.drawer.edge == OXFEDEDrawerEdgeLeft) {
                title.text = @"Switch to edge: right side";
            }
            else {
                title.text = @"Switch to edge: left side";
            }
            
            break;
        }
            
        case CellTypeWidthFactor: {
            if (self.drawer.scale.width == 0.55) {
                title.text = @"Make width: 0.8";
            }
            else {
                title.text = @"Make width: 0.55";
            }
            
            break;
        }
            
        case CellTypePush: {
            title.text = @"Push another controller :)";
            break;
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    __weak ViewController *_self = self;
    CellType cellType = [tableView numberOfRowsInSection:0] == 4 ? indexPath.row : indexPath.row + 1;
    switch (cellType) {
        case CellTypeContainer: {
            self.action = ^{
                if (_self.drawer.container == _self.rootController) {
                    _self.drawer.container = _self.navigationController.topViewController;
                }
                else {
                    _self.drawer.container = _self.rootController;
                }
                
                _self.drawer.open = YES;
            };
            self.drawer.open = NO;
            
            break;
        }
            
        case CellTypeEdge: {
            self.action = ^{
                if (_self.drawer.edge == OXFEDEDrawerEdgeLeft) {
                    _self.drawer.edge = OXFEDEDrawerEdgeRight;
                }
                else {
                    _self.drawer.edge = OXFEDEDrawerEdgeLeft;
                }
                _self.drawer.open = YES;
            };
            self.drawer.open = NO;
            
            break;
        }
            
        case CellTypeWidthFactor: {
            self.action = ^{
                CGSize size = _self.drawer.scale;
                if (size.width == 0.8) {
                    size.width = 0.55;
                }
                else {
                    size.width = 0.8;
                }
                
                _self.drawer.scale = size;
                _self.drawer.open = YES;
            };
            self.drawer.open = NO;
            
            break;
        }
            
        case CellTypePush: {
            if (self.drawer.container == self.rootController) {
                [self.navigationController.topViewController performSegueWithIdentifier:@"PushNext" sender:self];
                [self.tableView reloadData];
            }
            else {
                self.action = ^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [_self.navigationController.topViewController performSegueWithIdentifier:@"PushNext" sender:_self];
                    });
                };
                self.drawer.open = NO;
            }
            
            break;
        }
    }
}

- (void)drawerDidClose {
    if (self.action) {
        self.action();
        self.action = nil;
    }
}

@end
