//
//  HelperFucntion.m
//  Plane
//
//  Created by Peng, Yan on 6/14/14.
//  Copyright (c) 2014 Peng, Yan. All rights reserved.
//

#import "HelperFucntion.h"

#import "Constants.h"

#define GUARD_ARRANGE(target, x, y) ((target < x) ? x : ((target > y) ? y : target))
#define BEZIER_CURVE(t, v0, v1, v2) ((1.0-t)*(1.0-t)*v0 + 2*(1-t)*t*v1 + t*t*v2)
#define BEZIER_CURVE_C2(t, v0, v1, v2, v3) ((1.0 - t) * (1.0 - t) * (1.0 - t) * v0 + 3 * (1.0 - t) * (1.0 - t) * t * v1 + 3 * (1.0 - t) * t * t * v2 + t * t * t *v3)

@implementation HelperFunction

+ (GLKVector3)getPointAtSphereWithLongtitude:(GLfloat)lon Latitude:(GLfloat)lat{
    return [HelperFunction getPointAtSphereWithHorizontalRadius:GLKMathDegreesToRadians(lon + 180) VerticalRadius:GLKMathDegreesToRadians(90 - lat)];
}

+ (GLKVector3)getPointAtSphereWithHorizontalRadius:(GLfloat)theta VerticalRadius:(GLfloat)phi{
    theta = theta - M_PI / 2; //make the line of 0 degree lontitude the center of the sphere at the very begining
    return GLKVector3MultiplyScalar(GLKVector3Make(-sinf(phi) * cosf(theta), cosf(phi), sinf(phi) * sinf(theta)),SPHERE_RADIUS);
}

+ (GLKVector3)getPointAtPlaneWithLongtitude:(GLfloat)lon Latitude:(GLfloat)lat{
    return [HelperFunction getPointAtPlaneWithX:(lon/360) Y:lat/(180)];
}

+ (GLKVector3)getPointAtPlaneWithX:(GLfloat)x Y:(GLfloat)y{
    GLKVector3 planeScaleFactor = GLKVector3Make(PLANE_WIDTH_HEIGHT_RATIO * PLANE_HEIGHT, PLANE_HEIGHT, 1);
    return GLKVector3Multiply(GLKVector3Make(x, y, 0), planeScaleFactor);
}

+ (GLKVector3)getPointAtBezierCurveWithRatio:(GLfloat)t start:(GLKVector3)start end:(GLKVector3)end controls:(GLKVector3*)controls{
    GLKVector3 point;
    point.x = BEZIER_CURVE_C2(t, start.x, controls[0].x, controls[1].x, end.x);
    point.y = BEZIER_CURVE_C2(t, start.y, controls[0].y, controls[1].y, end.y);
    point.z = BEZIER_CURVE_C2(t, start.z, controls[0].z, controls[1].z, end.z);
    return point;
}

+ (GLKVector3*)getControlPointWithStart:(GLKVector3)start End:(GLKVector3)end shapeType:(NSInteger)type{
    NSUInteger num = 2;
    GLKVector3* controls = (GLKVector3*)malloc(num * sizeof(GLKVector3));
    GLfloat length = GLKVector3Length(GLKVector3Subtract(end, start));
    GLKVector3 normal = GLKVector3Normalize(GLKVector3Add(start, end));
    NSUInteger gap = 6;
    for (NSUInteger i = 1; i <= num; ++i) {
        GLKVector3 control = GLKVector3Add(start, GLKVector3MultiplyScalar(GLKVector3Subtract(end, start),(GLfloat)(i + (i - 1) * gap) / (num + gap + 1)));
        if (type == Sphere) {
            control = GLKVector3Add(control, GLKVector3MultiplyScalar(normal, 0.8 * length));
        }else{
            control.z = 1.5;
        }
        controls[i - 1] = control;
    }
    return controls;
}

+ (GLfloat)getMagnitudeWith:(NSUInteger)i{
    return ((i + 1.0) / (sizeof(country) / sizeof(countryInfo) + 2));
}

+ (GLKVector3)RGBfromHSL:(GLKVector3)hsl{
    GLfloat h = hsl.x;
    GLfloat s = hsl.y;
    GLfloat l = hsl.z;
    
    assert(h > -0.0001 && h < 1.0001);
    assert(s > -0.0001 && s < 1.0001);
    assert(l > -0.0001 && l < 1.0001);
    
    GLKVector3 rgb = GLKVector3Make(0.0, 0.0, 0.0);
    if ( s < 0.0001) {
        rgb.r = rgb.g = rgb.b = l;
        return rgb;
    }
    
    GLfloat q = (l < 0.5f ) ? (l * (1.0f + s)) : (l + s - (l * s));
    GLfloat p = (2.0f * l) - q;
    
    GLfloat T[3];
    T[0] = h + 0.3333333f;
    T[1] = h;
    T[2] = h - 0.3333333f;
    
    for(NSUInteger i=0; i<3; i++)
        
    {
        if(T[i] < 0) T[i] += 1.0f;
        if(T[i] > 1) T[i] -= 1.0f;
        
        if((T[i] * 6) < 1)
        {
            T[i] = p + ((q - p) * 6.0f * T[i]);
        }
        else if((T[i] * 2.0f) < 1)
        {
            T[i] = q;
        }
        else if((T[i] * 3.0f) < 2)
        {
            T[i] = p + (q-p) * ((2.0f/3.0f) - T[i]) * 6.0f;
        }
        else
        {
            T[i] = p;
        }
    }
    
    rgb.r = GUARD_ARRANGE(T[0],0.0,1.0);
    rgb.g = GUARD_ARRANGE(T[1],0.0,1.0);
    rgb.b = GUARD_ARRANGE(T[2],0.0,1.0);
    
    return rgb;
}

@end
