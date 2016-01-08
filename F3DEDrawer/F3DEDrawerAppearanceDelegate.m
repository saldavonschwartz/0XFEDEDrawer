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

#import "F3DEDrawerAppearanceDelegate.h"

static CGFloat kSpringCompensation = 40.;
static CGFloat kOverlayOpacity = 0.5;
static CGFloat kDrawerShadowOpacity = 0.4;

@implementation F3DEDrawerAppearanceDelegate

- (void)drawer:(F3DEDrawer *)drawer appearanceForInitialization:(F3DEDrawerAppearanceState *)state {
    drawer.view.layer.shadowColor = [UIColor blackColor].CGColor;
    drawer.view.layer.shadowRadius = 6.;
    drawer.view.layer.shadowOffset = CGSizeZero;
    drawer.view.layer.shadowOpacity = drawer.open ? kDrawerShadowOpacity : 0.;
    state.overlay.backgroundColor = [UIColor blackColor];
    state.overlay.alpha = drawer.open ? kOverlayOpacity : 0.;
}

- (void)drawer:(F3DEDrawer *)drawer appearanceForUpdate:(F3DEDrawerAppearanceState *)state {
    drawer.view.backgroundColor = drawer.content ? drawer.content.view.backgroundColor : [UIColor whiteColor];
}

- (void)drawer:(F3DEDrawer *)drawer appearanceForTransitionBegin:(F3DEDrawerAppearanceState *)state {
    drawer.view.layer.shadowOpacity = kDrawerShadowOpacity;
}

- (void)drawer:(F3DEDrawer *)drawer appearanceForTransitionEnd:(F3DEDrawerAppearanceState *)state {
    drawer.view.layer.shadowOpacity = drawer.open ? kDrawerShadowOpacity : 0.;
}

- (void)drawer:(F3DEDrawer *)drawer appearanceForTransitionProgress:(F3DEDrawerAppearanceState *)state {
    state.overlay.alpha = kOverlayOpacity * state.openFraction;
    CGRect frame = drawer.view.frame;
    frame.origin = state.targetPosition;
    drawer.view.frame = frame;
}

- (void)drawer:(F3DEDrawer *)drawer animationForTransition:(F3DEDrawerAppearanceState *)state completion:(void (^)(void))completion {
    __block CGRect targetFrame = (CGRect){state.targetPosition, drawer.view.frame.size};
    BOOL willClose = CGPointEqualToPoint(state.targetPosition, state.closedPosition);
    
    if (willClose) {
        [UIView animateWithDuration:[self animationDurationForDrawer:drawer state:state] animations:^{
            drawer.view.frame = targetFrame;
            state.overlay.alpha  = 0.;
        } completion:^(BOOL finished) {
            completion();
        }];
    }
    else {
        [self adjustDrawer:drawer forTransitionToFrame:&targetFrame springOffset:kSpringCompensation];
        [UIView animateWithDuration:0.5
                              delay:0.f
             usingSpringWithDamping:.7f
              initialSpringVelocity:0.f
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             drawer.view.frame = targetFrame;
                             state.overlay.alpha  = kOverlayOpacity;
                         }
                         completion:^(BOOL finished) {
                             [self adjustDrawer:drawer forTransitionToFrame:&targetFrame springOffset:-kSpringCompensation];
                             completion();
                         }];
    }
}

- (CGFloat)animationDurationForDrawer:(F3DEDrawer*)drawer state:(F3DEDrawerAppearanceState*)state {
    CGFloat remainingTime;
    
    switch (drawer.edge) {
        case F3DEDrawerEdgeLeft:
        case F3DEDrawerEdgeRight: {
            remainingTime = fabs(drawer.view.frame.origin.x - state.targetPosition.x) / fabs(state.velocity.x);
            break;
        }
            
        case F3DEDrawerEdgeTop:
        case F3DEDrawerEdgeBottom: {
            remainingTime = fabs(drawer.view.frame.origin.y - state.targetPosition.y) / fabs(state.velocity.y);
            break;
        }
    }
    
    return  MAX(0.15, MIN(remainingTime, .3));
}

- (void)adjustDrawer:(F3DEDrawer*)drawer forTransitionToFrame:(CGRect*)targetFrame springOffset:(CGFloat)springOffset {
    CGRect drawerFrame = drawer.view.frame;
    CGRect contentFrame = drawer.content.view.frame;
    
    switch (drawer.edge) {
        case F3DEDrawerEdgeLeft: {
            drawerFrame.origin.x -= springOffset;
            drawerFrame.size.width += springOffset;
            contentFrame.origin.x += springOffset;
            targetFrame->origin.x -= springOffset;
            targetFrame->size.width += springOffset;
            
            break;
        }
            
        case F3DEDrawerEdgeRight: {
            drawerFrame.origin.x += springOffset;
            drawerFrame.size.width += springOffset;
            contentFrame.origin.x -= springOffset;
            targetFrame->origin.x += springOffset;
            targetFrame->size.width += springOffset;
            
            break;
        }
            
        case F3DEDrawerEdgeTop: {
            drawerFrame.origin.y -= springOffset;
            drawerFrame.size.height += springOffset;
            contentFrame.origin.y += springOffset;
            targetFrame->origin.y -= springOffset;
            targetFrame->size.height += springOffset;
            
            break;
        }
            
        case F3DEDrawerEdgeBottom: {
            drawerFrame.origin.y += springOffset;
            drawerFrame.size.height += springOffset;
            contentFrame.origin.y -= springOffset;
            targetFrame->origin.y += springOffset;
            targetFrame->size.height += springOffset;
            
            break;
        }
    }
    
    drawer.view.frame = drawerFrame;
    drawer.content.view.frame = contentFrame;
}

@end
