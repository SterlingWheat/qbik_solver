import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Importaciones con la estructura de carpetas del proyecto
import 'gestores/globales/gestor_configuracion.dart';
import 'gestores/globales/gestor_estadisticas.dart';
import 'servicios/ia/servicio_ia_vision.dart';
import 'servicios/ia/servicio_gemini_vision.dart'; // 🔥 Nuevo servicio integrado
import 'rutas/rutas_app.dart';
import 'rutas/paginas_app.dart';

void main() async {
  // Garantiza que los canales de comunicación nativos estén listos antes de inicializaciones asíncronas
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Carga las variables de entorno (.env) para leer de forma segura la API Key de Gemini
    await dotenv.load(fileName: ".env");
    debugPrint("✅ Variables de entorno cargadas correctamente.");
  } catch (e) {
    debugPrint("🚨 Error al cargar el archivo de entorno .env: $e");
  }

  // 1. Inyectamos los Servicios (Permanecen en memoria durante toda la vida de la app)
  // Inicializa la carga en segundo plano de los modelos locales TensorFlow Lite / YOLOv8
  Get.put(ServicioIAVision()); 
  
  // 🔥 INYECCIÓN DE GEMINI: Registramos el cliente de la nube de manera global
  Get.put(ServicioGeminiVision());

  // 2. Inyectamos los Gestores Globales Reactivos
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