//
//  ViewController.m
//  ProjectWaterCare
//
//  Creado por Isaac Burciaga
//

#import "ViewController.h"

@implementation ViewController

#pragma mark - Inicialización

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Inicializar diccionario desde UserDefaults
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"consumoAgua"];
    self.consumoPorFecha = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    
    // Fecha por defecto: hoy
    [self.datePicker setDateValue:[NSDate date]];
    
    // Mostrar datos iniciales
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

#pragma mark - Botones

- (IBAction)btnRegistrar:(id)sender {
    double litros = self.txtLitros.doubleValue;
    if (litros <= 0) {
        self.lblMensaje.stringValue = @"Ingrese una cantidad válida de litros.";
        return;
    }
    
    NSString *fechaClave = [self formatearFecha:self.datePicker.dateValue];
    
    // Acumular consumo si ya hay valor
    NSNumber *valorAnterior = self.consumoPorFecha[fechaClave];
    double nuevoValor = valorAnterior ? valorAnterior.doubleValue + litros : litros;
    self.consumoPorFecha[fechaClave] = @(nuevoValor);
    
    // Guardar en persistencia
    [[NSUserDefaults standardUserDefaults] setObject:self.consumoPorFecha forKey:@"consumoAgua"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.lblMensaje.stringValue = [NSString stringWithFormat:@"Registrado %.1f L el %@", litros, fechaClave];
    
    // Actualizar gráfica y resumen
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

- (IBAction)btnVerSemana:(id)sender {
    [self actualizarGraficaUltimosNDias:7];
}

- (IBAction)btnVerMes:(id)sender {
    [self actualizarGraficaPorMes];
}


- (IBAction)btnLimpiarDatos:(id)sender {
    [self.consumoPorFecha removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"consumoAgua"];
    self.lblMensaje.stringValue = @"Datos limpiados.";
    
    [self actualizarGraficaUltimosNRegistros:7];
    [self actualizarResumen];
}

#pragma mark - Lógica

// Formatea fecha como yyyy-MM-dd
- (NSString *)formatearFecha:(NSDate *)fecha {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                    fromDate:fecha];
    NSDate *fechaNormalizada = [cal dateFromComponents:comp]; // hora 00:00
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone localTimeZone]; // usa zona local
    return [formatter stringFromDate:fechaNormalizada];
}

#pragma mark - Agrupación por mes

// Agrupa consumo por mes y actualiza gráfica
- (NSDictionary<NSString*, NSNumber*> *)consumoPorMes {
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM"; // solo año-mes
    
    NSDateFormatter *dfFull = [[NSDateFormatter alloc] init];
    dfFull.dateFormat = @"yyyy-MM-dd";
    
    for (NSString *clave in self.consumoPorFecha) {
        NSDate *fecha = [dfFull dateFromString:clave];
        if (!fecha) continue;
        
        NSString *mes = [df stringFromDate:fecha]; // yyyy-MM
        NSNumber *litros = self.consumoPorFecha[clave];
        double litrosActual = 0.0;
        if ([litros isKindOfClass:[NSNumber class]]) {
            litrosActual = litros.doubleValue;
        } else if ([litros isKindOfClass:[NSString class]]) {
            litrosActual = [litros doubleValue];
        }
        
        double valorActual = 0.0;
        id val = res[mes];
        if ([val isKindOfClass:[NSNumber class]]) {
            valorActual = [val doubleValue];
        } else if ([val isKindOfClass:[NSString class]]) {
            valorActual = [val doubleValue];
        }
        
        res[mes] = @(valorActual + litrosActual);
    }
    return res;
}

#pragma mark - Agrupación por mes (12 meses del año actual)

- (void)actualizarGraficaPorMes {
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *compHoy = [cal components:(NSCalendarUnitYear) fromDate:[NSDate date]];
    NSInteger anioActual = compHoy.year;
    
    NSMutableArray *meses = [NSMutableArray array];
    NSMutableArray *valores = [NSMutableArray array];
    
    NSDateFormatter *dfClave = [[NSDateFormatter alloc] init];
    dfClave.dateFormat = @"yyyy-MM-dd";
    
    NSDateFormatter *dfMes = [[NSDateFormatter alloc] init];
    dfMes.dateFormat = @"yyyy-MM"; // para agrupar
    
    for (int m = 1; m <= 12; m++) {
        NSString *claveMes = [NSString stringWithFormat:@"%04d-%02d", (int)anioActual, m];
        double totalMes = 0;
        
        for (NSString *clave in self.consumoPorFecha) {
            NSDate *fecha = [dfClave dateFromString:clave];
            if (!fecha) continue;
            
            NSDateComponents *comp = [cal components:(NSCalendarUnitYear | NSCalendarUnitMonth) fromDate:fecha];
            if (comp.year == anioActual && comp.month == m) {
                NSNumber *litros = self.consumoPorFecha[clave];
                if (litros) totalMes += litros.doubleValue;
            }
        }
        [meses addObject:claveMes];         // yyyy-MM
        [valores addObject:@(totalMes)];    // total litros del mes
    }
    
    [self.chartView actualizarConFechas:meses valores:valores];
}



// Actualiza gráfica usando los últimos N registros con datos (Opción 2)
- (void)actualizarGraficaUltimosNRegistros:(NSInteger)n {
    NSArray *fechasOrdenadas = [[self.consumoPorFecha allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    if (fechasOrdenadas.count == 0) {
        [self.chartView actualizarConFechas:@[] valores:@[]];
        return;
    }
    
    NSArray *ultimosN = [fechasOrdenadas subarrayWithRange:NSMakeRange(MAX((int)fechasOrdenadas.count - (int)n, 0), MIN(n, fechasOrdenadas.count))];
    
    NSMutableArray *valores = [NSMutableArray array];
    for (NSString *fecha in ultimosN) {
        [valores addObject:self.consumoPorFecha[fecha]];
    }
    
    [self.chartView actualizarConFechas:ultimosN valores:valores];
}

// Calcula total y promedio de los últimos 7 días calendario
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
    
    self.lblTotal.stringValue = [NSString stringWithFormat:@"Total (7 días): %.1f L", total];
    self.lblPromedio.stringValue = [NSString stringWithFormat:@"Promedio diario: %.1f L", promedio];
}

// Devuelve los últimos N días calendario como yyyy-MM-dd
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

// Actualiza la gráfica usando los últimos N días calendario
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
        [valores addObject:v ?: @0]; // si no hay registro, ponemos 0
    }
    
    [self.chartView actualizarConFechas:fechas valores:valores];
}



@end
