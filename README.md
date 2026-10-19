# Inventario Doméstico App (Foddie App)

Aplicación móvil desarrollada en **Flutter** con almacenamiento local en **SQLite** para la gestión eficiente del inventario de la alacena del hogar. Su principal objetivo es prevenir el desperdicio de alimentos mediante la trazabilidad de caducidades utilizando el criterio **FEFO** (*First Expired, First Out*), notificaciones locales, gestión de lotes y análisis de gastos.

---

## Características Principales

* **Control de Inventario y Lotes:** Seguimiento de existencias por producto y lotes individuales con fecha de vencimiento.
* **Criterio FEFO:** Descuento automático prioritario del lote que caduca más pronto.
* **Alertas y Notificaciones Locales:** Notificaciones programadas cuando un producto está próximo a caducar (7 días / 1 día) o tiene stock bajo/agotado.
* **Gestión de Tiendas e Historial de Compras:** Registro de compras relacionando producto, tienda de compra, costo unitario y lote.
* **Visualización de Estadísticas:** Gráficas interactivas de gastos acumulados por tienda y métricas globales.
* **Widgets Personalizados:**
  * `IndicadorNivelStock`: Barra visual de progreso para monitorear existencias.
  * `HojaConsumoRapido`: Modal desplegable para realizar consumos rápidos directo desde la pantalla principal.

---

## Capturas de Pantalla y Evidencias

###  Pantalla Principal e Indicadores de Stock
| Estado de Stock Bajo | Estado de Producto Agotado | Pantalla sin Alertas |
| :---: | :---: | :---: |
| <img src="evidencias/evidencia 3.jpeg" width="230"/> | <img src="evidencias/evidencia 8.jpeg" width="230"/> | <img src="evidencias/evidencia 10.jpeg" width="230"/> |

###  Consumo de Inventario y Notificaciones Locales
| Confirmación de Consumo FEFO | Notificación del Sistema Android | Prueba de Notificaciones |
| :---: | :---: | :---: |
| <img src="evidencias/evidencia 4.jpeg" width="230"/> | <img src="evidencias/evidencia 5.jpeg" width="230"/> | <img src="evidencias/evidencia 6.jpeg" width="230"/> |

###  Estadísticas del Inventario
| Módulo de Estadísticas y Gráfica por Tienda |
| :---: |
| <img src="evidencias/evidencia 1.jpeg" width="260"/> |

---

## 📁 Estructura del Proyecto

```text
lib/
├── components/                  # Widgets personalizados reutilizables
│   ├── food_tile.dart
│   ├── indicador_nivel_stock.dart   # Widget: Barra visual de nivel de stock
│   ├── hoja_consumo_rapido.dart     # Widget: Bottom Sheet para consumo FEFO
│   └── theme_provider.dart
├── data/                        # Repositorios y Helper SQLite
│   ├── alerta_repository.dart
│   ├── carrito_repository.dart
│   ├── categoria_repository.dart
│   ├── consumo_repository.dart
│   ├── database_helper.dart
│   ├── estadisticas_repository.dart
│   ├── historial_compras_repository.dart
│   ├── lote_repository.dart
│   ├── notificaciones_service.dart
│   ├── producto_repository.dart
│   └── tienda_repository.dart
├── models/                      # Modelos de datos
│   ├── categoria.dart
│   ├── lote.dart
│   ├── producto.dart
│   ├── status_articulo.dart
│   └── tienda.dart
├── pages/                       # Pantallas del flujo de navegación
│   ├── add_producto_page.dart
│   ├── calendario_page.dart
│   ├── carrito_page.dart
│   ├── categorias_page.dart
│   ├── consumo_page.dart
│   ├── estadisticas_page.dart
│   ├── historial_compras_page.dart
│   ├── inicio_page.dart
│   ├── lotes_page.dart
│   ├── productos_page.dart
│   └── tiendas_page.dart
└── main.dart                    # Punto de entrada de la aplicación

**Integraciones realizadas por el equipo:**
🔹 Jesús Alejandro Rojas Moreno

Base de Datos: Diseño, modelado y construcción de la base de datos local SQLite. Estructura del codigo DataBaseHelper para darle la implementacion del mapeo y conexiones entre objetos y llaves.

Modelos y Repositorios: Creación de los modelos de datos y repositorios para la interacción y persistencia de información.

Desarrollo de Pantallas y Flujos (UI/UX & Logic):

Diseñó e implementó la Página Principal (inicio_page.dart).

Gestión completa de Productos, Categorías y Lotes.

Pantalla de Consumo e Historial de Compras.

Administración de Tiendas y módulo de Estadísticas.

Alertas: Configuración e implementación del motor de alertas del sistema.

🔹 Dennis Adrián Quintana

Módulo de Calendario para monitoreo por fechas.

Cambio y reestructura de Modelos : reestructuración de Modelos para poder aplicar diversos metodos dentro de pages, y persistencia local en los repositorios
Desarrollo de Widgets Especializados:

StockStatusProgress: Widget para el cálculo dinámico y representación visual del stock disponible contra el stock mínimo (colores dinámicos y barras de progreso).

QuickConsumeSheet: Modal deslizante para el descuento inmediato de existencias bajo la regla de negocio FEFO con refresco dinámico de interfaz.

Integración de Componentes: Incorporación de acciones rápidas dentro de las tarjetas de alerta de la pantalla principal (InicioPage).

Sincronización de Servicios: Vinculación de los flujos de consumo rápido con el servicio de alertas (NotificacionesService) y actualización del estado de inventario en tiempo real.

Resolución de Errores de Entorno: Corrección de fallos de compilación nativa en Kotlin/Gradle

