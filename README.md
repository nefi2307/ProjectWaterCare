# CuidAgua 💧

**Aplicación de macOS para registro y visualización del consumo de agua**  
Permite a los usuarios registrar el consumo diario de agua, visualizar su comportamiento en una gráfica (semanal o mensual) y reflexionar sobre su hábito de uso.

---

## Funcionalidades principales

- Registro de litros de agua por fecha, acumulando si ya existía un valor para ese día.  
- Persistencia ligera con `UserDefaults` para mantener el histórico entre ejecuciones.  
- Vista semanal: últimos N días (configurable) con gráfica de barras coloreada según nivel de consumo.  
- Vista mensual: agrupación por mes, sumando litros y mostrando tendencias mensuales.  
- `ChartView` personalizado (`NSView`) que dibuja la gráfica de barras, etiquetas, línea de umbral, colores dinámicos (verde/amarillo/rojo) según consumo.  
- Interfaz simple y directa: selector de fecha, campo de litros, botones *Registrar*, *Ver Semana*, *Ver Mes*, *Limpiar Datos*.  
- Código en Objective-C (archivos `.h` y `.m`) organizados para claridad, mantenibilidad y extensión futura.

---

## Instalación y uso

1. Abre el proyecto en Xcode (macOS, lenguaje Objective-C).  
2. Compila y ejecuta en un Mac (no en iOS).  
3. En la ventana principal:  
   - Selecciona la fecha deseada (por defecto aparece la fecha actual).  
   - Ingresa la cantidad de litros de agua consumidos.  
   - Pulsa **Registrar** para acumular el valor del día seleccionado.  
   - Pulsa **Ver Semana** para mostrar el gráfico de los últimos N días.  
   - Pulsa **Ver Mes** para mostrar el gráfico acumulado por mes.  
   - Pulsa **Limpiar Datos** para borrar todo el historial.

---

## Estructura de archivos
CuidAgua/

├── AppDelegate.h

├── AppDelegate.m

├── ChartView.h

├── ChartView.m

├── ViewController.h

└── ViewController.m


- **ChartView.h/.m**: clase personalizada que dibuja el gráfico de barras.  
- **ViewController.h/.m**: controlador principal que gestiona la interfaz, persistencia de datos, lógica de registro y cambio de vista.  
- **AppDelegate.h/.m**: delegado de la aplicación, configuración mínima ya que la lógica principal está en el `ViewController`.

---

¡Gracias por usar **CuidAgua**! 💧  

