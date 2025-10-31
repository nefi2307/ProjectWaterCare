//
//  ViewController.h
//  ProjectWaterCare
//
//  Created by Isaac Burciaga on 31/10/25.
//

#import <Cocoa/Cocoa.h>
#import "ChartView.h"

//NS_ASSUME_NONNULL_BEGIN

@interface ViewController : NSViewController

// outlets
@property (weak) IBOutlet NSTextField *txtLitros; //entrada numérica (litros)
@property (weak) IBOutlet NSDatePicker *datePicker; // selecciona fecha
@property (weak) IBOutlet NSTextField *lblTotal; // muestra total (semana)
@property (weak) IBOutlet NSTextField *lblPromedio; // muestra promedio diario
@property (weak) IBOutlet NSTextField *lblMensaje; // alertas / recomendaciones
@property (weak) IBOutlet ChartView *chartView; // vista custom para graficar

// Botones
- (IBAction)btnRegistrar:(id)sender;
- (IBAction)btnVerSemana:(id)sender;
- (IBAction)btnVerMes:(id)sender;
- (IBAction)btnLimpiarDatos:(id)sender;

// --- Lógica y persistencia ---
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> *consumoPorFecha; // key: yyyy-MM-dd -> liters
@property (nonatomic) double umbral; // umbral diario para alerta

@end

