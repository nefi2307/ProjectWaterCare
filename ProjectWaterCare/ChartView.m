// ChartView.m

#import "ChartView.h"

@interface ChartView ()
@property NSArray<NSString *> *fechas;
@property NSArray<NSNumber *> *valores;
@end

@implementation ChartView

- (void)actualizarConFechas:(NSArray<NSString *> *)fechas valores:(NSArray<NSNumber *> *)valores {
    self.fechas = fechas;
    self.valores = valores;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.valores.count == 0) return;
    
    CGFloat ancho = self.bounds.size.width;
    CGFloat alto = self.bounds.size.height - 30; // margen inferior para etiquetas
    CGFloat espacio = ancho / self.valores.count; // espacio por barra
    
    // Determinar el valor máximo para escalar las barras
    double max = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
    if (max == 0) max = 1;
    max = ceil(max / 10.0) * 10; // redondear a múltiplos de 10
    
    // Fondo blanco
    [[NSColor whiteColor] setFill];
    NSRectFill(self.bounds);
    
    // Dibujar líneas horizontales del eje Y con etiquetas
    [[NSColor lightGrayColor] setStroke];
    NSInteger lineas = 5;
    for (NSInteger i = 0; i <= lineas; i++) {
        CGFloat y = 30 + (alto - 20) * i / lineas;
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, y)];
        [path lineToPoint:NSMakePoint(ancho, y)];
        [path stroke];
        
        // Etiqueta Y
        NSString *label = [NSString stringWithFormat:@"%.0f", max * i / lineas];
        NSDictionary *attrs = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        [label drawAtPoint:NSMakePoint(0, y) withAttributes:attrs];
    }
    
    // Dibujar barras
    CGFloat anchoBarra = MIN(30, espacio * 0.6); // ancho máximo 30 px o 60% del espacio
    CGFloat margenX = (espacio - anchoBarra) / 2.0; // centrar barra
    
    for (NSInteger i = 0; i < self.valores.count; i++) {
        double valor = [self.valores[i] doubleValue];
        CGFloat altura = (valor / max) * (alto - 20); // altura proporcional
        CGFloat x = i * espacio + margenX;
        CGFloat y = 30; // desde el eje inferior
        
        // Dibujar barra
        NSRect barra = NSMakeRect(x, y, anchoBarra, altura);
        [[NSColor systemBlueColor] setFill];
        NSRectFill(barra);
        
        // Valor encima de la barra
        NSString *textoValor = [NSString stringWithFormat:@"%.0f", valor];
        NSDictionary *attrsValor = @{NSFontAttributeName:[NSFont systemFontOfSize:9]};
        [textoValor drawAtPoint:NSMakePoint(x, y + altura + 2) withAttributes:attrsValor];
        
        // Etiqueta abajo (fecha corta MM-dd)
        NSString *fecha = self.fechas[i];
        NSString *corta = [fecha substringFromIndex:5];
        NSDictionary *attrsFecha = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        [corta drawAtPoint:NSMakePoint(x, 5) withAttributes:attrsFecha];
    }
}

@end
