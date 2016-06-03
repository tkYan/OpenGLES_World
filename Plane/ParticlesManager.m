//
//  ParticlesManager.m
//  Plane
//
//  Created by Peng, Yan on 6/14/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "ParticlesManager.h"

#import "HelperFucntion.h"

@implementation ParticlesManager
{
    //OpenGL parameter
    size_t sizeofVertices;
    size_t sizeofColors;
    size_t sizeofTextureCoordinate;
    size_t sizeofIndice;
    
    GLKVector3* vertices;
    GLKVector4* colors;
    GLKVector2* textureCoordinates;
    GLushort* indice;
    
    GLuint vertexBuffer;
    GLuint colorBuffer;
    GLuint textureBuffer;
    GLuint indexBuffer;
    
    GLKTextureInfo* textureInfo;
    
    GLKVector3* fromPosition;
    GLKVector3* toPosition;
    
    NSUInteger numOfVertices;
    NSUInteger numOfLines;
    NSUInteger numOfParticles;
    
    ShapeType shapeType;
}

@synthesize effect;
@synthesize drawEnabled;
@synthesize shapeSwitchAnimation;

#pragma mark -

- (id) init{
    self = [super init];
    if (self) {
        drawEnabled = YES;
        numOfLines = (int)(sizeof(country) / sizeof(countryInfo) - 1);
        numOfParticles = NUM_OF_PARTICLES_IN_ONE_LINE * numOfLines;
        numOfVertices = 4 * numOfParticles;
        self.rotateMatrix = GLKMatrix4Identity;
        shapeType = Sphere;
        [self initData];
    }
    return self;
}

- (void) initData{
    [self loadTexture];
    [self initBuffer];
    [self initVertexWithRatioOffset:0];
    [self initOthers];
}

- (void)updateVertexWithOffset:(GLfloat)offset{
    [self initVertexWithRatioOffset:offset];
    [self updateVertexBuffer];
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

- (void)loadTexture{
    CGImageRef imageRef = [[UIImage imageNamed:@"particles.png"] CGImage];
    
    textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                               options:nil
                                                 error:NULL];
}

- (GLKVector3)getPointFromMainShapeWithLontitude:(GLfloat)lon Latitude:(GLfloat)lat{
    if (shapeType == Sphere) {
        return [HelperFunction getPointAtSphereWithLongtitude:lon Latitude:lat];
    }else{
        return [HelperFunction getPointAtPlaneWithLongtitude:lon Latitude:lat];
    }
}

- (GLKVector3)inverseRotateVertex:(GLKVector3)vec withMatrix:(GLKMatrix4)inverse{
    GLKVector4 vector = GLKVector4Make(vec.x, vec.y, vec.z, 1.0);
    vector = GLKMatrix4MultiplyVector4(inverse, vector);
    return GLKVector3Make(vector.x, vector.y, vector.z);
}

- (void) initVertexWithRatioOffset:(GLfloat)offset{
    NSUInteger count = 0;
    bool shouldRotate;
    GLKMatrix4 inverseRotateMatrix = GLKMatrix4Invert(self.rotateMatrix, &shouldRotate);
    
    GLKVector3 start = [self getPointFromMainShapeWithLontitude:[self getLongtidueFor:0] Latitude:[self getLatitudeFor:0]];
    for (NSUInteger i = 0; i < numOfLines; i++) {
        GLKVector3 end = [self getPointFromMainShapeWithLontitude:[self getLongtidueFor:i+1] Latitude:[self getLatitudeFor:i+1]];
        GLKVector3* controls = [HelperFunction getControlPointWithStart:start End:end shapeType:shapeType];
        for (NSUInteger j = 0; j < NUM_OF_PARTICLES_IN_ONE_LINE; ++j) {
            GLfloat ratio = (GLfloat)(j * numOfLines + i) / numOfParticles;
            ratio = ratio + offset - floorf(ratio + offset);
            GLKVector3 baseVec = [HelperFunction getPointAtBezierCurveWithRatio:ratio start:start end:end controls:controls];

            GLKVector3 vec0 = GLKVector3Make(-Particle_Size, -Particle_Size, 0);
            GLKVector3 vec1 = GLKVector3Make( Particle_Size, -Particle_Size, 0);
            GLKVector3 vec2 = GLKVector3Make( Particle_Size,  Particle_Size, 0);
            GLKVector3 vec3 = GLKVector3Make(-Particle_Size,  Particle_Size, 0);
            if (shouldRotate) {
                vec0 = [self inverseRotateVertex:vec0 withMatrix:inverseRotateMatrix];
                vec1 = [self inverseRotateVertex:vec1 withMatrix:inverseRotateMatrix];
                vec2 = [self inverseRotateVertex:vec2 withMatrix:inverseRotateMatrix];
                vec3 = [self inverseRotateVertex:vec3 withMatrix:inverseRotateMatrix];
            }
            vertices[count++] = GLKVector3Add(baseVec, vec0);
            vertices[count++] = GLKVector3Add(baseVec, vec1);
            vertices[count++] = GLKVector3Add(baseVec, vec2);
            vertices[count++] = GLKVector3Add(baseVec, vec3);
        }
        SAFE_FREE(controls);
    }
}

