//    The MIT License (MIT)
//
//    Copyright (c) 2015 Federico Saldarini
//    https://www.linkedin.com/in/federicosaldarini
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


#import <UIKit/UIKit.h>

#pragma mark - Drawer:
@protocol F3DEDrawerDelegate;
@protocol F3DEDrawerAppearanceDelegate;

typedef NS_ENUM(NSInteger, F3DEDrawerEdge) {
    F3DEDrawerEdgeLeft = UIRectEdgeLeft,
    F3DEDrawerEdgeRight = UIRectEdgeRight,
    F3DEDrawerEdgeTop = UIRectEdgeTop,
    F3DEDrawerEdgeBottom = UIRectEdgeBottom,
};

@interface F3DEDrawer : UIViewController
//  Open / closes the drawer:
@property (nonatomic, assign) BOOL open;
//  Drawer size as a fraction [0-1 range] of its container view (default = w:.8, h:1.):
@property (nonatomic, assign) CGSize scale;
//  Anchor point along the edge axis [0 - 1 range] (default = 0.5):
@property (nonatomic, assign) CGFloat anchor;
//  Edge the drawer is anchored to (default = F3DEDrawerEdgeLeft):
@property (nonatomic, assign) F3DEDrawerEdge edge;
//  View controller whose view will be displayed in the drawer:
@property (nonatomic, strong) UIViewController *content;
// View controller which will contain the drawer:
@property (nonatomic, weak) UIViewController *container;
//  Event delegate (optional):
@property (nonatomic, weak) NSObject<F3DEDrawerDelegate> *delegate;
//  Appearance delegate (required, default = F3DEDrawerAppearanceDelegate):
@property (nonatomic, strong) NSObject<F3DEDrawerAppearanceDelegate> *appearanceDelegate;
@end

#pragma  mark - Event Delegate:
@protocol F3DEDrawerDelegate <NSObject>
@optional
- (BOOL)drawerShouldBeginPanning:(F3DEDrawer *)drawer;
- (void)drawerDidBeginPanning:(F3DEDrawer *)drawer;
- (void)drawer:(F3DEDrawer*)drawer didPan:(CGFloat)openFraction;
- (void)drawerDidEndPanning:(F3DEDrawer*)drawer;
@end

#pragma  mark - Appearance Delegate:
@interface F3DEDrawerAppearanceState : NSObject;
@property (nonatomic, assign, readonly) CGPoint closedPosition;
@property (nonatomic, assign, readonly) CGPoint openPosition;
@property (nonatomic, assign, readonly) CGPoint targetPosition;
@property (nonatomic, assign, readonly) CGPoint velocity;
@property (nonatomic, assign, readonly) CGFloat openFraction;
@property (nonatomic, strong, readonly) UIView *overlay;
@end

@protocol F3DEDrawerAppearanceDelegate <NSObject>
/*  Called the first time a delegate is assigned to the drawer.
    This is useful for instance to set up appearance aspects that will stay constant throughout the delegate's lifecycle.*/
- (void)drawer:(F3DEDrawer*)drawer appearanceForInitialization:(F3DEDrawerAppearanceState*)state;

/*  Called when new content is assigned to the drawer or the drawer goes thru a geometry / mechanics update.*/
- (void)drawer:(F3DEDrawer*)drawer appearanceForUpdate:(F3DEDrawerAppearanceState*)state;

/*  Called for the beginning of a transition between open and closed, regardless of whether the transition was 
    initiated programmatically or thru gestures.*/
- (void)drawer:(F3DEDrawer*)drawer appearanceForTransitionBegin:(F3DEDrawerAppearanceState*)state;

/*  Called for the end of a transition between open and closed, regardless of whether the transition was initiated 
    programmatically or thru gestures.*/
- (void)drawer:(F3DEDrawer*)drawer appearanceForTransitionEnd:(F3DEDrawerAppearanceState*)state;

/*  Called after `-drawer:appearanceForTransitionBegin:` each time the user pans the drawer.*/
- (void)drawer:(F3DEDrawer*)drawer appearanceForTransitionProgress:(F3DEDrawerAppearanceState*)state;

/*  Called for the delegate to animate a transition from whatever position the drawer happens to be in towards a 
    final state (open or closed). This method will be called regardless of how the transition was initiated and is always 
    called after `-drawer:appearanceForTransitionBegin:` (and after `-drawer:appearanceForTransitionProgress:` 
    if transitioning thru a gesture) and before `-drawer:appearanceForTransitionEnd:`. The delegate must call the 
    completion block when done animating.*/
- (void)drawer:(F3DEDrawer*)drawer animationForTransition:(F3DEDrawerAppearanceState*)state completion:(void(^)(void))completion;
@end
