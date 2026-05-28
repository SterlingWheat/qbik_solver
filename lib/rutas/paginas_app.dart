import 'package:get/get.dart';
import '../views/core/pantalla_bienvenida.dart';
import '../views/core/pantalla_menu_principal.dart';
import '../views/core/pantalla_configuracion.dart';
import '../views/herramientas/pantalla_cronometro.dart';
import '../views/herramientas/pantalla_estadisticas.dart';
import '../views/ingreso/pantalla_seleccion_ingreso.dart';
import '../views/ingreso/pantalla_ingreso_manual_2x2.dart';
import '../views/ingreso/pantalla_ingreso_manual_3x3.dart';
import '../views/ingreso/pantalla_escaner_2x2.dart';
import '../views/ingreso/pantalla_camara_2x2.dart';
import '../views/solucion/pantalla_solucion_pasos_2x2.dart';
import '../views/solucion/pantalla_solucion_pasos_3x3.dart';
import 'rutas_app.dart';

abstract class PaginasApp {
  static final paginas = [
    GetPage(
      name: RutasApp.bienvenida,
      page: () => const PantallaBienvenida(),
    ),
    GetPage(
      name: RutasApp.menuPrincipal,
      page: () => const PantallaMenuPrincipal(),
    ),
    GetPage(
      name: RutasApp.seleccionIngreso,
      // Recupera el String 'tipoCubo' enviado al navegar
      page: () => PantallaSeleccionIngreso(tipoCubo: Get.arguments as String),
    ),
    GetPage(
      name: RutasApp.configuracion,
      page: () => const PantallaConfiguracion(),
    ),
    GetPage(
      name: RutasApp.cronometro,
      page: () => const PantallaCronometro(),
    ),
    GetPage(
      name: RutasApp.estadisticas,
      page: () => const PantallaEstadisticas(),
    ),
    GetPage(
      name: RutasApp.ingresoManual2x2,
      page: () => const PantallaIngresoManual2x2(),
    ),
    GetPage(
      name: RutasApp.ingresoManual3x3,
      page: () => const PantallaIngresoManual3x3(),
    ),
    GetPage(
      name: RutasApp.escaner2x2,
      page: () => const PantallaEscaner2x2(),
    ),
    GetPage(
      name: RutasApp.camara2x2,
      // Recupera el String 'nombreCara' enviado desde el escáner
      page: () => PantallaCamara2x2(nombreCara: Get.arguments as String),
    ),
    GetPage(
      name: RutasApp.solucionPasos2x2,
      // Recupera el gestor de reproducción instanciado para el flujo de pasos
      page: () => PantallaSolucionPasos2x2(gestor: Get.arguments),
    ),
    GetPage(
      name: RutasApp.solucionPasos3x3,
      // Recupera el gestor de reproducción instanciado para el flujo de pasos
      page: () => PantallaSolucionPasos3x3(gestor: Get.arguments),
    ),
  ];
}