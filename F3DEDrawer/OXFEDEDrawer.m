//    The MIT License (MIT)
//
//    Copyright (c) 2015 Federico Saldarini
//    https://www.linkedin.com/in/federicosaldarini
//    https://github.com/saldavonschwartz
//    http://0xfede.io
//
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

#import "OXFEDEDrawer.h"
#import "OXFEDEDrawerAppearanceDelegate.h"

#pragma mark - OXFEDEDrawerAppearanceState - Private:
@interface OXFEDEDrawerAppearanceState ()
@property (nonatomic, assign, readwrite) CGPoint closedPosition;
@property (nonatomic, assign, readwrite) CGPoint openPosition;
@property (nonatomic, assign, readwrite) CGPoint targetPosition;
@property (nonatomic, assign, readwrite) CGPoint velocity;
@property (nonatomic, assign, readwrite) CGFloat openFraction;
@property (nonatomic, strong, readwrite) UIView *overlay;
@end

@implementation OXFEDEDrawerAppearanceState
@end

#pragma mark - KVOView:
@interface KVOView : UIView
@end

@implementation KVOView
- (void)willMoveToSuperview:(UIView *)newSuperview {
    [super willMoveToSuperview:newSuperview];
    [self willChangeValueForKey:@"superview"];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    [self didChangeValueForKey:@"superview"];
}
@end

#pragma mark - OXFEDEDrawer - Private:
@interface OXFEDEDrawer ()
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgeRecognizer;
@property (nonatomic, assign) BOOL needsUpdate;
@property (nonatomic, assign) BOOL stateChangeTriggeredFromGesture;
@property (nonatomic, strong) OXFEDEDrawerAppearanceState *state;
@property (nonatomic, copy) CGPoint(^clamp)(CGPoint);
@property (nonatomic, copy) BOOL(^isOpen)(void);
@property (nonatomic, copy) CGFloat(^openFraction)(void);
@property (nonatomic, assign) CGPoint referenceVelocity;
@property (nonatomic, assign) BOOL transitioning;
@end

@implementation OXFEDEDrawer

#pragma mark - Class:
+ (NSSet *)keyPathsForValuesAffectingNeedsUpdate {
    NSArray *geometryKeys = @[@"edge", @"anchor", @"scale", @"view.superview", @"view.superview.frame"];
    return [NSSet setWithArray:geometryKeys];
}

+ (BOOL)automaticallyNotifiesObserversOfOpen {
    return NO;
}

