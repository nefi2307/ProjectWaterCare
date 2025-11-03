#import "ViewController.h"

@implementation ViewController

#pragma mark - Inicialización

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"consumoAgua"];
    self.consumoPorFecha = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    
    [self.datePicker setDateValue:[NSDate date]];
    
    // Establecer umbrales diarios por defecto
    self.chartView.umbralRojo = 200.0;
    self.chartView.umbralAmarillo = 150.0; // (ej. 75% del rojo)
    
    // Usar 'NRegistros' para mostrar los últimos 7 con datos (incluye futuros)
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
    
    // Inicializa el arreglo de recomendaciones
        self.recomendacionesAgua = @[
            @"Cierra la llave mientras te cepillas los dientes. Puedes ahorrar hasta 10 litros.",
            @"Toma duchas más cortas. ¡Cada minuto menos cuenta!",
            @"Revisa que no tengas fugas en llaves o inodoros. Una pequeña fuga puede desperdiciar cientos de litros.",
            @"Junta el agua fría de la regadera en una cubeta mientras esperas que salga la caliente. Úsala para regar plantas.",
            @"Usa la lavadora solo con cargas completas de ropa."
        ];
    
}

#pragma mark - Botones

- (IBAction)btnRegistrar:(id)sender {
    double litros = self.txtLitros.doubleValue;
    if (litros <= 0) {
        self.lblMensaje.stringValue = @"Ingrese una cantidad válida de litros.";
        return;
    }
    
    NSString *fechaClave = [self formatearFecha:self.datePicker.dateValue];
    
    NSNumber *valorAnterior = self.consumoPorFecha[fechaClave];
    double nuevoValor = valorAnterior ? valorAnterior.doubleValue + litros : litros;
    self.consumoPorFecha[fechaClave] = @(nuevoValor);
    
    [[NSUserDefaults standardUserDefaults] setObject:self.consumoPorFecha forKey:@"consumoAgua"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.lblMensaje.stringValue = [NSString stringWithFormat:@"Registrado %.1f L el %@", litros, fechaClave];
    
    // Re-establecer umbrales diarios
    self.chartView.umbralRojo = 200.0;
    self.chartView.umbralAmarillo = 150.0;
    
    // Usar 'NRegistros' para que el nuevo registro (incluso futuro) aparezca
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

- (IBAction)btnVerSemana:(id)sender {
    // Establecer umbrales diarios
    self.chartView.umbralRojo = 200.0;
    self.chartView.umbralAmarillo = 150.0;
    
    // Usar 'NDias' para forzar la vista de los últimos 7 días del CALENDARIO
    [self actualizarGraficaUltimosNDias:7];
}

- (IBAction)btnVerMes:(id)sender {
    // Establecer umbrales mensuales
    self.chartView.umbralRojo = 6000.0;
    self.chartView.umbralAmarillo = 4500.0;
    [self actualizarGraficaPorMes];
}

- (IBAction)mostrarRecomendacion:(id)sender {
    
    // 1. Elige un índice aleatorio
    uint32_t indiceAleatorio = arc4random_uniform((uint32_t)self.recomendacionesAgua.count);
    
    // 2. Obtiene la recomendación
    NSString *recomendacion = self.recomendacionesAgua[indiceAleatorio];
    
    // 3. Muestra una alerta (pop-up)
    NSAlert *alerta = [[NSAlert alloc] init];
    [alerta setMessageText:@"¡Recomendación para Cuidar el Agua!"];
    [alerta setInformativeText:recomendacion];
    [alerta addButtonWithTitle:@"¡Entendido!"];
    
    // *** LA CORRECCIÓN ESTÁ AQUÍ ***
    // 1. Comenta o elimina esta línea, que es la que fuerza el espacio para el ícono
    // [alerta setAlertStyle:NSAlertStyleInformational];
    
    // 2. Esta línea ahora sí funcionará para quitar el ícono por defecto
    [alerta setIcon:nil];
    
    [alerta runModal]; // Muestra la alerta
}

- (IBAction)btnLimpiarDatos:(id)sender {
    [self.consumoPorFecha removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"consumoAgua"];
    self.lblMensaje.stringValue = @"Datos limpiados.";
    
    // Re-establecer umbrales diarios
    self.chartView.umbralRojo = 200.0;
    self.chartView.umbralAmarillo = 150.0;
    
    // Usar 'NRegistros' para limpiar la gráfica
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

#pragma mark - Lógica

- (NSString *)formatearFecha:(NSDate *)fecha {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                    fromDate:fecha];
    NSDate *fechaNormalizada = [cal dateFromComponents:comp];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone localTimeZone];
    return [formatter stringFromDate:fechaNormalizada];
}

- (NSDictionary<NSString*, NSNumber*> *)consumoPorMes {
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM";
    
    NSDateFormatter *dfFull = [[NSDateFormatter alloc] init];
    dfFull.dateFormat = @"yyyy-MM-dd";
    
    for (NSString *clave in self.consumoPorFecha) {
        NSDate *fecha = [dfFull dateFromString:clave];
        if (!fecha) continue;
        
        NSString *mes = [df stringFromDate:fecha];
        NSNumber *litros = self.consumoPorFecha[clave];
        double litrosActual = litros.doubleValue;
        
        double valorActual = [res[mes] doubleValue];
        res[mes] = @(valorActual + litrosActual);
    }
    return res;
}

- (void)actualizarGraficaPorMes {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSInteger anioActual = [[cal components:NSCalendarUnitYear fromDate:[NSDate date]] year];
    
    NSMutableArray *meses = [NSMutableArray array];
    NSMutableArray *valores = [NSMutableArray array];
    
    NSDateFormatter *dfClave = [[NSDateFormatter alloc] init];
    dfClave.dateFormat = @"yyyy-MM-dd";
    
    for (int m = 1; m <= 12; m++) {
        NSString *claveMes = [NSString stringWithFormat:@"%04d-%02d", (int)anioActual, m];
        double totalMes = 0;
        
        for (NSString *clave in self.consumoPorFecha) {
            NSDate *fecha = [dfClave dateFromString:clave];
            if (!fecha) continue;
            
            NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:fecha];
            if (comp.year == anioActual && comp.month == m) {
                totalMes += [self.consumoPorFecha[clave] doubleValue];
            }
        }
        
        if (totalMes > 0) { // solo barras con datos
            [meses addObject:claveMes];
            [valores addObject:@(totalMes)];
        }
    }
    
    [self.chartView actualizarConFechas:meses valores:valores mostrarMes:YES];
}

