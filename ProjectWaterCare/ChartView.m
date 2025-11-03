#import "ChartView.h"

@implementation ChartView

- (void)actualizarConFechas:(NSArray<NSString *> *)fechas
                    valores:(NSArray<NSNumber *> *)valores
                 mostrarMes:(BOOL)mes {
    self.fechas = fechas;
    self.valores = valores;
    self.mostrarMes = mes;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.valores.count == 0) return;
    
    CGFloat ancho = self.bounds.size.width;
    CGFloat alto = self.bounds.size.height - 30;
    CGFloat espacio = ancho / self.valores.count;
    
    double max = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
    if (max == 0) max = 1;
    
    if (self.mostrarMes) {
        max = ceil(max / 500.0) * 500.0;
    } else {
        max = ceil(max / 10.0) * 10.0;
    }
    
    // Fondo
    [[NSColor whiteColor] setFill];
    NSRectFill(self.bounds);
    
    // Líneas horizontales y etiquetas
    [[NSColor lightGrayColor] setStroke];
    NSInteger lineas = 5;
    for (NSInteger i = 0; i <= lineas; i++) {
        CGFloat y = 30 + (alto - 20) * i / lineas;
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, y)];
        [path lineToPoint:NSMakePoint(ancho, y)];
        [path stroke];
        
        NSString *label = [NSString stringWithFormat:@"%.0f", max * i / lineas];
        NSDictionary *attrs = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        [label drawAtPoint:NSMakePoint(0, y) withAttributes:attrs];
    }
    
    CGFloat anchoBarra = MIN(30, espacio * 0.6);
    CGFloat margenX = (espacio - anchoBarra) / 2.0;
    
    for (NSInteger i = 0; i < self.valores.count; i++) {
        double valor = [self.valores[i] doubleValue];
        if (valor <= 0) continue; // No dibuja barras de 0
        
        CGFloat altura = (valor / max) * (alto - 20);
        CGFloat x = i * espacio + margenX;
        CGFloat y = 30;
        
        // Color según consumo
        NSColor *color;
        if (valor <= 0.8 * self.umbral) {
            color = [NSColor systemGreenColor];
        } else if (valor <= self.umbral) {
            color = [NSColor systemYellowColor];
        } else {
            color = [NSColor systemRedColor];
        }
        [color setFill];
        NSRectFill(NSMakeRect(x, y, anchoBarra, altura));
        
        // Etiqueta de valor
        NSString *textoValor = [NSString stringWithFormat:@"%.0f", valor];
        NSDictionary *attrsValor = @{NSFontAttributeName:[NSFont systemFontOfSize:9]};
        [textoValor drawAtPoint:NSMakePoint(x, y + altura + 2) withAttributes:attrsValor];
        
        // Etiqueta de fecha
        NSString *fecha = self.fechas[i];
        NSString *corta = [fecha substringFromIndex:5];
        NSDictionary *attrsFecha = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        [corta drawAtPoint:NSMakePoint(x, 5) withAttributes:attrsFecha];
    }
}

@end
