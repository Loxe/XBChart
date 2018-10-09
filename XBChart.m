//
//  Chart.m
//  ContractionCounter
//
//  Created by Binbin on 16/7/27.
//  Copyright (c) 2016年 Loxe. All rights reserved.
//

#import "XBChart.h"

CGFloat margin=14.f;
CGFloat leftMargin = 40;
CGFloat rightMargin = 20;
CGFloat bottomMargin = 20.f;
CGFloat radius=3.f;
#define yAxisTag 998
#define XBColorRGB(rgbValue)            [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]
@interface XBChart ()<UIGestureRecognizerDelegate>
{

    NSMutableArray <CAShapeLayer*> *_allLayer;
    UIColor * _touchLineColor;
    UIColor * _lineColor;
    UIColor * _color;
    
}
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) CAShapeLayer * linePath;
@property(nonatomic, assign) CGFloat    avgHeight;
@property(nonatomic, assign) double     maxValue;
@property(nonatomic, assign) double     minValue;
@property(nonatomic, assign) NSInteger  dataCount;
@property(nonatomic, assign) NSInteger     xCount;
@property(nonatomic, assign) NSInteger     yCount;
@property (nonatomic, strong) UIImageView   * touchXline;
@property (nonatomic, strong) UIImageView   * touchYline;
@end
@implementation XBChart
+ (instancetype)createWithColor:(UIColor*)color lineColor:(UIColor*)lineColor touchLineColor:(UIColor *)touchLineColor frame:(CGRect)frame{
    XBChart * chart = [[XBChart alloc] initWithFrame:frame];
    chart.touchLineColor = touchLineColor;
    chart.lineColor      = lineColor;
    chart.color          = color;
    return chart;
    
}
-(instancetype)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if (self) {
        self.backgroundColor=[UIColor whiteColor];
        _linePath=[CAShapeLayer layer];
        _linePath.lineCap=kCALineCapRound;
        _linePath.lineJoin=kCALineJoinBevel;
        _linePath.lineWidth=1;
        _linePath.fillColor=[UIColor clearColor].CGColor;
        [self.layer addSublayer:_linePath];
        _maxValue=1;
        _allLayer=[NSMutableArray array];
    }
    return self;
}
-(double)maxValue
{
    return [_dataSource maxValueForChart:self];
}
-(double)minValue {
    return [_dataSource minValueForChart:self];
}


-(NSInteger)dataCount
{
    return [_dataSource numberForChart:self];
}
- (NSInteger)xCount {
    return [_dataSource xAxisNumberForChart:self];
}

- (NSInteger)yCount {
    return [_dataSource yAxisNumberForChart:self];
}
-(CGFloat)avgHeight
{
    CGFloat height=self.frame.size.height;
    _avgHeight=(height - bottomMargin * 2 -20)/(self.maxValue-self.minValue);
    return _avgHeight;
}
-(void)drawRect:(CGRect)rect
{
    [_allLayer enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperlayer];
    }];
    [_allLayer removeAllObjects];
    [self setupReferenceLine];
    [self setupTitle];
    if (self.dataCount>0) {
        [self drawYAxisLabel];
        [self setAxisLabel];
        

        
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureAction:)];
        longPressGesture.minimumPressDuration = 0.1f;
        [self addGestureRecognizer:longPressGesture];
        
        
