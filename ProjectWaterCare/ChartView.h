#import <Cocoa/Cocoa.h>

@interface ChartView : NSView

@property (nonatomic, strong) NSArray<NSString *> *fechas;
@property (nonatomic, strong) NSArray<NSNumber *> *valores;
@property (nonatomic) BOOL mostrarMes;
@property (nonatomic) double umbral;

// Método público para actualizar la gráfica
- (void)actualizarConFechas:(NSArray<NSString *> *)fechas
                    valores:(NSArray<NSNumber *> *)valores
                 mostrarMes:(BOOL)mes;

@end
