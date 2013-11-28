//
//  PanScaleRotateScrollViewController.m
//  PlanetsTest
//
//  Created by Liam on 21/11/2013.
//  Copyright (c) 2013 Liam Conroy (Freelance). All rights reserved.
//

#import "PanScaleRotateScrollViewController.h"

#define SCALE_MIN 0.2f
#define SCALE_MAX 2.0f

@interface PanScaleRotateScrollViewController ()

@property UIView * viewToManipulate;
    
@property CGFloat currentScale;
@property CGFloat lastScale;
@property CGFloat currentRotation;
@property CGFloat lastRotation;

@property (nonatomic, strong) UILabel * zoomLabel;
@property (nonatomic, strong) UILabel * rotateLabel;
@property (nonatomic, strong) UILabel * positionLabel;

@end

@implementation PanScaleRotateScrollViewController

#pragma mark -
#pragma mark Setup and Teardown

- (void)setupControls
{
    UIRotationGestureRecognizer *rotationGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotateView:)];
    rotationGesture.delaysTouchesEnded = FALSE;
    rotationGesture.cancelsTouchesInView = FALSE;
    [self.view addGestureRecognizer:rotationGesture];
    [rotationGesture setDelegate:self];
    
    UIPinchGestureRecognizer *pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleView:)];
    pinchGesture.delaysTouchesEnded = FALSE;
    pinchGesture.cancelsTouchesInView = FALSE;
    [pinchGesture setDelegate:self];
    [self.view addGestureRecognizer:pinchGesture];
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panView:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:2];
    panRecognizer.delaysTouchesEnded = FALSE;
    panRecognizer.cancelsTouchesInView = FALSE;
    [panRecognizer setDelegate:self];
    [self.view addGestureRecognizer:panRecognizer];
}

- (void)setupTestView
{
    _viewToManipulate = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/2, self.view.frame.size.height/2)];
    _viewToManipulate.center = self.view.center;
    [_viewToManipulate setBackgroundColor:[UIColor darkGrayColor]];
    [self.view addSubview:_viewToManipulate];
}
    
- (void)viewDidLoad
{
    [self setupTestView];
    [self setupControls];
}

#pragma mark -
#pragma mark Maths Helper Functions

static inline CGFloat CGAffineTransformGetScaleX(CGAffineTransform transform)
{
    return sqrtf( (transform.a * transform.a) + (transform.c * transform.c) );
}
    
- (CGPoint)pointBetweenPoint:(CGPoint)a andPoint:(CGPoint)b
{
    return CGPointMake((a.x+b.x)/2, (a.y+b.y)/2);
}

#pragma mark -
#pragma mark Touch Control Related
    
- (void)rotateView:(UIRotationGestureRecognizer *)gestureRecognizer
{
    if(gestureRecognizer.numberOfTouches == 2)
    {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            _viewToManipulate.transform = CGAffineTransformRotate([_viewToManipulate transform], [gestureRecognizer rotation]);
            [gestureRecognizer setRotation:0];
        }
    }
}

-(void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view
{
    CGPoint newPoint = CGPointMake(view.bounds.size.width * anchorPoint.x, view.bounds.size.height * anchorPoint.y);
    CGPoint oldPoint = CGPointMake(view.bounds.size.width * view.layer.anchorPoint.x, view.bounds.size.height * view.layer.anchorPoint.y);
    
    newPoint = CGPointApplyAffineTransform(newPoint, view.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, view.transform);
    
    CGPoint position = view.layer.position;
    
    position.x -= oldPoint.x;
    position.x += newPoint.x;
    
    position.y -= oldPoint.y;
    position.y += newPoint.y;
    
    view.layer.position = position;
    view.layer.anchorPoint = anchorPoint;
}
    
- (void)setAnchorPointForGestureRecogniser:(UIGestureRecognizer *)gesture forView:(UIView *)view
{
    CGPoint touch1 = [gesture locationOfTouch:0 inView:self.view];
    CGPoint touch2 = [gesture locationOfTouch:1 inView:self.view];
    
    CGPoint center = [self pointBetweenPoint:touch1 andPoint:touch2];
    CGPoint centerInSpaceView = [_viewToManipulate convertPoint:center fromView:self.view];
    CGPoint anchor = CGPointMake(centerInSpaceView.x/_viewToManipulate.frame.size.width,
                                 centerInSpaceView.y/_viewToManipulate.frame.size.height);
    
    [self setAnchorPoint:anchor forView:view];
}

- (void)limitScale
{
    CGFloat currentScale = [[_viewToManipulate valueForKeyPath:@"layer.transform.scale.x"] floatValue];
    
    if (currentScale > SCALE_MAX)
    {
        [_viewToManipulate setValue:[NSNumber numberWithFloat:SCALE_MAX] forKeyPath:@"layer.transform.scale.x"];
        [_viewToManipulate setValue:[NSNumber numberWithFloat:SCALE_MAX] forKeyPath:@"layer.transform.scale.y"];
    }
    else if (currentScale < SCALE_MIN)
    {
        [_viewToManipulate setValue:[NSNumber numberWithFloat:SCALE_MIN] forKeyPath:@"layer.transform.scale.x"];
        [_viewToManipulate setValue:[NSNumber numberWithFloat:SCALE_MIN] forKeyPath:@"layer.transform.scale.y"];
    }
}

- (void)scaleView:(UIPinchGestureRecognizer *)gestureRecognizer
{
    if(gestureRecognizer.numberOfTouches == 2)
    {
        if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
        {
            _viewToManipulate.transform = CGAffineTransformScale([_viewToManipulate transform], [gestureRecognizer scale], [gestureRecognizer scale]);
            [gestureRecognizer setScale:1];
        }
    }
    
    [self limitScale];
}

-(void)panView:(UIPanGestureRecognizer *)gestureRecognizer;
{
    if ([gestureRecognizer state] == UIGestureRecognizerStateBegan || [gestureRecognizer state] == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [gestureRecognizer translationInView:[_viewToManipulate superview]];
        [_viewToManipulate setCenter:CGPointMake([_viewToManipulate center].x + translation.x, [_viewToManipulate center].y+translation.y)];
        [gestureRecognizer setTranslation:CGPointZero inView:[_viewToManipulate superview]];
    }
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (gestureRecognizer.view != otherGestureRecognizer.view)
        return NO;
    
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])
        return NO;
    
    return YES;
}

@end
