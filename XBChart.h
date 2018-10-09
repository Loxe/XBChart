//
//  Chart.h
//  ContractionCounter
//
//  Created by Binbin on 16/7/27.
//  Copyright (c) 2016年 Loxe. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XBChart;
@protocol XBChartDataSource <NSObject>
@required
-(double)maxValueForChart:(XBChart *)chart;
-(double)minValueForChart:(XBChart *)chart;
-(NSInteger)yAxisNumberForChart:(XBChart *)chart;
-(NSInteger)numberForChart:(XBChart *)chart;
-(NSInteger)xAxisNumberForChart:(XBChart *)chart;
-(double)chart:(XBChart *)chart valueAtIndex:(NSInteger)index;
@optional
-(NSString *)titleForChart:(XBChart *)chart;
-(NSString *)titleForXAtChart:(XBChart *)chart;
-(NSString *)titleForYAtChart:(XBChart *)chart;
-(BOOL)showDataAtPointForChart:(XBChart *)chart;


-(NSString *)chart:(XBChart *)chart titleForXLabelAtIndex:(NSInteger)index;
@end


@protocol XBChartDelegate <NSObject>

@optional
-(void)chart:(XBChart *)view didClickPointAtIndex:(NSInteger)index;
-(void)chartRelese:(XBChart *)view;
@end

@interface XBChart : UIView
@property(nonatomic,assign)id<XBChartDataSource> dataSource;
@property(assign, nonatomic)id<XBChartDelegate> delegate;
@property (nonatomic, strong) UIColor    * color;
@property (nonatomic, strong) UIColor    * lineColor;
@property (nonatomic, strong) UIColor    * touchLineColor;
+ (instancetype)createWithColor:(UIColor*)color lineColor:(UIColor*)lineColor touchLineColor:(UIColor *)touchLineColor frame:(CGRect)frame;
-(void)reload;
@end
