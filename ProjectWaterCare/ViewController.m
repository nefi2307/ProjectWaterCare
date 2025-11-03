// ViewController.m

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // ✅ Inicializamos el diccionario desde UserDefaults
    NSDictionary *saved = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"consumoAgua"];
    self.consumoPorFecha = saved ? [saved mutableCopy] : [NSMutableDictionary dictionary];
    
    // ✅ Fecha por defecto: hoy
    [self.datePicker setDateValue:[NSDate date]];
    
    // ✅ Mostrar la gráfica inicial
    [self actualizarGraficaConUltimosDias:7];
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
    
    // Si ya hay consumo en ese día, se puede reemplazar o sumar
    NSNumber *valorAnterior = self.consumoPorFecha[fechaClave];
    double nuevoValor = valorAnterior ? valorAnterior.doubleValue + litros : litros;
    self.consumoPorFecha[fechaClave] = @(nuevoValor);
    
    // Guardar en persistencia
    [[NSUserDefaults standardUserDefaults] setObject:self.consumoPorFecha forKey:@"consumoAgua"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.lblMensaje.stringValue = [NSString stringWithFormat:@"Registrado %.1f L el %@", litros, fechaClave];
    
    // Actualizar gráfica y resumen
    [self actualizarGraficaConUltimosDias:7];
    [self actualizarResumen];
}


- (IBAction)btnVerSemana:(id)sender {
    [self actualizarGraficaConUltimosDias:7];
}

- (IBAction)btnVerMes:(id)sender {
    [self actualizarGraficaConUltimosDias:30];
}

- (IBAction)btnLimpiarDatos:(id)sender {
    [self.consumoPorFecha removeAllObjects];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"consumoAgua"];
    self.lblMensaje.stringValue = @"Datos limpiados.";
    [self actualizarGraficaConUltimosDias:7];
    [self actualizarResumen];
}

#pragma mark - Lógica

// ⚙️ Devuelve la fecha normalizada como “yyyy-MM-dd”
- (NSString *)formatearFecha:(NSDate *)fecha {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return [formatter stringFromDate:fecha];
}

// ⚙️ Devuelve un arreglo con los últimos N días (como cadenas “yyyy-MM-dd”)
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

// ✅ Actualiza la gráfica con los últimos N días
- (void)actualizarGraficaConUltimosDias:(NSInteger)dias {
    // Obtener todas las fechas registradas
    NSArray *todasFechas = [[self.consumoPorFecha allKeys] sortedArrayUsingSelector:@selector(compare:)];
    
    NSMutableArray *fechasFiltradas = [NSMutableArray array];
    NSMutableArray *valoresFiltrados = [NSMutableArray array];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd";
    
    NSDate *hoy = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *limite = [cal dateByAddingUnit:NSCalendarUnitDay value:-dias+1 toDate:hoy options:0];
    
    for (NSString *fechaStr in todasFechas) {
        NSDate *f = [df dateFromString:fechaStr];
        if (!f) continue;
        if ([f compare:limite] != NSOrderedAscending) { // f >= limite
            [fechasFiltradas addObject:fechaStr];
            [valoresFiltrados addObject:self.consumoPorFecha[fechaStr]];
        }
    }
    
    // Si no hay registros en rango, llenar con 0 para mantener gráfico consistente
    if (fechasFiltradas.count == 0) {
        for (NSInteger i = 0; i < dias; i++) {
            NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:-dias+1+i toDate:hoy options:0];
            [fechasFiltradas addObject:[self formatearFecha:d]];
            [valoresFiltrados addObject:@0];
        }
    }
    
    [self.chartView actualizarConFechas:fechasFiltradas valores:valoresFiltrados];
}

// ✅ Calcula total y promedio semanal
- (void)actualizarResumen {
    // Considerar todas las fechas registradas para calcular promedio/total
    NSArray *todasFechas = [[self.consumoPorFecha allKeys] sortedArrayUsingSelector:@selector(compare:)];
    double total = 0;
    for (NSString *f in todasFechas) {
        total += [self.consumoPorFecha[f] doubleValue];
    }
    double promedio = todasFechas.count > 0 ? total / todasFechas.count : 0;
    
    self.lblTotal.stringValue = [NSString stringWithFormat:@"Total: %.1f L", total];
    self.lblPromedio.stringValue = [NSString stringWithFormat:@"Promedio diario: %.1f L", promedio];
}

@end