- (void)actualizarGraficaUltimosNRegistros:(NSInteger)n {
    // Toma todas las fechas guardadas y las ordena
    NSArray *fechasOrdenadas = [[self.consumoPorFecha allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    if (fechasOrdenadas.count == 0) {
        [self.chartView actualizarConFechas:@[] valores:@[] mostrarMes:NO];
        return;
    }
    
    // Toma las últimas N fechas del arreglo ordenado
    NSArray *ultimosN = [fechasOrdenadas subarrayWithRange:NSMakeRange(MAX((int)fechasOrdenadas.count - (int)n, 0), MIN(n, fechasOrdenadas.count))];
    
    NSMutableArray *valores = [NSMutableArray array];
    for (NSString *fecha in ultimosN) {
        [valores addObject:self.consumoPorFecha[fecha]];
    }
    
    [self.chartView actualizarConFechas:ultimosN valores:valores mostrarMes:NO];
}

- (void)actualizarResumen {
    NSArray *ultimos7 = [self ultimosDias:7];
    double total = 0;
    int diasConDatos = 0;
    
    for (NSString *f in ultimos7) {
        NSNumber *v = self.consumoPorFecha[f];
        if (v) {
            total += v.doubleValue;
            diasConDatos++;
        }
    }
    
    double promedio = diasConDatos > 0 ? total / diasConDatos : 0;
    
    // *** INICIO DE LA MEJORA VISUAL ***
    NSString *icono = @"";
    if (diasConDatos > 0) { // Solo mostrar icono si hay datos
        if (promedio >= 200.0) { // Umbral diario rojo
            icono = @"⚠️";
        } else if (promedio >= 150.0) { // Umbral diario amarillo
            icono = @"😐";
        } else {
            icono = @"👍";
        }
    }
    
    // Lógica para mostrar u ocultar el botón ⚠️
        if (promedio >= 150.0) { // Si el promedio supera el umbral amarillo
            self.btnRecomendacion.hidden = NO; // ¡Muéstralo!
        } else {
            self.btnRecomendacion.hidden = YES; // Ocúltalo
        }
    
    // *** FIN DE LA MEJORA VISUAL ***

    self.lblTotal.stringValue = [NSString stringWithFormat:@"Total (7 días): %.1f L", total];
    
    // Añadir el icono al texto
    self.lblPromedio.stringValue = [NSString stringWithFormat:@"Promedio diario: %.1f L %@", promedio, icono];
}

- (NSArray<NSString *> *)ultimosDias:(NSInteger)dias {
    NSMutableArray *fechas = [NSMutableArray array];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *hoy = [NSDate date];
    
    for (NSInteger i = dias - 1; i >= 0; i--) {
        NSDate *fecha = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:hoy options:0];
        [fechas addObject:[self formatearFecha:fecha]];
    }
    return fechas;
}

- (void)actualizarGraficaUltimosNDias:(NSInteger)dias {
    NSMutableArray *fechas = [NSMutableArray array];
    NSMutableArray *valores = [NSMutableArray array];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *hoy = [NSDate date];
    
    for (NSInteger i = dias - 1; i >= 0; i--) {
        NSDate *fecha = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:hoy options:0];
        NSString *clave = [self formatearFecha:fecha];
        [fechas addObject:clave];
        NSNumber *v = self.consumoPorFecha[clave];
        [valores addObject:v ?: @0]; // Añade 0 si no hay registro
    }
    
    [self.chartView actualizarConFechas:fechas valores:valores mostrarMes:NO];
}

@end