//        UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGestureAction:)];
//        panGesture.delegate = self;
//        [panGesture setMaximumNumberOfTouches:1];
//        [self addGestureRecognizer:panGesture];
        
        
        UIBezierPath *path=[UIBezierPath bezierPath];
        for (int i=0; i<self.dataCount; i++) {
            CGFloat value=[_dataSource chart:self valueAtIndex:i];
            CGPoint point=[self pointWithValue:value index:i];
            point.y = point.y;
            if (i==0) {
                [path moveToPoint:point];
            }else{
                [path addLineToPoint:point];
            }
        }
        path.lineCapStyle = kCGLineCapRound;
        path.lineJoinStyle=kCGLineJoinRound;
        //path.lineWidth=1;
        [self.lineColor setStroke];
        CABasicAnimation *pathAnimation=[CABasicAnimation animationWithKeyPath:@"strokeEnd"];
        pathAnimation.duration = 1.5;
        pathAnimation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pathAnimation.fromValue=[NSNumber numberWithFloat:0.0f];
        pathAnimation.toValue=[NSNumber numberWithFloat:1.0f];
        pathAnimation.autoreverses=NO;
        _linePath.path=path.CGPath;
        _linePath.strokeColor=self.lineColor.CGColor;
        [_linePath addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
        
        _linePath.strokeEnd = 1.0;
        [self touchXline];
        [self touchYline];
        for (int i=0; i<self.dataCount; i++) {
            CGFloat value=[_dataSource chart:self valueAtIndex:i];
            CGPoint point=[self pointWithValue:value index:i];
            UIBezierPath *drawPoint=[UIBezierPath bezierPath];
            [drawPoint addArcWithCenter:point radius:radius startAngle:M_PI*0 endAngle:M_PI*2 clockwise:YES];
            CAShapeLayer *layer=[[CAShapeLayer alloc]init];
            layer.fillColor = [UIColor whiteColor].CGColor;
            layer.strokeColor = self.color.CGColor;
            layer.path=drawPoint.CGPath;
//            if (self.dataCount == 1) {
//                layer.hidden = NO;
//            } else {
//                layer.hidden = YES;
//            }
            _linePath.strokeEnd=1;
            [_allLayer addObject:layer];
            [self.layer addSublayer:layer];
            if (_dataSource&&[_dataSource respondsToSelector:@selector(showDataAtPointForChart:)]&&[_dataSource showDataAtPointForChart:self]) {
                NSString *valueString=[NSString stringWithFormat:@"%ld",(long)value];
                CGRect frame=[valueString boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f]} context:nil];
                CGPoint pointForValueString=CGPointMake(point.x-frame.size.width/2, point.y+margin/3);
                if (pointForValueString.y+frame.size.height>self.frame.size.height-1.5*margin) {
                    pointForValueString.y=point.y-1.5*margin;
                }
                [valueString drawAtPoint:pointForValueString withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:14.f]}];
            }
        }
    }
}
NSInteger lastIdx;
- (void)handleGestureAction:(UIGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        if (self.dataCount != 1 && self.dataCount > 0) {
//            _allLayer[lastIdx].hidden = YES;
        }
        self.touchYline.hidden = self.touchXline.hidden = YES;
        lastIdx = 999;
        if(_delegate && [_delegate respondsToSelector:@selector(chartRelese:)]) {
            [self.delegate chartRelese:self];
        }
    } else {
        CGFloat width  = self.frame.size.width - leftMargin - rightMargin;
        CGFloat itemW  = (width)/(self.xCount-1);
        CGPoint translation = [recognizer locationInView:self.viewForBaselineLayout];
        translation.x += (leftMargin + itemW/2);
        NSInteger pointIdex = ((translation.x - leftMargin /2) / itemW)-1;

        if (lastIdx != pointIdex && self.dataCount > 0) {
//            if (lastIdx != 999) {
//                _allLayer[lastIdx].hidden = YES;
//            }
            
            if (pointIdex > _allLayer.count-1) {
                pointIdex = _allLayer.count-1;
            } else if (pointIdex < 0) {
                pointIdex = 0;
            }
            _allLayer[pointIdex].hidden = NO;
            lastIdx = pointIdex;
            CGFloat value=[_dataSource chart:self valueAtIndex:pointIdex];
            CGPoint point=[self pointWithValue:value index:pointIdex];
            CGRect xlineRect = self.touchXline.frame;
            CGRect ylineRect = self.touchYline.frame;
            xlineRect.origin.y = point.y;
            ylineRect.origin.x = point.x;
            self.touchXline.frame = xlineRect;
            self.touchYline.frame = ylineRect;
            self.touchYline.hidden = self.touchXline.hidden = NO;
            if (_delegate && [_delegate respondsToSelector:@selector(chart:didClickPointAtIndex:)]) {
                [self.delegate chart:self didClickPointAtIndex:pointIdex];
            }
        }
        
    }
}

