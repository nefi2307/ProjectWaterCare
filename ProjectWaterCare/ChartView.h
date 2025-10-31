//
//  ChartView.h
//  ProjectWaterCare
//
//  Created by Isaac Burciaga on 31/10/25.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChartView : NSView

// API simple: labels (strings) y values (NSNumbers)
- (void)setLabels:(NSArray<NSString*>*)labels values:(NSArray<NSNumber*>*)values;
@end

NS_ASSUME_NONNULL_END
