//
//  HelperFucntion.h
//  Plane
//
//  Created by Peng, Yan on 6/14/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKit.h>

@interface HelperFunction : NSObject

+ (GLKVector3)getPointAtSphereWithLongtitude:(GLfloat)lon Latitude:(GLfloat)lat;
+ (GLKVector3)getPointAtSphereWithHorizontalRadius:(GLfloat)theta VerticalRadius:(GLfloat)phi;
+ (GLKVector3)getPointAtPlaneWithLongtitude:(GLfloat)lon Latitude:(GLfloat)lat;
+ (GLKVector3)getPointAtPlaneWithX:(GLfloat)x Y:(GLfloat)y;

+ (GLKVector3)getPointAtBezierCurveWithRatio:(GLfloat)t start:(GLKVector3)start end:(GLKVector3)end controls:(GLKVector3*)controls;
+ (GLKVector3*)getControlPointWithStart:(GLKVector3)start End:(GLKVector3)end shapeType:(NSInteger)type;

+ (GLfloat)getMagnitudeWith:(NSUInteger)i;

+ (GLKVector3)RGBfromHSL:(GLKVector3)hsl;

@end
