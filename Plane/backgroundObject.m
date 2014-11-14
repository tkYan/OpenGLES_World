//
//  backgroundObject.m
//  Plane
//
//  Created by Peng, Yan on 6/13/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "backgroundObject.h"

@implementation backgroundObject
{
    //OpenGL parameter
    size_t sizeofVertices;
    size_t sizeofTextureCoordinates;
    
    GLKVector3* vertices;
    GLKVector2* textureCoordinates;
    
    GLuint vertexBuffer;
    GLuint textureCoordinateBuffer;
    
    GLKTextureInfo* textureInfo;
}

@synthesize effect;
@synthesize drawEnabled;

#pragma mark -

- (id) init{
    self = [super init];
    if (self) {
        drawEnabled = YES;
        [self initData];
    }
    return self;
}

- (void) initData{
    [self initTexture];
    [self initBuffer];
    [self initShapeData];
}


#pragma mark - internal help function

- (void) initTexture{
    CGImageRef imageRef = [[UIImage imageNamed:@"glow.jpg"] CGImage];
    
    textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                               options:nil
                                                 error:NULL];
}

- (void) initShapeData{
    NSUInteger count = 0;
    NSUInteger num = NUM_OF_VERTEX_FOR_PLANE / 2 - 1;
    for (NSUInteger i = 0 ; i <= num; ++i) {
        GLfloat x = BACKGROUND_PLANE_SIZE * ((GLfloat)i / num  - 0.5);
        GLfloat s = (GLfloat)i / num;
        for (NSUInteger j = 0 ; j <= num; ++j){
            GLfloat y = BACKGROUND_PLANE_SIZE * ((GLfloat)j / num - 0.5);
            GLfloat t = (GLfloat)j / num;
            
            vertices[count].x = x;
            vertices[count].y = y;
            vertices[count].z = - STARTING_Z;
            
            textureCoordinates[count].s = s;
            textureCoordinates[count].t = t;
            
            ++count;
        }
    }
}


#pragma mark - resources manage&drawObjective protocol

- (void)generateBuffer{
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofVertices, vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &textureCoordinateBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofTextureCoordinates, textureCoordinates, GL_STATIC_DRAW);
}

- (void)releaseBuffer{
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &textureCoordinateBuffer);
}

- (void) initBuffer{
    //init size and allocate buffer
    sizeofVertices = NUM_OF_VERTEX_FOR_PLANE * sizeof(GLKVector3);
    sizeofTextureCoordinates = NUM_OF_VERTEX_FOR_PLANE * sizeof(GLKVector2);
    
    vertices = (GLKVector3*)malloc(sizeofVertices);
    textureCoordinates = (GLKVector2*)malloc(sizeofTextureCoordinates);
}


- (void)drawMainShapesWithModelViewMatrix:(GLKMatrix4)matrix{
    
    self.effect.transform.modelviewMatrix = matrix;
    self.effect.texture2d0.name = textureInfo.name;
    self.effect.texture2d0.target = textureInfo.target;
    [self.effect prepareToDraw];
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Texture
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, NUM_OF_VERTEX_FOR_PLANE);
    
    glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
}

- (void) dealloc {
    [self releaseBuffer];
    [self freeResources];
}

- (void)freeResources
{
    SAFE_FREE(vertices);
    SAFE_FREE(textureCoordinates);
}

@end
