#import "ChartView.h"

@implementation ChartView

// --- (Inicialización no cambia: initWithFrame, initWithCoder, commonInit) ---

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self setWantsLayer:YES];
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.barLayers = [NSMutableArray array];
}

// --- (actualizarConFechas no cambia) ---

- (void)actualizarConFechas:(NSArray<NSString *> *)fechas
                     valores:(NSArray<NSNumber *> *)valores
                  mostrarMes:(BOOL)mes {
    self.fechas = fechas;
    self.valores = valores;
    self.mostrarMes = mes;
    
    [self layoutBarLayersAnimated:YES];
    [self setNeedsDisplay:YES];
}


// --- (layoutBarLayersAnimated no cambia) ---

- (void)layoutBarLayersAnimated:(BOOL)animated {
    
    for (CALayer *layer in self.barLayers) {
        [layer removeFromSuperlayer];
    }
    [self.barLayers removeAllObjects];

    if (self.valores.count == 0) {
        [self setNeedsDisplay:YES];
        return;
    }

    CGFloat ancho = self.bounds.size.width;
    CGFloat alto = self.bounds.size.height - 30;
    CGFloat altoGrafica = alto - 20;
    CGFloat yBase = 30;

    double max = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
    if (max == 0) max = 1;
    if (!self.mostrarMes) {
        double maxValor = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
        double maxGrafica = ceil(MAX(maxValor, self.umbralRojo) / 10.0) * 10.0;
        if (maxGrafica == 0) maxGrafica = 10;
        max = maxGrafica;
    } else {
        max = ceil(max / 500.0) * 500.0;
    }

    CGFloat espacio = ancho / self.valores.count;
    CGFloat anchoBarra = MIN(30, espacio * 0.6);
    CGFloat margenX = (espacio - anchoBarra) / 2.0;
    
    NSMutableArray *alturasFinales = [NSMutableArray arrayWithCapacity:self.valores.count];

    for (NSInteger i = 0; i < self.valores.count; i++) {
        double valor = [self.valores[i] doubleValue];
        CGFloat x = i * espacio + margenX;
        CGFloat alturaFinal = (valor / max) * altoGrafica;
        [alturasFinales addObject:@(alturaFinal)];
        
        NSColor *colorBarra;
        if (valor == 0) {
            colorBarra = [NSColor lightGrayColor];
        } else if (valor >= self.umbralRojo) {
            colorBarra = [NSColor systemRedColor];
        } else if (valor >= self.umbralAmarillo) {
            colorBarra = [NSColor systemYellowColor];
        } else {
            colorBarra = [NSColor systemGreenColor];
        }
        
        CALayer *barLayer = [CALayer layer];
        barLayer.backgroundColor = colorBarra.CGColor;
        barLayer.anchorPoint = CGPointMake(0.5, 0.0);
        barLayer.position = CGPointMake(x + anchoBarra / 2.0, yBase);
        barLayer.bounds = CGRectMake(0, 0, anchoBarra, 0);

        [self.layer addSublayer:barLayer];
        [self.barLayers addObject:barLayer];
    }
    
    if (!animated) {
        for (NSInteger i = 0; i < self.barLayers.count; i++) {
            self.barLayers[i].bounds = CGRectMake(0, 0, anchoBarra, [alturasFinales[i] doubleValue]);
        }
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context) {
            context.duration = 0.5;
            context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            context.allowsImplicitAnimation = YES;
            
            for (NSInteger i = 0; i < self.barLayers.count; i++) {
                CGFloat alturaFinal = [alturasFinales[i] doubleValue];
                self.barLayers[i].bounds = CGRectMake(0, 0, anchoBarra, alturaFinal);
            }
            
        } completionHandler:nil];
    });
}