- (void)initOthers{
    NSUInteger count = 0;
    GLKVector3 hsl = GLKVector3Make(0.0, 1.0, 0.5);
    for (NSUInteger i = 0; i < numOfLines; i++) {
        hsl.x = [self getMagnitudeWith:i];
        GLKVector3 rgb = [HelperFunction RGBfromHSL:hsl];

        for (NSUInteger j = 0; j < NUM_OF_PARTICLES_IN_ONE_LINE; j++) {
            NSUInteger startIndex = count * 4;
            for (NSUInteger k = 0; k < 4; ++k) {
                colors[startIndex + k] = GLKVector4Make(rgb.r, rgb.g, rgb.b, 0.5);
            }
            textureCoordinates[startIndex].s = 0.5f;
            textureCoordinates[startIndex].t = 0.5f;
            textureCoordinates[startIndex + 1].s = 1.0f;
            textureCoordinates[startIndex + 1].t = 0.5f;
            textureCoordinates[startIndex + 2].s = 1.0f;
            textureCoordinates[startIndex + 2].t = 1.0f;
            textureCoordinates[startIndex + 3].s = 0.5f;
            textureCoordinates[startIndex + 3].t = 1.0f;
            
            NSUInteger start = count * 6;
            indice[start++] = startIndex;
            indice[start++] = startIndex + 1;
            indice[start++] = startIndex + 2;
            indice[start++] = startIndex + 2;
            indice[start++] = startIndex + 3;
            indice[start++] = startIndex;

            ++count;
        }
	}
}

#pragma mark - switch shape

- (void)switchShape:(ShapeType)type{
    memcpy(fromPosition, vertices, sizeofVertices);
    
    shapeType = type;
    [self initVertexWithRatioOffset:0];
    
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
    
    glGenBuffers(1, &textureBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofTextureCoordinate, textureCoordinates, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeofIndice, indice, GL_STATIC_DRAW);
}

- (void)releaseBuffer{
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &colorBuffer);
    glDeleteBuffers(1, &textureBuffer);
    glDeleteBuffers(1, &indexBuffer);
}

- (void) initBuffer{
    //init size and allocate buffer
    sizeofVertices = numOfVertices * sizeof(GLKVector3);
    sizeofColors = numOfVertices * sizeof(GLKVector4);
    sizeofTextureCoordinate = numOfVertices * sizeof(GLKVector2);
    sizeofIndice = 6 * numOfParticles * sizeof(GLushort);
    
    vertices = (GLKVector3*)malloc(sizeofVertices);
    colors = (GLKVector4*)malloc(sizeofColors);
    textureCoordinates = (GLKVector2*)malloc(sizeofTextureCoordinate);
    indice = (GLushort*)malloc(sizeofIndice);
    
    fromPosition = (GLKVector3*)malloc(sizeofVertices);
    toPosition = (GLKVector3*)malloc(sizeofVertices);
}

- (void)updateVertexBuffer{
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_DYNAMIC_DRAW);
}

- (void)drawMainShapesWithModelViewMatrix:(GLKMatrix4)matrix{
    
    self.effect.transform.modelviewMatrix = matrix;
    self.effect.texture2d0.name = textureInfo.name;
    self.effect.texture2d0.target = textureInfo.target;
    [self.effect prepareToDraw];
    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glDepthMask(GL_FALSE);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Texture
    glBindBuffer(GL_ARRAY_BUFFER, textureBuffer);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    //colors
    glBindBuffer(GL_ARRAY_BUFFER, colorBuffer);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Indices
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glDrawElements(GL_TRIANGLES, 6 * (GLsizei)numOfParticles, GL_UNSIGNED_SHORT, NULL);
    
    glDisableVertexAttribArray(GLKVertexAttribColor);
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    glDisable(GL_BLEND);
    glDepthMask(GL_TRUE);

}

- (void) dealloc {
    [self releaseBuffer];
    [self freeResources];
}

- (void)freeResources
{
    SAFE_FREE(vertices);
    SAFE_FREE(colors);
    SAFE_FREE(textureCoordinates);
    SAFE_FREE(indice);
    SAFE_FREE(fromPosition);
    SAFE_FREE(toPosition);
}

@end
