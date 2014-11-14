//
//  LineManager.m
//  Plane
//
//  Created by Peng, Yan on 6/13/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "LineManager.h"

#import "HelperFucntion.h"

@implementation LineManager
{
    //OpenGL parameter
    size_t sizeofVertices;
    size_t sizeofColors;
    
    GLKVector3* vertices;
    GLKVector4* colors;
    
    GLuint vertexBuffer;
    GLuint colorBuffer;
    
    GLKVector3* fromPosition;
    GLKVector3* toPosition;
    
    NSUInteger numOfVertices;
    NSUInteger numOfLines;
}

@synthesize shapeSwitchAnimation;
@synthesize effect;
@synthesize drawEnabled;

#pragma mark -

- (id) init{
    self = [super init];
    if (self) {
        drawEnabled = YES;
        numOfLines = (int)(sizeof(country) / sizeof(countryInfo) - 1);
        numOfVertices = NUM_OF_POINTS_IN_ONE_LINE * numOfLines;
        [self initData];
        shapeSwitchAnimation = NO;
    }
    return self;
}

- (void) initData{
    [self initBuffer];
    [self initVertexForSphere];
    [self initColors];
}


#pragma mark - internal help function

- (GLfloat)getLongtidueFor:(NSUInteger)i{
    return country[i].lon;
}

- (GLfloat)getLatitudeFor:(NSUInteger)i{
    return country[i].lat;
}

- (GLfloat)getMagnitudeWith:(NSUInteger)i{
    return [HelperFunction getMagnitudeWith:i];
}

- (void)computeVertexAtLine:(NSUInteger)i withBezierStartPoint:(GLKVector3)start endPoint:(GLKVector3)end controlPoint:(GLKVector3*)controls{
    for (NSUInteger j = 0; j < NUM_OF_POINTS_IN_ONE_LINE; j++) {
        GLfloat ratio = (GLfloat)j / BEZIER_CURVE_STEPS;
        NSUInteger index = i * NUM_OF_POINTS_IN_ONE_LINE + j;
        vertices[index] = [HelperFunction getPointAtBezierCurveWithRatio:ratio start:start end:end controls:controls];
    }
}

- (void) initVertexForSphere{
    GLKVector3 startPoint = [HelperFunction getPointAtSphereWithLongtitude:[self getLongtidueFor:0] Latitude:[self getLatitudeFor:0]];
    
    for (NSUInteger i = 0; i < numOfLines; i++) {
        GLKVector3 endPoint = [HelperFunction getPointAtSphereWithLongtitude:[self getLongtidueFor:i+1] Latitude:[self getLatitudeFor:i+1]];
        GLKVector3* controls = [HelperFunction getControlPointWithStart:startPoint End:endPoint shapeType:Sphere];
        [self computeVertexAtLine:i withBezierStartPoint:startPoint endPoint:endPoint controlPoint:controls];
        SAFE_FREE(controls);
	}
}

- (void) initVertexForPlane{
    GLKVector3 startPoint = [HelperFunction getPointAtPlaneWithLongtitude:[self getLongtidueFor:0] Latitude:[self getLatitudeFor:0]];
    for (NSUInteger i = 0; i < numOfLines; i++) {
        GLKVector3 endPoint = [HelperFunction getPointAtPlaneWithLongtitude:[self getLongtidueFor:i+1] Latitude:[self getLatitudeFor:i+1]];
        GLKVector3* controls = [HelperFunction getControlPointWithStart:startPoint End:endPoint shapeType:Plane];
        [self computeVertexAtLine:i withBezierStartPoint:startPoint endPoint:endPoint controlPoint:controls];
        SAFE_FREE(controls);
	}
}

- (void)initColors{
    GLKVector3 hsl = GLKVector3Make(0.0, 1.0, 0.5);
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < numOfLines; i++) {
        hsl.x = [self getMagnitudeWith:i];
        GLKVector3 rgb = [HelperFunction RGBfromHSL:hsl];
        
        for (NSUInteger j = 0; j < NUM_OF_POINTS_IN_ONE_LINE; j++) {
            colors[count++] = GLKVector4Make(rgb.r, rgb.g, rgb.b, 0.5);
        }
	}
}

#pragma mark - switch shape

- (void)switchShape:(ShapeType)type{
    memcpy(fromPosition, vertices, sizeofVertices);
    
    if (type == Plane) {
        [self initVertexForPlane];
    }else{
        [self initVertexForSphere];
    }
    
    memcpy(toPosition, vertices, sizeofVertices);
    
    shapeSwitchAnimation = YES;
}

- (void) updateVertexForSwitchShapeAnimation:(NSTimeInterval)ratio{
    NSUInteger count = 0;
    for(NSUInteger i = 0; i < numOfVertices; ++i){
        GLKVector3 currentPosition = GLKVector3Add(fromPosition[count], GLKVector3MultiplyScalar(GLKVector3Subtract(toPosition[count], fromPosition[count]), ratio));
        memcpy(&vertices[count], &currentPosition, sizeof(GLKVector3));
        ++count;
    }
    
    [self updateVertexBuffer];
}


#pragma mark - resources manage&drawObjective protocol

- (void)generateBuffer{
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_DYNAMIC_DRAW);
    
    glGenBuffers(1, &colorBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofColors, colors, GL_STATIC_DRAW);
}

- (void)releaseBuffer{
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &colorBuffer);
}

- (void) initBuffer{
    //init size and allocate buffer
    sizeofVertices = numOfVertices * sizeof(GLKVector3);
    sizeofColors = numOfVertices * sizeof(GLKVector4);
    
    vertices = (GLKVector3*)malloc(sizeofVertices);
    colors = (GLKVector4*)malloc(sizeofColors);
    
    fromPosition = (GLKVector3*)malloc(sizeofVertices);
    toPosition = (GLKVector3*)malloc(sizeofVertices);
}

- (void)updateVertexBuffer{
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_DYNAMIC_DRAW);
}

- (void)drawMainShapesWithModelViewMatrix:(GLKMatrix4)matrix{
    
    self.effect.transform.modelviewMatrix = matrix;
    [self.effect prepareToDraw];
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    //colors
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    for (NSUInteger i = 0; i < numOfLines; ++i) {
        glDrawArrays(GL_LINE_STRIP, i * (NUM_OF_POINTS_IN_ONE_LINE), NUM_OF_POINTS_IN_ONE_LINE);
    }
    
    glDisableVertexAttribArray(GLKVertexAttribColor);
}

- (void) dealloc {
    [self releaseBuffer];
    [self freeResources];
}

- (void)freeResources
{
    SAFE_FREE(vertices);
    SAFE_FREE(colors);
    SAFE_FREE(fromPosition);
    SAFE_FREE(toPosition);
}

@end
