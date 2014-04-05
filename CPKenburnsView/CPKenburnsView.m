    //
    //CPKenburnsImageView.m
    //
    //The MIT License (MIT)
    //Copyright © 2014 Muukii (www.muukii.me)
    //
    //Permission is hereby granted, free of charge, to any person obtaining a copy
    //of this software and associated documentation files (the “Software”), to deal
    //in the Software without restriction, including without limitation the rights
    //to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    //copies of the Software, and to permit persons to whom the Software is
    //furnished to do so, subject to the following conditions:
    //
    //The above copyright notice and this permission notice shall be included in
    //all copies or substantial portions of the Software.
    //
    //THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    //IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    //FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    //AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    //LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    //OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    //THE SOFTWARE.

#import "CPKenburnsView.h"
@interface CPKenburnsImageView : UIImageView

@end

@implementation CPKenburnsImageView

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    [self.layer addAnimation:[CATransition animation] forKey:kCATransition];
}
@end

@interface CPKenburnsView ()
@property (nonatomic, strong) CPKenburnsImageView * imageView;
@property (nonatomic) CGAffineTransform startTransform;
@property (nonatomic) CGAffineTransform endTransform;
@end
@implementation CPKenburnsView
{
    CGSize initImageViewSize;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initParams];
        [self configureView];
        [self configureAnimation];
    }
    return self;
}

- (void)configureView
{
    [self.imageView removeFromSuperview];
    self.imageView = [[CPKenburnsImageView alloc] initWithFrame:self.bounds];
    self.startTransform = CGAffineTransformIdentity;
    self.endTransform = CGAffineTransformIdentity;
    self.autoresizesSubviews = YES;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.clipsToBounds = YES;
    [self addSubview:self.imageView];
}

- (void)initParams
{
    self.minZoomRate = 1.2;
    self.maxZoomRate = 1.4;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
}

- (void)configureAnimation
{
    self.animationDuration = 15.f;
}

- (void)configureTransforms
{
    CPKenburnsImageViewZoomCourse cource = self.course != 0 ? self.course : (CPKenburnsImageViewZoomCourse)arc4random()%4 + 1;
    self.course = cource;
    [self setZoomRects:cource];
}

- (void)resetTransforms
{
    [self setZoomRects:self.course];
}

- (void)setZoomRects:(CPKenburnsImageViewZoomCourse)cource
{
    CGRect startRect;
    CGRect endRect;
    switch (cource) {
        case CPKenburnsImageViewZoomCourseUpperLeftToLowerRight:
            startRect = [self zoomRect:CPKenburnsImageViewZoomPointUpperLeft zoomRate:adjustZoomRate(self.minZoomRate, self.zoomRatio)];
            endRect = [self zoomRect:CPKenburnsImageViewZoomPointLowerRight zoomRate:adjustZoomRate(self.maxZoomRate, self.zoomRatio)];
            break;
        case CPKenburnsImageViewZoomCourseUpperRightToLowerLeft:
            startRect = [self zoomRect:CPKenburnsImageViewZoomPointUpperRight zoomRate:adjustZoomRate(self.minZoomRate, self.zoomRatio)];
            endRect = [self zoomRect:CPKenburnsImageViewZoomPointLowerLeft zoomRate:adjustZoomRate(self.maxZoomRate, self.zoomRatio)];
            break;
        case CPKenburnsImageViewZoomCourseLowerLeftToUpperRight:
            startRect = [self zoomRect:CPKenburnsImageViewZoomPointLowerLeft zoomRate:adjustZoomRate(self.minZoomRate, self.zoomRatio)];
            endRect = [self zoomRect:CPKenburnsImageViewZoomPointUpperRight zoomRate:adjustZoomRate(self.maxZoomRate, self.zoomRatio)];
            break;
        case CPKenburnsImageViewZoomCourseLowerRightToUpperLeft:
            startRect = [self zoomRect:CPKenburnsImageViewZoomPointLowerRight zoomRate:adjustZoomRate(self.minZoomRate, self.zoomRatio)];
            endRect = [self zoomRect:CPKenburnsImageViewZoomPointUpperLeft zoomRate:adjustZoomRate(self.maxZoomRate, self.zoomRatio)];
            break;
        case CPKenburnsImageViewZoomCourseRandom:
            NSAssert(@"Random is not support", nil);
            return;
    }
    self.startTransform = translatedAndScaledTransformUsingViewRect(startRect, self.imageView.frame);
    if (startRect.size.width == 0) {
        NSAssert(@"Move Rect is Null", nil);
    }
    self.endTransform = translatedAndScaledTransformUsingViewRect(endRect, self.imageView.frame);
}

