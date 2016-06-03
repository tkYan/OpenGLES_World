//
//  barManager.m
//  Plane
//
//  Created by Peng, Yan on 6/13/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "barManager.h"

#import "HelperFucntion.h"
#import "WorldData.h"

@implementation barManager
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
    NSUInteger numOfBars;
}

@synthesize shapeSwitchAnimation;
@synthesize effect;
@synthesize drawEnabled;

#pragma mark -

- (id) init{
    self = [super init];
    if (self) {
        drawEnabled = YES;
        numOfBars = sizeof(_population) / sizeof(LatLonBar);
        numOfVertices = numOfBars * 2;
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

- (GLfloat)getMagnitudeWith:(NSUInteger)i{
    return _population[i].magnitude;
}

- (GLfloat)getLontitudeFor:(NSUInteger)i{
    return _population[i].lon;
}

- (GLfloat)getLatitudeFor:(NSUInteger)i{
    return _population[i].lat;
}

- (void) initVertexForSphere{
    for (NSUInteger i = 0; i < numOfBars; i++) {
        vertices[i * 2] = [HelperFunction getPointAtSphereWithLongtitude:[self getLontitudeFor:i] Latitude:[self getLatitudeFor:i]];
        vertices[i * 2 + 1] = GLKVector3MultiplyScalar(vertices[i * 2], 1 + [self getMagnitudeWith:i]);
	}
}

- (void) initVertexForPlane{
    for (NSUInteger i = 0; i < numOfBars; i++) {
        vertices[i * 2] = [HelperFunction getPointAtPlaneWithLongtitude:[self getLontitudeFor:i] Latitude:[self getLatitudeFor:i]];
        vertices[i * 2 + 1] = GLKVector3Add(vertices[i * 2], GLKVector3Make(0, 0, [self getMagnitudeWith:i]));
	}
}

- (void)initColors{
    GLKVector3 hsl = GLKVector3Make(0.0, 1.0, 0.5);
    for (NSUInteger i = 0; i < numOfBars; i++) {
        hsl.x = [self getMagnitudeWith:i];
        GLKVector3 rgb = [HelperFunction RGBfromHSL:hsl];
        
		colors[i * 2] = GLKVector4Make(rgb.r, rgb.g, rgb.b, 0.8);
		colors[i * 2 + 1] = GLKVector4Make(rgb.r, rgb.g, rgb.b, 0.8);
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
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    //colors
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glDrawArrays(GL_LINES, 0, (GLsizei)numOfVertices);
    
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
