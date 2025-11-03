// ChartView.h

#import <Cocoa/Cocoa.h>

@interface ChartView : NSView

- (void)actualizarConFechas:(NSArray<NSString *> *)fechas valores:(NSArray<NSNumber *> *)valores;

@end