#pragma mark - Lifecycle:
- (instancetype)init {
    self = [super init];
    if (self) {
        self.state  = [OXFEDEDrawerAppearanceState new];
        [self initGeometry];
        [self initMechanics];
        self.appearanceDelegate = [OXFEDEDrawerAppearanceDelegate new];
        [self addObserver:self forKeyPath:@"needsUpdate" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return self;
}

- (void)loadView {
    self.view = [KVOView new];
}

- (void)dealloc {
    [self removeObserver:self forKeyPath:@"needsUpdate"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(nullable void *)context {
    if ([keyPath isEqualToString:@"needsUpdate"]) {
        NSAssert(!self.transitioning,
                 @"Attempted to modify geometry / mechanics "
                 @"of OXFEDEDrawer at the same time as appearance delegate.");
        _needsUpdate = NO;
        [self updateGeometry];
        [self updateMechanics];
        [self.appearanceDelegate drawer:self appearanceForUpdate:self.state];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    if (self.open) {
        return;
    }
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.view.hidden = YES;
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.view.hidden = NO;
    }];
}

- (void)setContainer:(UIViewController *)container {
    if (_container != container) {
        if (_container) {
            [self willMoveToParentViewController:nil];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
        
        _container = container;
        
        if (_container) {
            [_container addChildViewController:self];
            [_container.view addSubview:self.view];
            [self didMoveToParentViewController:_container];
        }
    }
}

- (void)setContent:(UIViewController *)content {
    if (_content != content) {
        if (_content) {
            [_content willMoveToParentViewController:nil];
            [_content.view removeFromSuperview];
            [_content removeFromParentViewController];
        }
        
        _content = content;
        
        if (_content) {
            [self addChildViewController:_content];
            [self.view addSubview:_content.view];
            _content.view.frame = self.view.bounds;
            [_content didMoveToParentViewController:self];
            [self.appearanceDelegate drawer:self appearanceForUpdate:self.state];
        }
    }
}

#pragma mark - Appearance:
- (void)setAppearanceDelegate:(NSObject<OXFEDEDrawerAppearanceDelegate> *)appearanceDelegate {
    NSAssert(appearanceDelegate,
             @"OXFEDEDrawer requires an appearance delegate "
             @"(i.e. OXFEDEDrawerAppearanceDelegate).");
    if (_appearanceDelegate != appearanceDelegate) {
        _appearanceDelegate  = appearanceDelegate;
    }
    
    [_appearanceDelegate drawer:self appearanceForInitialization:self.state];
}

#pragma mark - Geometry:
- (void)initGeometry {
    self.scale = CGSizeMake(.8, 1.);
    self.view.autoresizesSubviews = NO;
}

- (void)updateGeometry {
    if (!self.view.superview) {
        return;
    }
    
    CGRect containerBounds = self.view.superview.bounds;
    CGSize containerSize = containerBounds.size;
    
    CGSize contentSize = containerSize;
    contentSize.width *= self.scale.width;
    contentSize.height *= self.scale.height;
    
    self.view.frame = (CGRect){CGPointZero, contentSize};
    _content.view.frame = self.view.bounds;
}

#pragma mark - Mechanics:
- (void)initMechanics {
    self.edge = OXFEDEDrawerEdgeLeft;
    self.anchor = 0.5;
    self.state.overlay = [UIView new];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOverlay)];
    [self.state.overlay addGestureRecognizer:tap];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    [self.view addGestureRecognizer:pan];
    
    self.edgeRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
}

- (void)updateMechanics {
    if (!self.view.superview) {
        [self.state.overlay removeFromSuperview];
        [self.edgeRecognizer.view removeGestureRecognizer:self.edgeRecognizer];
    }
    else {
        [self.view.superview addGestureRecognizer:self.edgeRecognizer];
        self.edgeRecognizer.edges = (UIRectEdge)self.edge;
        
        __weak OXFEDEDrawer *_self = self;
        CGSize containerSize = self.view.superview.bounds.size;
        CGSize contentSize = self.view.bounds.size;
        CGPoint anchorPoint;
        anchorPoint.x = (containerSize.width - contentSize.width) * self.anchor;
        anchorPoint.y = (containerSize.height - contentSize.height) * self.anchor;
        
        switch (self.edge) {
            case OXFEDEDrawerEdgeLeft: {
                self.state.openPosition = CGPointMake(0., anchorPoint.y);
                self.state.closedPosition = (CGPoint){-contentSize.width, anchorPoint.y};
                self.referenceVelocity = CGPointMake(1., 0.);
                
                self.clamp = ^CGPoint(CGPoint target) {
                    return (CGPoint){MAX(_self.state.closedPosition.x, MIN(target.x, _self.state.openPosition.x)), anchorPoint.y};
                };
                
                self.openFraction = ^() {
                    return ABS(_self.view.frame.origin.x - self.state.closedPosition.x) / contentSize.width;
                };
                
                self.isOpen = ^BOOL() {
                    return _self.state.velocity.x  > 0.;
                };
                
                break;
            }
                
            case OXFEDEDrawerEdgeRight: {
                self.state.openPosition = (CGPoint){containerSize.width - contentSize.width, anchorPoint.y};
                self.state.closedPosition = (CGPoint){containerSize.width, anchorPoint.y};
                self.referenceVelocity = CGPointMake(-1., 0.);
                
                self.clamp = ^CGPoint(CGPoint target) {
                    return (CGPoint){MAX(_self.state.openPosition.x, MIN(target.x, _self.state.closedPosition.x)), anchorPoint.y};
                };
                
                self.openFraction = ^() {
                    return ABS(_self.view.frame.origin.x - self.state.closedPosition.x) / contentSize.width;
                };
                
                self.isOpen = ^BOOL() {
                    return _self.state.velocity.x < 0.;
                };
                
                break;
            }
                
            case OXFEDEDrawerEdgeTop: {
                self.state.openPosition = CGPointMake(anchorPoint.x, 0.);
                self.state.closedPosition = (CGPoint){anchorPoint.x, -contentSize.height};
                self.referenceVelocity = CGPointMake(0., 1.);
                
                self.clamp = ^CGPoint(CGPoint target) {
                    return (CGPoint){anchorPoint.x, MAX(_self.state.closedPosition.y, MIN(target.y, _self.state.openPosition.y))};
                };
                
                self.openFraction = ^() {
                    return ABS(_self.view.frame.origin.y - self.state.closedPosition.y) / contentSize.height;
                };
                
                self.isOpen = ^BOOL() {
                    return _self.state.velocity.y > 0.;
                };
                
                break;
            }
                
            case OXFEDEDrawerEdgeBottom: {
                self.state.openPosition = (CGPoint){anchorPoint.x, containerSize.height - contentSize.height};
                self.state.closedPosition = (CGPoint){anchorPoint.x, containerSize.height};
                self.referenceVelocity = CGPointMake(0., -1.);
                
                self.clamp = ^CGPoint(CGPoint target) {
                    return (CGPoint){anchorPoint.x, MAX(_self.state.openPosition.y, MIN(target.y, _self.state.closedPosition.y))};
                };
                
                self.openFraction = ^() {
                    return ABS(_self.view.frame.origin.y - self.state.closedPosition.y) / contentSize.height;
                };
                
                self.isOpen = ^BOOL() {
                    return _self.state.velocity.y < 0.;
                };
                
                break;
            }
        }
        
        self.state.overlay.frame = self.view.superview.bounds;
        [self.view.superview insertSubview:self.state.overlay belowSubview:self.view];
        
        CGPoint origin = self.open ? self.state.openPosition : self.state.closedPosition;
        self.view.frame = (CGRect){origin, self.view.bounds.size};
    }
}

- (void)setOpen:(BOOL)open {
    if (!self.stateChangeTriggeredFromGesture) {
        NSAssert(!self.transitioning,
                 @"Attempted to modify geometry / mechanics of "
                 @"OXFEDEDrawer at the same time as appearance delegate.");
        if (self.open == open || ![self beginTransition]) {
            return;
        }
    }
    else {
        self.stateChangeTriggeredFromGesture = NO;
    }
    
    self.state.targetPosition = open ? self.state.openPosition : self.state.closedPosition;
    [self.appearanceDelegate drawer:self animationForTransition:self.state completion:^{
        [self willChangeValueForKey:@"open"];
        _open = open;
        [self didChangeValueForKey:@"open"];
        [self commitTransition];
    }];
}

- (void)didPan:(UIPanGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            if (![self beginTransition]) {
                recognizer.enabled = NO;
            }

            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            CGPoint velocity = [recognizer velocityInView:recognizer.view];
            velocity.x = velocity.x ?: self.state.velocity.x;
            velocity.y = velocity.y ?: self.state.velocity.y;
            self.state.velocity = velocity;
            
            CGPoint translation = [recognizer translationInView:recognizer.view];
            [recognizer setTranslation:CGPointZero inView:recognizer.view];
            
            CGPoint targetPosition = self.view.frame.origin;
            targetPosition.x += translation.x;
            targetPosition.y += translation.y;
            
            self.state.openFraction = self.openFraction();
            self.state.targetPosition = self.clamp(targetPosition);
            [self.appearanceDelegate drawer:self appearanceForTransitionProgress:self.state];
            
            if ([self.delegate respondsToSelector:@selector(drawer:didPan:)]) {
                [self.delegate drawer:self didPan:self.state.openFraction];
            }
            
            break;
        }
            
        case UIGestureRecognizerStateCancelled: {
            recognizer.enabled = YES;
            
            break;
        }
            
        case UIGestureRecognizerStateEnded: {
            self.stateChangeTriggeredFromGesture = YES;
            self.open = self.isOpen();
            
            break;
        }
            
        default:
            break;
    }
}

