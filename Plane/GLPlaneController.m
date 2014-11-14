//
//  GLPlaneController.m
//  Plane
//
//  Created by Peng, Yan on 3/3/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "GLPlaneController.h"

#import "barManager.h"
#import "Constants.h"
#import "mainShapeManager.h"
#import "backgroundObject.h"
#import "LineManager.h"
#import "ParticlesManager.h"

@interface GLPlaneController ()

@property (strong, nonatomic) EAGLContext* context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation GLPlaneController
{
    GLfloat scaleFactor;
    GLfloat curScale;
    GLfloat rotateX;
    GLfloat rotateY;
    GLKMatrix4 rotateMatrix;
    GLKMatrix4 modelViewMatrixForMainShape;
    GLKMatrix4 modelViewMatrixForBackGround;
    

    NSMutableArray* drawObjectives;
    mainShapeManager* mainShape;
    backgroundObject* background;
    barManager*       barMetric;
    LineManager*      lineMetric;
    ParticlesManager* particlesMetric;
    
    BOOL isDragging;
    GLKVector2 velocity;
    NSDate* tapTime;
    NSDate* particleMoveTime;
}

@synthesize context = _context;
@synthesize effect = _effect;

#pragma mark - Init&Dealloc

- (void)initParameter{
    scaleFactor = 1.0;
    curScale = 1.0;
    rotateY = 0.0;
    rotateX = 0.0;
    rotateMatrix = GLKMatrix4Identity;
    
    isDragging = NO;
    tapTime =  nil;
    particleMoveTime = nil;
    velocity = GLKVector2Make(0.0, 0.0);
}

- (id)init
{
    self = [super init];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self initParameter];
    }
    return self;
}

- (void)addGesture {
    //add pin gesture as zoom
    UIPinchGestureRecognizer* zoomGesture = [[UIPinchGestureRecognizer alloc]
                                             initWithTarget:self
                                             action:@selector(zoomView:)];
    [self.view addGestureRecognizer:zoomGesture];
  
    //add pan gesture as rotate
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(rotateView:)];
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
}

- (void) initData{
    if (!drawObjectives) {
        drawObjectives = [[NSMutableArray alloc] init];
    }
    
    if (!background) {
        background = [[backgroundObject alloc] init];
        [drawObjectives addObject:background];
    }

    if (!mainShape) {
        mainShape = [[mainShapeManager alloc] initWithRowCount:MAX_ROW ColumnCount:MAX_COL];
        [drawObjectives addObject:mainShape];
    }
    
    if (!barMetric) {
        barMetric = [[barManager alloc] init];
        barMetric.drawEnabled = NO;
        [drawObjectives addObject:barMetric];
    }
    
    if (!lineMetric) {
        lineMetric = [[LineManager alloc] init];
        [drawObjectives addObject:lineMetric];
    }
    
    particleMoveTime = [NSDate date];
    if (!particlesMetric) {
        particlesMetric = [[ParticlesManager alloc] init];
        [drawObjectives addObject:particlesMetric];
    }
}

- (void)setupGL {
    self.effect = [[GLKBaseEffect alloc] init];
    
    [self enumerateObject:^void (id<drawObjective> object){
        object.effect = self.effect;
    }];
    
    [self setUpProjectionMatrix];
    [self setUpModelViewMatrix];
    
    [self enumerateObject:^void (id<drawObjective> object){
        [object generateBuffer];
    }];
    
    glEnable(GL_DEPTH_TEST);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    [EAGLContext setCurrentContext:self.context];
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    [self initData];
    [self setupGL];
    [self addGesture];
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
 
    [self enumerateObject:^void (id<drawObjective> object){
        [object releaseBuffer];
    }];

    self.effect = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

#pragma mark - internal function

- (void)enumerateObject:(void(^)(id<drawObjective>))callback{
    for (id<drawObjective> object in drawObjectives){
        callback(object);
    }
}

- (void)enumerateObjectForSwitchShape:(void(^)(id<switchShapeDelegate>))callback{
    for (NSInteger i = 0; i < [drawObjectives count]; ++i) {
        id currentShape = [drawObjectives objectAtIndex:i];
        if ([currentShape conformsToProtocol:@protocol(switchShapeDelegate)]) {
            callback(currentShape);
        }
    }
}

#pragma mark - HandleGesture

- (void)zoomView:(UIPinchGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        scaleFactor = curScale * recognizer.scale;
        if (scaleFactor < MinScaleFactor) {
            scaleFactor = MinScaleFactor;
        }
        if (scaleFactor  > MaxScaleFactor) {
            scaleFactor = MaxScaleFactor;
        }
        
        [self setUpModelViewMatrix];
    }else if (recognizer.state == UIGestureRecognizerStateEnded){
        curScale *= recognizer.scale;
        
        if (curScale < MinScaleFactor) {
            curScale = MinScaleFactor;
        }
        if (curScale  > MaxScaleFactor) {
            curScale = MaxScaleFactor;
        }
    }
}

- (void)computeRotateMatrix:(CGPoint) point
{
    GLfloat moveX = point.x - rotateX;
    GLfloat moveY = point.y - rotateY;
    GLKVector3 axis = GLKVector3Make(moveX, moveY, 0);
    //normal towards camera
    GLKVector3 normal = GLKVector3Make(0, 0, -1);
    GLKVector3 rotateAxis = GLKVector3Normalize(GLKVector3CrossProduct(normal, axis));
    GLfloat radius = RotateFactor * GLKVector2Length(GLKVector2Make(moveX, moveY));
    
    if (radius) {
        rotateMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(radius, rotateAxis.x, -rotateAxis.y, rotateAxis.z), rotateMatrix);
        if (particlesMetric) {
            particlesMetric.rotateMatrix = rotateMatrix;
        }
    }
    [self setUpModelViewMatrix];
}