- (void)setImage:(UIImage *)image
{
    _image = image;
    if (image == nil) {
        self.imageView.image = nil;
        return;
    }
    [self initImageViewSize:image];
    [self configureTransforms];
    [self motion];
}

- (void)initImageViewSize:(UIImage *)image
{
    CGSize imageSize = image.size;
    CGFloat width = CGRectGetWidth(self.bounds);
    CGFloat height = CGRectGetHeight(self.bounds);

    CGFloat power;
    CGSize resizedImageSize;
    CGFloat selfLongSize = MAX(CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds));

        //写真のサイズに合わせる
    if (imageSize.width > imageSize.height) {
            //横長
        power = selfLongSize / imageSize.height;
        resizedImageSize = CGSizeMake(imageSize.width * power, imageSize.height * power);
    } else if (imageSize.width == imageSize.height) {
            //正方形
        resizedImageSize = CGSizeMake(width, height);
    } else {
            //縦長
        power = selfLongSize / imageSize.width;
        resizedImageSize = CGSizeMake(imageSize.width * power, imageSize.height * power);
    }
    self.imageView.transform = CGAffineTransformIdentity;
    CGRect imageViewRect = self.imageView.bounds;
    imageViewRect.size = resizedImageSize;
    self.imageView.bounds = imageViewRect;
    self.imageView.image = image;
    initImageViewSize = resizedImageSize;
}

- (void)restartMotion
{
    [self initImageViewSize:self.image];
    [self configureTransforms];
    [self motion];
}
- (void)motion
{
    [UIView animateWithDuration:self.animationDuration delay:0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat animations:^{
        self.imageView.transform = self.startTransform;
        self.imageView.transform = self.endTransform;
    } completion:^(BOOL finished) {
    }];
}

- (CGRect)zoomRect:(CPKenburnsImageViewZoomPoint)zoomPoint zoomRate:(CGFloat)zoomRate
{
    CGSize imageSize = initImageViewSize;
    CGSize zoomSize;
    CGPoint point;

    zoomSize = CGSizeMake(imageSize.width*zoomRate,imageSize.height*zoomRate);

    CGFloat y = -(fabs(zoomSize.height - CGRectGetHeight(self.bounds)));
    CGFloat x = -(fabs(zoomSize.width - CGRectGetWidth(self.bounds)));

    switch (zoomPoint) {
        case CPKenburnsImageViewZoomPointLowerLeft:
            point = CGPointMake(0, y);
            break;
        case CPKenburnsImageViewZoomPointLowerRight:
            point = CGPointMake(x, y);
            break;
        case CPKenburnsImageViewZoomPointUpperLeft:
            point = CGPointMake(0,0);
            break;
        case CPKenburnsImageViewZoomPointUpperRight:
            point = CGPointMake(x, 0);
            break;
    }
    CGRect zoomRect;
    zoomRect.size = zoomSize;
    zoomRect.origin = point;
    return zoomRect;
}

CGFloat
adjustZoomRate(CGFloat zoomRate,CGFloat ratio)
{
    return zoomRate;
}

CGAffineTransform
translatedAndScaledTransformUsingViewRect(CGRect viewRect,CGRect fromRect)
{
    CGSize scales = CGSizeMake(viewRect.size.width/fromRect.size.width, viewRect.size.height/fromRect.size.height);
    CGPoint offset = CGPointMake(CGRectGetMidX(viewRect) - CGRectGetMidX(fromRect), CGRectGetMidY(viewRect) - CGRectGetMidY(fromRect));
    return CGAffineTransformMake(scales.width, 0, 0, scales.height, offset.x, offset.y);
}

CGAffineTransform
scaleFromSizeToSize(CGSize fromSize,CGSize toSize)
{
    CGSize scales = CGSizeMake(toSize.width/fromSize.width, toSize.height/fromSize.height);
    return CGAffineTransformMakeScale(scales.width,scales.height);
}

@end
