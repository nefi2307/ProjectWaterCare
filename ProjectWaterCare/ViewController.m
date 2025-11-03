#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"consumoAgua"];
    self.consumoPorFecha = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    
    [self.datePicker setDateValue:[NSDate date]];
    
    // Por defecto, vista semanal
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

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
    
    // Actualizar vista semanal por defecto
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

- (IBAction)btnVerSemana:(id)sender {
    self.chartView.umbral = 200.0; // umbral diario recomendado
    [self actualizarGraficaUltimosNDias:7];
}

- (IBAction)btnVerMes:(id)sender {
    self.chartView.umbral = 6000.0; // umbral mensual recomendado
    [self actualizarGraficaPorMes];
}

- (IBAction)btnLimpiarDatos:(id)sender {
    [self.consumoPorFecha removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"consumoAgua"];
    self.lblMensaje.stringValue = @"Datos limpiados.";
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

// --- Formato y lógica ---
- (NSString *)formatearFecha:(NSDate *)fecha {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:fecha];
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
        double litros = [self.consumoPorFecha[clave] doubleValue];
        double valorActual = [res[mes] doubleValue];
        res[mes] = @(valorActual + litros);
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
            if (comp.year == anioActual && comp.month == m)
                totalMes += [self.consumoPorFecha[clave] doubleValue];
        }
        [meses addObject:claveMes];
        [valores addObject:@(totalMes)];
    }
    [self.chartView actualizarConFechas:meses valores:valores mostrarMes:YES];
}

- (void)actualizarGraficaUltimosNRegistros:(NSInteger)n {
    NSArray *fechasOrdenadas = [[self.consumoPorFecha allKeys] sortedArrayUsingSelector:@selector(compare:)];
    if (fechasOrdenadas.count == 0) {
        [self.chartView actualizarConFechas:@[] valores:@[] mostrarMes:NO];
        return;
    }
    
    NSArray *ultimosN = [fechasOrdenadas subarrayWithRange:NSMakeRange(MAX((int)fechasOrdenadas.count - (int)n, 0), MIN(n, fechasOrdenadas.count))];
    NSMutableArray *valores = [NSMutableArray array];
    for (NSString *fecha in ultimosN) [valores addObject:self.consumoPorFecha[fecha]];
    [self.chartView actualizarConFechas:ultimosN valores:valores mostrarMes:NO];
}

- (void)actualizarResumen {
    NSArray *ultimos7 = [self ultimosDias:7];
    double total = 0;
    int diasConDatos = 0;
    for (NSString *f in ultimos7) {
        NSNumber *v = self.consumoPorFecha[f];
        if (v) { total += v.doubleValue; diasConDatos++; }
    }
    double promedio = diasConDatos > 0 ? total / diasConDatos : 0;
    self.lblTotal.stringValue = [NSString stringWithFormat:@"Total (7 días): %.1f L", total];
    self.lblPromedio.stringValue = [NSString stringWithFormat:@"Promedio diario: %.1f L", promedio];
}

- (NSArray<NSString *> *)ultimosDias:(NSInteger)dias {
    NSMutableArray *fechas = [NSMutableArray array];
    NSDate *hoy = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    for (NSInteger i = dias - 1; i >= 0; i--) {
        NSDate *fecha = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:hoy options:0];
        [fechas addObject:[self formatearFecha:fecha]];
    }
    return fechas;
}

- (void)actualizarGraficaUltimosNDias:(NSInteger)dias {
    NSMutableArray *fechas = [NSMutableArray array];
    NSMutableArray *valores = [NSMutableArray array];
    NSDate *hoy = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    for (NSInteger i = dias - 1; i >= 0; i--) {
        NSDate *fecha = [cal dateByAddingUnit:NSCalendarUnitDay value:-i toDate:hoy options:0];
        NSString *clave = [self formatearFecha:fecha];
        [fechas addObject:clave];
        NSNumber *v = self.consumoPorFecha[clave];
        [valores addObject:v ?: @0];
    }
    [self.chartView actualizarConFechas:fechas valores:valores mostrarMes:NO];
}

@end
