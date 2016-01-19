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


#import <UIKit/UIKit.h>

#pragma mark - Drawer:
@protocol OXFEDEDrawerDelegate;
@protocol OXFEDEDrawerAppearanceDelegate;

typedef NS_ENUM(NSInteger, OXFEDEDrawerEdge) {
    OXFEDEDrawerEdgeLeft = UIRectEdgeLeft,
    OXFEDEDrawerEdgeRight = UIRectEdgeRight,
    OXFEDEDrawerEdgeTop = UIRectEdgeTop,
    OXFEDEDrawerEdgeBottom = UIRectEdgeBottom,
};


@interface OXFEDEDrawer : UIViewController
//  Open / closes the drawer:
@property (nonatomic, assign) BOOL open;
//  Drawer size as a fraction [0-1 range] of its container view (default = w:.8, h:1.):
@property (nonatomic, assign) CGSize scale;
//  Anchor point along the edge axis [0 - 1 range] (default = 0.5):
@property (nonatomic, assign) CGFloat anchor;
//  Edge the drawer is anchored to (default = OXFEDEDrawerEdgeLeft):
@property (nonatomic, assign) OXFEDEDrawerEdge edge;
//  View controller whose view will be displayed in the drawer:
@property (nonatomic, strong) UIViewController *content;
// View controller which will contain the drawer:
@property (nonatomic, weak) UIViewController *container;
//  Event delegate (optional):
@property (nonatomic, weak) NSObject<OXFEDEDrawerDelegate> *delegate;
//  Appearance delegate (required, default = OXFEDEDrawerAppearanceDelegate):
@property (nonatomic, strong) NSObject<OXFEDEDrawerAppearanceDelegate> *appearanceDelegate;
@end

#pragma  mark - Event Delegate:
@protocol OXFEDEDrawerDelegate <NSObject>
@optional
- (BOOL)drawerShouldBeginPanning:(OXFEDEDrawer *)drawer;
- (void)drawerDidBeginPanning:(OXFEDEDrawer *)drawer;
- (void)drawer:(OXFEDEDrawer*)drawer didPan:(CGFloat)openFraction;
- (void)drawerDidEndPanning:(OXFEDEDrawer*)drawer;
@end

#pragma  mark - Appearance Delegate:
@interface OXFEDEDrawerAppearanceState : NSObject;
@property (nonatomic, assign, readonly) CGPoint closedPosition;
@property (nonatomic, assign, readonly) CGPoint openPosition;
@property (nonatomic, assign, readonly) CGPoint targetPosition;
@property (nonatomic, assign, readonly) CGPoint velocity;
@property (nonatomic, assign, readonly) CGFloat openFraction;
@property (nonatomic, strong, readonly) UIView *overlay;
@end

@protocol OXFEDEDrawerAppearanceDelegate <NSObject>
/*  Called the first time a delegate is assigned to the drawer.
    This is useful for instance to set up appearance aspects that will stay constant throughout the delegate's lifecycle.*/
- (void)drawer:(OXFEDEDrawer*)drawer appearanceForInitialization:(OXFEDEDrawerAppearanceState*)state;

/*  Called when new content is assigned to the drawer or the drawer goes thru a geometry / mechanics update.*/
- (void)drawer:(OXFEDEDrawer*)drawer appearanceForUpdate:(OXFEDEDrawerAppearanceState*)state;

/*  Called for the beginning of a transition between open and closed, regardless of whether the transition was 
    initiated programmatically or thru gestures.*/
- (void)drawer:(OXFEDEDrawer*)drawer appearanceForTransitionBegin:(OXFEDEDrawerAppearanceState*)state;

/*  Called for the end of a transition between open and closed, regardless of whether the transition was initiated 
    programmatically or thru gestures.*/
- (void)drawer:(OXFEDEDrawer*)drawer appearanceForTransitionEnd:(OXFEDEDrawerAppearanceState*)state;

/*  Called after `-drawer:appearanceForTransitionBegin:` each time the user pans the drawer.*/
- (void)drawer:(OXFEDEDrawer*)drawer appearanceForTransitionProgress:(OXFEDEDrawerAppearanceState*)state;

/*  Called for the delegate to animate a transition from whatever position the drawer happens to be in towards a 
    final state (open or closed). This method will be called regardless of how the transition was initiated and is always 
    called after `-drawer:appearanceForTransitionBegin:` (and after `-drawer:appearanceForTransitionProgress:` 
    if transitioning thru a gesture) and before `-drawer:appearanceForTransitionEnd:`. The delegate must call the 
    completion block when done animating.*/
- (void)drawer:(OXFEDEDrawer*)drawer animationForTransition:(OXFEDEDrawerAppearanceState*)state completion:(void(^)(void))completion;
@end
