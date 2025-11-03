#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h> // <-- Importar QuartzCore

@interface ChartView : NSView

@property (nonatomic, strong) NSArray<NSString *> *fechas;
@property (nonatomic, strong) NSArray<NSNumber *> *valores;
@property (nonatomic) BOOL mostrarMes;

@property (nonatomic) double umbralRojo;
@property (nonatomic) double umbralAmarillo;

// *** CAMBIO: Nueva propiedad para guardar las capas de las barras ***
@property (nonatomic, strong) NSMutableArray<CALayer *> *barLayers;

// Método público para actualizar la gráfica
- (void)actualizarConFechas:(NSArray<NSString *> *)fechas
                     valores:(NSArray<NSNumber *> *)valores
                  mostrarMes:(BOOL)mes;

@end