-(void)drawXLabel:(NSString *)text index:(NSInteger)index
{
    NSDictionary *font=@{NSFontAttributeName: [UIFont systemFontOfSize:10.f],NSForegroundColorAttributeName:[XBColorRGB(0xC6CCDF) colorWithAlphaComponent:1.F]};
    CGPoint point=[self xLabelPointWithIndex:index];
    CGSize size=[text boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:font context:nil].size;
    point.x-=size.width/2;
    point.y+=3;
    [text drawAtPoint:point withAttributes:font];
}
-(void)drawYAxisLabel
{
    NSInteger removeTag = yAxisTag;
    do {
        [[self viewWithTag:removeTag] removeFromSuperview];
        removeTag++;
    } while ([self viewWithTag:removeTag]);
    for (int i = 0; i<self.yCount+1; i++) {
        CGPoint yPoint = [self yLabelPointWithIndex:i];
        UILabel * lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, yPoint.y-6, leftMargin , 12)];
        lbl.adjustsFontSizeToFitWidth = YES;
        lbl.minimumScaleFactor = 6;
        lbl.text = [NSString stringWithFormat:@"%.2lf",self.maxValue - ((self.maxValue - self.minValue )/self.yCount * i)];
        lbl.font = [UIFont systemFontOfSize:10];
        lbl.tag = yAxisTag+i;
        lbl.textAlignment = NSTextAlignmentCenter;
        lbl.textColor = [XBColorRGB(0xC6CCDF) colorWithAlphaComponent:1.F];
        [self addSubview:lbl];
    }
    
   
    
    
    
//    
//    NSString *origin=@"0";
//    [origin drawAtPoint:CGPointMake(0.9*margin, self.frame.size.height-2*margin) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:11.f]}];
//    
//    NSString *max=[NSString stringWithFormat:@"%ld",(long)self.maxValue];
//    CGRect tmpFrame=[max boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:font context:nil];
//    [max drawAtPoint:CGPointMake(1.5*margin-tmpFrame.size.width-1, [self pointWithValue:_maxValue index:0].y-5) withAttributes:font];
}
-(void)setupTitle
{
    if (_dataSource&&[_dataSource respondsToSelector:@selector(titleForChart:)]) {
        self.titleLabel.text=[_dataSource titleForChart:self];
    }
    if (_dataSource&&[_dataSource respondsToSelector:@selector(titleForYAtChart:)]) {
        NSString *yTitle=[_dataSource titleForYAtChart:self];
        [yTitle drawAtPoint:CGPointMake(1.5*margin,0.5*margin) withAttributes:nil];
    }
    if (_dataSource&&[_dataSource respondsToSelector:@selector(titleForXAtChart:)]) {
        NSString *xTitle=[_dataSource titleForXAtChart:self];
        CGRect frame=[xTitle boundingRectWithSize:CGSizeMake(MAXFLOAT, MAXFLOAT) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.f]} context:nil];
        [xTitle drawAtPoint:CGPointMake(self.frame.size.width-margin-frame.size.width,self.frame.size.height-2*margin-frame.size.height) withAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.f]}];
    }
    
    
}
-(void)setupReferenceLine
{
    CGFloat height=self.frame.size.height;
    CGFloat width = self.frame.size .width;
    UIColor * yColor = [XBColorRGB(0xC6CCDF) colorWithAlphaComponent:0.3];
    UIColor * xColor = [XBColorRGB(0xDDE1EC) colorWithAlphaComponent:0.3];
    UIBezierPath *coordinate=[UIBezierPath bezierPath];
    [XBColorRGB(0xC6CCDF) setStroke];
    [coordinate moveToPoint:CGPointMake(self.dataCount>0?leftMargin:rightMargin, bottomMargin)];
    [coordinate addLineToPoint:CGPointMake(self.dataCount>0?leftMargin:rightMargin, self.frame.size.height-bottomMargin)];
    [coordinate addLineToPoint:CGPointMake(self.frame.size.width-rightMargin, self.frame.size.height-bottomMargin)];
    [coordinate stroke];
    
    for (int i = 1; i < self.xCount; i++) {
        CGPoint  p = [self xLabelPointWithIndex:i];
        UIBezierPath * referenceLine=[UIBezierPath bezierPath];
        [xColor setStroke];
        [referenceLine moveToPoint:CGPointMake(p.x, height-bottomMargin)];
        [referenceLine addLineToPoint:CGPointMake(p.x, bottomMargin)];
        [referenceLine stroke];
    }
    
    for (int i = 0; i < self.yCount; i++) {
        CGPoint p = [self yLabelPointWithIndex:i];
        [yColor setStroke];
        p.x  = leftMargin;
        UIBezierPath * referenceLine=[UIBezierPath bezierPath];
        [referenceLine moveToPoint:CGPointMake(self.dataCount>0?leftMargin:rightMargin , p.y)];
        [referenceLine addLineToPoint:CGPointMake(width-rightMargin, p.y)];
        [referenceLine stroke];
    }

}

