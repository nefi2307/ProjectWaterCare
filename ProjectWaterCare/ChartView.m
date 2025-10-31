//
//  ChartView.m
//  ProjectWaterCare
//
//  Created by Isaac Burciaga on 31/10/25.
//

#import "ChartView.h"

@interface ChartView ()
@property (nonatomic, strong) NSArray<NSString*> *labels;
@property (nonatomic, strong) NSArray<NSNumber*> *values;
@end

@implementation ChartView

- (void)setLabels:(NSArray<NSString*> *)labels values:(NSArray<NSNumber*> *)values {
    self.labels = labels;
    self.values = values;
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (!self.values || self.values.count == 0) return;
    
    NSGraphicsContext* ctx = [NSGraphicsContext currentContext];
    CGContextRef gc = (CGContextRef)ctx.graphicsPort;
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    NSUInteger n = self.values.count;
    CGFloat margin = 10;
    CGFloat available = w - 2*margin;
    CGFloat barWidth = (available / (CGFloat)n) * 0.8;
    CGFloat gap = (available - n*barWidth) / (n>1 ? (n-1) : 1);
    
    // hallar max para escalado
    double maxV = 0;
    for (NSNumber *num in self.values) { if ([num doubleValue] > maxV) maxV = [num doubleValue]; }
    if (maxV == 0) maxV = 1;
    
    for (NSUInteger i=0; i<n; i++) {
        double val = [self.values[i] doubleValue];
        CGFloat barHeight = (val / maxV) * (h - 40);
        CGFloat x = margin + i*(barWidth + gap);
        CGFloat y = 20;
        CGRect barRect = CGRectMake(x, y, barWidth, barHeight);
        
        CGContextSetFillColorWithColor(gc, [[NSColor systemBlueColor] CGColor]);
        CGContextFillRect(gc, barRect);
        
        // Label debajo de la barra
        NSString *label = (i < self.labels.count) ? self.labels[i] : @"";
        NSDictionary *attrs = @{ NSFontAttributeName: [NSFont systemFontOfSize:9],
                                 NSForegroundColorAttributeName: [NSColor labelColor] };
        CGRect labelRect = CGRectMake(x, 0, barWidth, 16);
        [label drawInRect:labelRect withAttributes:attrs];
    }
    
    // borde inferior
    CGContextSetStrokeColorWithColor(gc, [[NSColor lightGrayColor] CGColor]);
    CGContextStrokeRect(gc, CGRectMake(margin, 20, w-2*margin, h-40));
}

@end