- (void)rotateView:(UIPanGestureRecognizer *)recongnizer
{
    if ([self isAnimation]) {
        return;
    }
    
    CGPoint point = [recongnizer translationInView:self.view];
    [self computeRotateMatrix:point];
    rotateX = point.x;
    rotateY = point.y;
    if (recongnizer.state == UIGestureRecognizerStateBegan) {
        isDragging = YES;
    }else if (recongnizer.state == UIGestureRecognizerStateEnded) {
        rotateX = 0;
        rotateY = 0;
        isDragging = NO;
        CGPoint velocityPoint = [recongnizer velocityInView:self.view];
        velocity.x = velocityPoint.x * VelocityFactor;
        velocity.y = velocityPoint.y * VelocityFactor;
    }
}

#pragma mark - GLKViewDelegate

- (void)setUpProjectionMatrix{
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f), aspect, 1.0f, 20.0f);
    self.effect.transform.projectionMatrix = projectionMatrix;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect{
    NSLog(@"frame rate:%.2f", 1.0 / self.timeSinceLastDraw);
    [self setUpProjectionMatrix];
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    [self enumerateObject:^void (id<drawObjective> object){
        if (object.drawEnabled) {
            if ([object isKindOfClass:[backgroundObject class]]) {
                [object drawMainShapesWithModelViewMatrix:modelViewMatrixForBackGround];
            }else{
                [object drawMainShapesWithModelViewMatrix:modelViewMatrixForMainShape];
            }
        }
    }];
}

#pragma mark - GLKViewControllerDelegate

- (void)setUpModelViewMatrix{
    
    [self setupMainModeViewMatrix];
    [self setupBackgroundModelViewMatrix];
}

- (void)setupMainModeViewMatrix{
    //tanslate
    modelViewMatrixForMainShape = GLKMatrix4MakeTranslation(0.0, 0.0, -STARTING_Z);
    
    //rotate
    modelViewMatrixForMainShape = GLKMatrix4Multiply(modelViewMatrixForMainShape, rotateMatrix);
    
    //scale
    modelViewMatrixForMainShape = GLKMatrix4Scale(modelViewMatrixForMainShape, scaleFactor, scaleFactor, scaleFactor);
}

- (void)setupBackgroundModelViewMatrix{
    //tanslate
    modelViewMatrixForBackGround = GLKMatrix4MakeTranslation(0.0, 0.0, -STARTING_Z);
    
    //scale
    modelViewMatrixForBackGround = GLKMatrix4Scale(modelViewMatrixForBackGround, scaleFactor, scaleFactor, scaleFactor);
}

- (void)update{
    if ([self switchShapeAnimation]) {
        NSTimeInterval diff = -[tapTime timeIntervalSinceNow];
        float ratio = (diff * 1000.0f) / SWITCH_SHAPE_DURATION;
        if (ratio > 1) {
            [self enumerateObjectForSwitchShape:^(id<switchShapeDelegate>object){
                object.shapeSwitchAnimation = NO;
            }];
            ratio = 1;
            if (lineMetric.drawEnabled) {
                particlesMetric.drawEnabled = YES;
            }
        }
        
        [self enumerateObjectForSwitchShape:^(id<switchShapeDelegate>object){
            [object updateVertexForSwitchShapeAnimation:ratio];
        }];
    }
    
    if (particlesMetric.drawEnabled) {
        NSTimeInterval diff = -[particleMoveTime timeIntervalSinceNow];
        float ratio = (diff * 1000.0f) / PARTICLE_MOVE_DURATION;
        if (ratio > 1) {
            ratio = ratio - floorf(ratio);
        }
        [particlesMetric updateVertexWithOffset:ratio];
    }
    
    float velocitySize = GLKVector2Length(velocity);
    
    if (!isDragging && velocitySize > 0.0001) {
        CGPoint velocityPoint = CGPointMake(velocity.x, velocity.y);
        [self computeRotateMatrix:velocityPoint];
        
        velocity.x *= Sensitivity;
        velocity.y *= Sensitivity;
    }
}

#pragma mark - check state

- (BOOL)switchShapeAnimation{
    if (!mainShape) {
        return NO;
    }
    return mainShape.shapeSwitchAnimation;
}


- (BOOL)isAnimation{
    return [self switchShapeAnimation];
}

#pragma mark - UI

- (IBAction)switchShapes:(UISegmentedControl *)sender {
    if (mainShape) {
        tapTime = [NSDate date];
        
        [self enumerateObjectForSwitchShape:^(id<switchShapeDelegate>object){
            [object switchShape:sender.selectedSegmentIndex];
        }];
        particlesMetric.drawEnabled = NO;
    }
}

- (IBAction)switchMetrics:(UISegmentedControl *)sender {
    if (mainShape) {
        if (sender.selectedSegmentIndex == Path) {
            barMetric.drawEnabled = NO;
            lineMetric.drawEnabled = YES;
            particlesMetric.drawEnabled = YES;
        }else if (sender.selectedSegmentIndex == Bar){
            lineMetric.drawEnabled = NO;
            particlesMetric.drawEnabled = NO;
            barMetric.drawEnabled = YES;
        }
    }
}

@end