-(void)setAxisLabel {
        for (int i = 0; i<self.xCount; i++) {
            NSString * titleForXLabel = @"";
            if ([_dataSource respondsToSelector:@selector(chart:titleForXLabelAtIndex:)]) {
                titleForXLabel = [_dataSource chart:self titleForXLabelAtIndex:i];
            }
            [self drawXLabel:titleForXLabel index:i];
        }
}

-(UILabel *)titleLabel
{
    if (_titleLabel==nil) {
        _titleLabel=[[UILabel alloc]init];
        _titleLabel.font=[UIFont systemFontOfSize:14.f];
        [self addSubview:_titleLabel];
        _titleLabel.translatesAutoresizingMaskIntoConstraints=NO;
        _titleLabel.textAlignment=NSTextAlignmentCenter;
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_titleLabel]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_titleLabel)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[_titleLabel]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_titleLabel)]];
    }
    return _titleLabel;
  
}
-(CGPoint)pointWithValue:(double)value index:(NSInteger)index
{
    CGFloat height =self.frame.size.height - bottomMargin;
    CGFloat width  =self.frame.size.width  - rightMargin - (self.dataCount>0?leftMargin:rightMargin);
    return CGPointMake((self.dataCount>0?leftMargin:rightMargin) + (width)/(self.xCount-1) * index, height-fabs(self.minValue-value)*self.avgHeight);
}

-(CGPoint)xLabelPointWithIndex:(NSInteger)index
{
    CGFloat height =self.frame.size.height - bottomMargin;
    CGFloat width  =self.frame.size.width - rightMargin - (self.dataCount>0?leftMargin:rightMargin);
    return CGPointMake((self.dataCount>0?leftMargin:rightMargin) + (width)/(self.xCount-1) * index, height);
}

-(CGPoint)yLabelPointWithIndex:(NSInteger)index {
    CGFloat height = self.frame.size.height;
    CGFloat chartHeight = height - bottomMargin*2 - 20;
    return CGPointMake(0, bottomMargin + 20 + index *(chartHeight/self.yCount));
}
-(void)reload
{
    [self setNeedsDisplay];
}
- (UIColor *)color {
    return _color?_color:[UIColor redColor];
}

- (void)setColor:(UIColor *)color {
    _color = color;
    [self setNeedsDisplay];
}

- (UIColor *)lineColor {
    return _lineColor ? _lineColor : self.color;
}

- (void)setLineColor:(UIColor *)lineColor {
    _lineColor = lineColor;
    [self setNeedsDisplay];
}

-(UIImageView *)touchXline {
    if (!_touchXline) {
        _touchXline  = [[UIImageView alloc]initWithFrame:CGRectMake(leftMargin, 0, self.frame.size.width-leftMargin-rightMargin, 1)];
        _touchXline.backgroundColor = self.touchLineColor;
        _touchXline.hidden = YES;
        [self addSubview:_touchXline];
    }
    return _touchXline;
}
-(UIImageView *)touchYline {
    if (!_touchYline) {
        _touchYline  = [[UIImageView alloc]initWithFrame:CGRectMake(0, bottomMargin, 1, self.frame.size.height-bottomMargin*2)];
        _touchYline.backgroundColor = self.touchLineColor;
        _touchYline.hidden = YES;
        [self addSubview:_touchYline];
    }
    return _touchYline;
}
- (UIColor *)touchLineColor {
    return _touchLineColor ? _touchLineColor : self.color;
}
- (void)setTouchLineColor:(UIColor *)ttouchLineColor {
    _touchLineColor = ttouchLineColor;
    self.touchYline.backgroundColor = self.touchXline.backgroundColor = ttouchLineColor;
}
@end
