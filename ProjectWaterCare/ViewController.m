//
//  ViewController.m
//  ProjectWaterCare
//
//  Created by Isaac Burciaga on 31/10/25.
//

#import "ViewController.h"

@implementation ViewController

#pragma mark - Inicialización

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Umbral diario: valor configurable; ejemplo: 200 L/día
    self.umbral = 200.0;
    
    // Cargar valores guardados (NSUserDefaults)
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *saved = [defaults dictionaryForKey:@"consumoAgua"];
    if (saved) {
        // mutable copy para modificar
        self.consumoPorFecha = [saved mutableCopy];
    } else {
        self.consumoPorFecha = [NSMutableDictionary dictionary];
    }
    
    // Set defaults UI
    self.datePicker.dateValue = [NSDate date];
    self.lblMensaje.stringValue = @"Bienvenido. Registra tu consumo diario de agua.";
    
    // Mostrar datos iniciales
    [self mostrarUltimaSemana];
    [self actualizarResumenUI];
}

#pragma mark - Utilidades (formateo de fecha / persistencia)

// Convierte NSDate -> "yyyy-MM-dd" para usar como key en diccionario
- (NSString*)keyForDate:(NSDate*)date {
    static NSDateFormatter *df = nil;
    if (!df) {
        df = [[NSDateFormatter alloc] init];
        df.dateFormat = @"yyyy-MM-dd";
        df.locale = [NSLocale currentLocale];
    }
    return [df stringFromDate:date];
}

// Guarda consumoPorFecha en NSUserDefaults
- (void)guardarDatos {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.consumoPorFecha forKey:@"consumoAgua"];
    [defaults synchronize];
}

#pragma mark - Acciones UI

// Registro de consumo para la fecha seleccionada
- (IBAction)btnRegistrar:(id)sender {
    // leer litros desde NSTextField (doubleValue)
    double litros = [self.txtLitros doubleValue];
    NSDate *fecha = self.datePicker.dateValue;
    NSString *key = [self keyForDate:fecha];
    
    // Validaciones
    if (litros < 0) {
        self.lblMensaje.stringValue = @"Error: el valor de litros no puede ser negativo.";
        return;
    }
    if (litros == 0) {
        // Permitimos 0, pero avisamos
        self.lblMensaje.stringValue = @"Registro: 0 L (puedes eliminar o actualizar si fue un error).";
    }
    
    // Guardar en memoria y persistencia
    self.consumoPorFecha[key] = @(litros);
    [self guardarDatos];
    
    // Mensaje y alerta si supera umbral
    if (litros > self.umbral) {
        self.lblMensaje.stringValue = [NSString stringWithFormat:@"Alerta: consumo alto (%.1f L) > umbral (%.1f L). Recomendaciones disponibles.", litros, self.umbral];
    } else {
        self.lblMensaje.stringValue = [NSString stringWithFormat:@"Consumo registrado: %.1f L para %@", litros, key];
    }
    
    // Actualizar UI: resumen y gráfico
    [self actualizarResumenUI];
    [self mostrarUltimaSemana];
}

// Mostrar consumo de la última semana (7 días)
- (IBAction)btnVerSemana:(id)sender {
    [self mostrarUltimaSemana];
}

// Mostrar consumo del último mes (30 días)
- (IBAction)btnVerMes:(id)sender {
    [self mostrarUltimoMes];
}

// Eliminar todos los datos con confirmación
- (IBAction)btnLimpiarDatos:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Confirmar eliminación";
    alert.informativeText = @"¿Desea eliminar todos los registros de consumo? Esta acción no se puede deshacer.";
    [alert addButtonWithTitle:@"Eliminar"];
    [alert addButtonWithTitle:@"Cancelar"];
    NSModalResponse resp = [alert runModal];
    if (resp == NSAlertFirstButtonReturn) {
        [self.consumoPorFecha removeAllObjects];
        [self guardarDatos];
        self.lblMensaje.stringValue = @"Datos eliminados.";
        [self actualizarResumenUI];
        [self mostrarUltimaSemana];
    }
}

#pragma mark - Rango de fechas y preparación de series

// Devuelve un arreglo de keys (yyyy-MM-dd) para los últimos N días (orden cronológico ascendente)
- (NSArray<NSString*>*)datesForLastNDays:(NSInteger)days {
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:days];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDate *today = [NSDate date];
    // Construimos el rango desde (today - days + 1) hasta today
    for (NSInteger i = 0; i < days; i++) {
        NSDate *d = [cal dateByAddingUnit:NSCalendarUnitDay value:-(days-1-i) toDate:today options:0];
        [arr addObject:[self keyForDate:d]];
    }
    return arr;
}

// Mostrar última semana (7 días)
- (void)mostrarUltimaSemana {
    NSArray *keys = [self datesForLastNDays:7];
    NSMutableArray<NSNumber*> *values = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString *k in keys) {
        NSNumber *v = self.consumoPorFecha[k];
        if (v) [values addObject:v]; else [values addObject:@0];
    }
    // Pasar datos a ChartView para dibujar
    [self.chartView setLabels:keys values:values];
    [self.chartView setNeedsDisplay:YES];
}

// Mostrar último mes (30 días)
- (void)mostrarUltimoMes {
    NSArray *keys = [self datesForLastNDays:30];
    NSMutableArray<NSNumber*> *values = [NSMutableArray arrayWithCapacity:keys.count];
    for (NSString *k in keys) {
        NSNumber *v = self.consumoPorFecha[k];
        if (v) [values addObject:v]; else [values addObject:@0];
    }
    [self.chartView setLabels:keys values:values];
    [self.chartView setNeedsDisplay:YES];
}

#pragma mark - Resumen (total y promedio)

// Calcular y actualizar total y promedio de la última semana
- (void)actualizarResumenUI {
    NSArray *keys = [self datesForLastNDays:7];
    double suma = 0;
    int diasConDato = 0;
    for (NSString *k in keys) {
        NSNumber *v = self.consumoPorFecha[k];
        if (v) { suma += [v doubleValue]; diasConDato++; }
    }
    double promedio = (diasConDato>0) ? (suma / diasConDato) : 0.0;
    self.lblTotal.stringValue = [NSString stringWithFormat:@"Total últimos %lu días: %.1f L", (unsigned long)keys.count, suma];
    self.lblPromedio.stringValue = [NSString stringWithFormat:@"Promedio diario: %.1f L", promedio];
}
@end
