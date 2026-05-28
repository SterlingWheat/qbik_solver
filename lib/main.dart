import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Importaciones con la nueva estructura de carpetas
import 'gestores/globales/gestor_configuracion.dart';
import 'gestores/globales/gestor_estadisticas.dart';
import 'servicios/ia/servicio_ia_vision.dart';
import 'rutas/rutas_app.dart';
import 'rutas/paginas_app.dart';

void main() {
  // 1. Inyectamos los Servicios (Viven durante toda la vida de la app)
  // Esto carga los modelos de IA de TensorFlow Lite en segundo plano
  Get.put(ServicioIAVision()); 

  // 2. Inyectamos los Gestores Globales
  Get.put(GestorConfiguracion());
  Get.put(GestorEstadisticas());
  
  runApp(const AplicacionCubo());
}

class AplicacionCubo extends StatelessWidget {
  const AplicacionCubo({super.key});

  @override
  Widget build(BuildContext context) {
    // Buscamos la instancia activa del gestor de configuración
    final gestorConfig = Get.find<GestorConfiguracion>();

    // Obx redibuja de forma eficiente y reactiva cuando cambia el tema
    return Obx(() {
      return GetMaterialApp(
        title: 'QBIK IA',
        debugShowCheckedModeBanner: false,
        
        // Configuración dinámica del tema accediendo al valor reactivo (.value)
        themeMode: gestorConfig.esTemaOscuro.value ? ThemeMode.dark : ThemeMode.light,
        
        // Esquema de Colores Claro
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.light,
          ),
        ),
        
        // Esquema de Colores Oscuro
        darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        
        // Implementación del sistema de rutas centralizado de GetX
        initialRoute: RutasApp.bienvenida,
        getPages: PaginasApp.paginas,
      );
    });
  }
}