// *** MÉTODO 'drawRect:' MODIFICADO ***
// (Las barras animadas ya están, esto dibuja las líneas y las NUEVAS etiquetas)
- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    if (self.valores.count == 0) {
        return;
    }

    CGFloat ancho = self.bounds.size.width;
    CGFloat alto = self.bounds.size.height - 30;
    
    double max = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
    if (max == 0) max = 1;

    if (!self.mostrarMes) {
        double maxValor = [[self.valores valueForKeyPath:@"@max.doubleValue"] doubleValue];
        double maxGrafica = ceil(MAX(maxValor, self.umbralRojo) / 10.0) * 10.0;
        if (maxGrafica == 0) maxGrafica = 10;
        max = maxGrafica;
    } else {
        max = ceil(max / 500.0) * 500.0;
    }

    CGFloat altoGrafica = alto - 20;
    CGFloat yBase = 30;

    // Líneas de referencia y etiquetas (Grises)
    [[NSColor lightGrayColor] setStroke];
    NSInteger lineas = 5;
    for (NSInteger i = 0; i <= lineas; i++) {
        CGFloat y = yBase + (altoGrafica) * i / lineas;
        NSBezierPath *path = [NSBezierPath bezierPath];
        [path moveToPoint:NSMakePoint(0, y)];
        [path lineToPoint:NSMakePoint(ancho, y)];
        [path stroke];
        
        NSString *label = [NSString stringWithFormat:@"%.0f", max * i / lineas];
        NSDictionary *attrs = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        [label drawAtPoint:NSMakePoint(0, y) withAttributes:attrs];
    }
    
    // DIBUJAR LÍNEAS DE UMBRAL (Punteadas)
    CGFloat dashPattern[] = {4.0, 2.0};
    
    if (self.umbralAmarillo > 0 && self.umbralAmarillo < max) {
        CGFloat yAmarillo = yBase + (self.umbralAmarillo / max) * altoGrafica;
        NSBezierPath *pathAmarillo = [NSBezierPath bezierPath];
        [pathAmarillo moveToPoint:NSMakePoint(0, yAmarillo)];
        [pathAmarillo lineToPoint:NSMakePoint(ancho, yAmarillo)];
        [pathAmarillo setLineDash:dashPattern count:2 phase:0.0];
        [[NSColor systemYellowColor] setStroke];
        [pathAmarillo stroke];
    }
    
    if (self.umbralRojo > 0 && self.umbralRojo < max) {
        CGFloat yRojo = yBase + (self.umbralRojo / max) * altoGrafica;
        NSBezierPath *pathRojo = [NSBezierPath bezierPath];
        [pathRojo moveToPoint:NSMakePoint(0, yRojo)];
        [pathRojo lineToPoint:NSMakePoint(ancho, yRojo)];
        [pathRojo setLineDash:dashPattern count:2 phase:0.0];
        [[NSColor systemRedColor] setStroke];
        [pathRojo stroke];
    }
    
    
    // --- *** INICIO DE MEJORAS DE ETIQUETAS *** ---
    
    // Crear formateadores de fecha (fuera del bucle por eficiencia)
    NSLocale *esLocale = [NSLocale localeWithLocaleIdentifier:@"es_ES"];
    
    NSDateFormatter *dateParserDiario = [[NSDateFormatter alloc] init];
    dateParserDiario.dateFormat = @"yyyy-MM-dd";
    
    NSDateFormatter *dateFormatterDiario = [[NSDateFormatter alloc] init];
    dateFormatterDiario.dateFormat = @"EEE dd"; // "lun. 27"
    dateFormatterDiario.locale = esLocale;

    NSDateFormatter *dateParserMensual = [[NSDateFormatter alloc] init];
    dateParserMensual.dateFormat = @"yyyy-MM";
    
    NSDateFormatter *dateFormatterMensual = [[NSDateFormatter alloc] init];
    dateFormatterMensual.dateFormat = @"MMMM"; // "octubre"
    dateFormatterMensual.locale = esLocale;


    CGFloat espacioEntreBarras = ancho / self.valores.count;
    CGFloat anchoBarra = MIN(30, espacioEntreBarras * 0.6);
    CGFloat margenX = (espacioEntreBarras - anchoBarra) / 2.0;

    for (NSInteger i = 0; i < self.valores.count; i++) {
        
        // --- 1. ETIQUETA DE FECHA (ABAJO) ---
        NSString *fechaOriginal = self.fechas[i];
        NSString *etiquetaFechaStr = @"";
        
        if (self.mostrarMes) {
            NSDate *fecha = [dateParserMensual dateFromString:fechaOriginal];
            if (fecha) {
                etiquetaFechaStr = [dateFormatterMensual stringFromDate:fecha];
            } else {
                etiquetaFechaStr = fechaOriginal; // Fallback
            }
        } else {
            NSDate *fecha = [dateParserDiario dateFromString:fechaOriginal];
            if (fecha) {
                etiquetaFechaStr = [dateFormatterDiario stringFromDate:fecha];
            } else {
                etiquetaFechaStr = [fechaOriginal substringFromIndex:5]; // Fallback
            }
        }
        
        // Dibujar etiqueta de fecha centrada
        CGFloat x = i * espacioEntreBarras;
        NSDictionary *attrsFecha = @{NSFontAttributeName:[NSFont systemFontOfSize:8]};
        NSSize textSizeFecha = [etiquetaFechaStr sizeWithAttributes:attrsFecha];
        [etiquetaFechaStr drawAtPoint:NSMakePoint(x + (espacioEntreBarras - textSizeFecha.width) / 2.0, 5) withAttributes:attrsFecha];
        
        
        // --- 2. ETIQUETA DE VALOR Y PORCENTAJE (ARRIBA) ---
        double valor = [self.valores[i] doubleValue];
        if (valor > 0) {
            CGFloat altura = (valor / max) * altoGrafica;
            CGFloat xValor = i * espacioEntreBarras + margenX;
            
            NSString *textoValor = [NSString stringWithFormat:@"%.0f", valor];
            NSString *textoPorcentaje = @"";
            
            // Calcular porcentaje si hay un umbral rojo
            if (self.umbralRojo > 0) {
                double porcentaje = (valor / self.umbralRojo) * 100.0;
                textoPorcentaje = [NSString stringWithFormat:@" (%.0f%%)", porcentaje];
            }
            
            // Combinar valor y porcentaje
            NSString *etiquetaSuperior = [NSString stringWithFormat:@"%@%@", textoValor, textoPorcentaje];
            
            NSDictionary *attrsValor = @{NSFontAttributeName:[NSFont systemFontOfSize:9]};
            NSSize textSizeValor = [etiquetaSuperior sizeWithAttributes:attrsValor];
            [etiquetaSuperior drawAtPoint:NSMakePoint(xValor + (anchoBarra - textSizeValor.width) / 2.0, yBase + altura + 2)
                         withAttributes:attrsValor];
        }
    }
    // --- *** FIN DE MEJORAS DE ETIQUETAS *** ---
}


// --- ('viewDidEndLiveResize' no cambia) ---
- (void)viewDidEndLiveResize {
    [super viewDidEndLiveResize];
    [self layoutBarLayersAnimated:NO]; // Reajustar sin animación
    [self setNeedsDisplay:YES];
}

@end
