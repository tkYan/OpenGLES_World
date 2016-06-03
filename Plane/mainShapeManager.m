//
//  planeManager.m
//  Plane
//
//  Created by Peng, Yan on 3/19/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "mainShapeManager.h"

#import "HelperFucntion.h"

@implementation mainShapeManager
{
    //OpenGL parameter
    size_t sizeofVertices;
    size_t sizeofTextureCoordinates;
    size_t sizeofIndices;
    
    GLKVector3* vertices;
    GLKVector2* textureCoordinates;
    GLushort* indices;
    
    GLuint vertexBuffer;
    GLuint textureCoordinateBuffer;
    GLuint indicesBuffer;
    
    GLKTextureInfo* textureInfo;
    
    //shape parameter
    NSUInteger rowCount;
    NSUInteger colCount;
    NSUInteger numOfVertices;
    NSUInteger numOfIndice;

    GLKVector3* fromPosition;
    GLKVector3* toPosition;
}

@synthesize shapeSwitchAnimation;
@synthesize effect;
@synthesize drawEnabled;

#pragma mark -

- (id) initWithRowCount:(NSUInteger)row ColumnCount:(NSUInteger)column{
    NSAssert(row >=0 && column >=0, @"Invalid Argument, row and column should be non-negative number, row = %lu, col = %lu", (unsigned long)row, (unsigned long)column);
    self = [super init];
    if (self) {
        drawEnabled = YES;
        rowCount = row;
        colCount = column;
        numOfVertices = (rowCount + 1) * (colCount + 1);
        numOfIndice = INDEX_NUMBER_FOR_EACH_RECT * rowCount * colCount;
        [self initData];
        shapeSwitchAnimation = NO;
    }
    return self;
}

- (void) initData{
    [self initTexture];
    [self initBuffer];
    [self initSphereVertex];
    [self initTextureAndIndice];
}


#pragma mark - internal help function

- (void) initTexture{
    CGImageRef imageRef = [[UIImage imageNamed:@"earthbw.jpg"] CGImage];
    
    textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                               options:nil
                                                 error:NULL];
}

- (void) initSphereVertex{
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < colCount + 1; ++i) {
		GLfloat phi = M_PI * (GLfloat)i / colCount;
		for (NSUInteger j = 0; j < rowCount + 1; ++j) {
			GLfloat theta = 2.0 * M_PI * (GLfloat)j / rowCount;
            vertices[count] = [HelperFunction getPointAtSphereWithHorizontalRadius:theta VerticalRadius:phi];
			
			++count;
		}
	}
}

- (void) initPlaneVertex{
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < colCount + 1; ++i) {
        GLfloat y = (0.5f - (GLfloat)i / colCount);
        for (NSUInteger j = 0; j < rowCount + 1; ++j) {
            GLfloat x = ((GLfloat)j / rowCount - 0.5f);
            vertices[count++] = [HelperFunction getPointAtPlaneWithX:x Y:y];
        }
    }
}

- (void)initTextureAndIndice{
    NSUInteger count = 0;
    for (NSUInteger i = 0; i < colCount + 1; ++i) {
		GLfloat t = (GLfloat)i / colCount;
		for (NSUInteger j = 0; j < rowCount + 1; ++j) {
			GLfloat s = (GLfloat)j / rowCount;
			textureCoordinates[count].s = s;
			textureCoordinates[count].t = t;
			++count;
		}
	}
	
	count = 0;
	for (NSUInteger i = 0; i < colCount; ++i) {
		NSUInteger firstInRow = i * (rowCount +1);
		for (NSUInteger j = 0; j < rowCount; ++j) {
            NSUInteger firstInRect = firstInRow + j;
			indices[count++] = firstInRect;
			indices[count++] = firstInRect + (rowCount + 1);
			indices[count++] = firstInRect + 1;
			
			indices[count++] = firstInRect + 1;
			indices[count++] = firstInRect + (rowCount + 1);
			indices[count++] = firstInRect + (rowCount + 1) + 1;
		}
	}
}

#pragma mark - switch shape

- (void)switchShape:(ShapeType)type{
    memcpy(fromPosition, vertices, sizeofVertices);
    
    if (type == Plane) {
        [self initPlaneVertex];
    }else{
        [self initSphereVertex];
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
    
    glGenBuffers(1, &textureCoordinateBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeofTextureCoordinates, textureCoordinates, GL_STATIC_DRAW);
    
    glGenBuffers(1, &indicesBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeofIndices, indices, GL_STATIC_DRAW);
}

- (void)releaseBuffer{
    glDeleteBuffers(1, &vertexBuffer);
    glDeleteBuffers(1, &textureCoordinateBuffer);
    glDeleteBuffers(1, &indicesBuffer);
}

- (void) initBuffer{
    //init size and allocate buffer
    sizeofVertices = numOfVertices * sizeof(GLKVector3);
    sizeofTextureCoordinates = numOfVertices * sizeof(GLKVector2);
    sizeofIndices = numOfIndice * sizeof(GLushort);
    
    vertices = (GLKVector3*)malloc(sizeofVertices);
    textureCoordinates = (GLKVector2*)malloc(sizeofTextureCoordinates);
    indices = (GLushort*)malloc(sizeofIndices);
    
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
    
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    
    // Position
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Texture
    glBindBuffer(GL_ARRAY_BUFFER, textureCoordinateBuffer);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, NULL);
    
    // Indices
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indicesBuffer);
    glDrawElements(GL_TRIANGLES, (GLsizei)numOfIndice, GL_UNSIGNED_SHORT, NULL);
    
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
    SAFE_FREE(indices);
    SAFE_FREE(fromPosition);
    SAFE_FREE(toPosition);
}

@end
