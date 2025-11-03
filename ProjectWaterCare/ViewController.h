#import <Cocoa/Cocoa.h>
#import "ChartView.h"

@interface ViewController : NSViewController

// Outlets
@property (weak) IBOutlet NSTextField *txtLitros;
@property (weak) IBOutlet NSDatePicker *datePicker;
@property (weak) IBOutlet NSTextField *lblTotal;
@property (weak) IBOutlet NSTextField *lblPromedio;
@property (weak) IBOutlet NSTextField *lblMensaje;
@property (weak) IBOutlet ChartView *chartView;
@property (weak) IBOutlet NSButton *btnRecomendacion;

// Botones
- (IBAction)btnRegistrar:(id)sender;
- (IBAction)btnVerSemana:(id)sender;
- (IBAction)btnVerMes:(id)sender;
- (IBAction)btnLimpiarDatos:(id)sender;
- (IBAction)mostrarRecomendacion:(id)sender;

// Lógica y persistencia
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSNumber*> *consumoPorFecha;

@property (nonatomic, strong) NSArray<NSString *> *recomendacionesAgua;

- (void)actualizarGraficaPorMes;

@end