- (void)didTapOverlay {
    self.open = NO;
}

- (BOOL)beginTransition {
    if ([self.delegate respondsToSelector:@selector(drawerShouldBeginPanning:)]) {
        if (![self.delegate drawerShouldBeginPanning:self]) {
            return NO;
        }
    }
    
    self.transitioning = YES;
    
    if (!self.open) {
        [self.content viewWillAppear:NO];
    }
    
    self.state.openFraction = self.open ? 1. : 0.;
    self.state.targetPosition = self.view.frame.origin;
    self.state.velocity = CGPointMake(!_open ? self.referenceVelocity.x : -self.referenceVelocity.x,
                                        !_open ? self.referenceVelocity.y : -self.referenceVelocity.y);
    [self.appearanceDelegate drawer:self appearanceForTransitionBegin:self.state];
    
    if ([self.delegate respondsToSelector:@selector(drawerDidBeginPanning:)]) {
        [self.delegate drawerDidBeginPanning:self];
    }
    
    return YES;
}

- (void)commitTransition {
    self.state.openFraction = self.open ? 1. : 0.;
    self.state.targetPosition = self.view.frame.origin;
    self.state.velocity = CGPointZero;
    [self.appearanceDelegate drawer:self appearanceForTransitionEnd:self.state];
    
    self.transitioning = NO;
    
    if (!self.open) {
        [self.content viewDidDisappear:NO];
    }
    
    if ([self.delegate respondsToSelector:@selector(drawerDidEndPanning:)]) {
        [self.delegate drawerDidEndPanning:self];
    }
}

@end
