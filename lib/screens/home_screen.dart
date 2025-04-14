import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:compras_app/services/api_service.dart'; // Asegúrate que la ruta sea correcta
// Asegúrate que la ruta sea correcta
import 'package:compras_app/screens/details_screen.dart'; // Asegúrate que la ruta sea correcta
import 'package:flutter/services.dart'; // Para formatters

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>(); // Para validación de formulario
  final _rucController = TextEditingController();
  final _tipoController = TextEditingController();
  final _serieController = TextEditingController();
  final _numeroController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // Controlador para el scanner QR
  late MobileScannerController cameraController;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
    // Ya no se llama a _setTestValues() aquí
  }

  // --- Método _setTestValues eliminado ---

  @override
  void dispose() {
    _rucController.dispose();
    _tipoController.dispose();
    _serieController.dispose();
    _numeroController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _scanQR() {
    // Limpiar campos y errores antes de escanear
    setState(() {
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevenir que el usuario cierre el diálogo por accidente
      builder: (context) => AlertDialog(
        title: const Text('Escanear Código QR'),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String? code = barcodes.first.rawValue;
                  if (code != null) {
                    debugPrint("QR Detectado: $code");
                    // Detener cámara y cerrar diálogo ANTES de procesar
                    cameraController.stop();
                    Navigator.of(context).pop(); // Cierra el diálogo
                    _processQRData(code);
                  }
                }
              },
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.cancel),
            label: const Text('Cancelar'),
            onPressed: () {
              cameraController.stop();
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
        ],
      ),
    ).then((_) {
      // Asegurarse de que la cámara se detenga si el diálogo se cierra de otra forma
      cameraController.stop();
    });
  }

void _processQRData(String data) {
  // Limpiar espacios adicionales al inicio/fin
  data = data.trim();

  // Expresión regular mejorada para ser más flexible con el formato de QR
  // Ahora acepta datos adicionales después de los primeros 4 campos
  final regExp = RegExp(r'(\d{11})\s*\|\s*([a-zA-Z0-9]{1,2})\s*\|\s*([a-zA-Z0-9]+)\s*\|\s*(\d+)');
  final match = regExp.firstMatch(data);

  if (match != null) {
    final ruc = match.group(1)!;
    final tipo = match.group(2)!;
    final serie = match.group(3)!;
    final numero = match.group(4)!;

    // Quitar ceros a la izquierda del número si es necesario
    final numeroInt = int.tryParse(numero) ?? 0;
    final numeroFormateado = numeroInt.toString();

    setState(() {
      _rucController.text = ruc;
      _tipoController.text = tipo;
      _serieController.text = serie.toUpperCase(); // Convertir a mayúsculas
      _numeroController.text = numeroFormateado;
    });
    
    // Es importante resetear el formulario DESPUÉS de asignar los valores
    // Esta línea debe estar fuera del setState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.reset(); // Resetea el estado de validación
    });

    _showSuccessSnackbar('QR escaneado correctamente. Puede consultar la factura.');
    debugPrint("Datos QR procesados (RegExp): RUC=$ruc, Tipo=$tipo, Serie=$serie, Num=$numero");

  } else {
    // Intentar con el formato básico de separación por | si RegExp falla
    final parts = data.split('|');
    if (parts.length >= 4) {
      final ruc = parts[0].trim();
      final tipo = parts[1].trim();
      final serie = parts[2].trim();
      final numero = parts[3].trim();

      // Quitar ceros a la izquierda del número si es necesario
      final numeroInt = int.tryParse(numero) ?? 0;
      final numeroFormateado = numeroInt.toString();

      // Validación básica de las partes extraídas
      if (ruc.isNotEmpty && ruc.length == 11 && int.tryParse(ruc) != null &&
          tipo.isNotEmpty && tipo.length <= 2 &&
          serie.isNotEmpty &&
          numero.isNotEmpty && int.tryParse(numero) != null)
      {
        setState(() {
          _rucController.text = ruc;
          _tipoController.text = tipo;
          _serieController.text = serie.toUpperCase();
          _numeroController.text = numeroFormateado;
        });
        
        // Resetear el formulario después de asignar los valores
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _formKey.currentState?.reset(); // Resetea el estado de validación
        });
        
        _showSuccessSnackbar('QR escaneado correctamente. Puede consultar la factura.');
        debugPrint("Datos QR procesados (Split): RUC=$ruc, Tipo=$tipo, Serie=$serie, Num=$numero");
      } else {
        _showErrorSnackbar('Error: El QR contiene datos inválidos o incompletos.');
        debugPrint("Error procesando QR (Split): Datos inválidos. RUC='$ruc', Tipo='$tipo', Serie='$serie', Num='$numero'");
      }
    } else {
      _showErrorSnackbar('Error: El formato del QR no es válido. Formato esperado: RUC|TIPO|SERIE|NUMERO');
      debugPrint("Error procesando QR: Formato inválido. Contenido: $data");
    }
  }
}
  // Validación de campos usando el FormKey
  bool _validateFields() {
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      return true; // La validación pasó
    }
    _showErrorSnackbar('Por favor, corrija los errores en el formulario.');
    return false; // La validación falló
  }

  // Validador para el campo RUC
  String? _validateRuc(String? value) {
    if (value == null || value.isEmpty) {
      return 'El RUC es obligatorio';
    }
    if (value.length != 11) {
      return 'El RUC debe tener 11 dígitos';
    }
    if (int.tryParse(value) == null) {
      return 'El RUC debe contener solo números';
    }
    if (!value.startsWith('10') && !value.startsWith('20')) {
      return 'RUC inválido (debe iniciar con 10 o 20)';
    }
    return null; // Válido
  }

  // Validador para Tipo de Documento
  String? _validateTipo(String? value) {
     if (value == null || value.isEmpty) {
       return 'El tipo es obligatorio';
     }
     // Puedes añadir más validaciones si conoces los tipos válidos (ej: '01', '03', etc.)
     // if (!['01', '03', '07', '08'].contains(value)) {
     //   return 'Tipo inválido';
     // }
     return null;
  }

  // Validador para Serie
  String? _validateSerie(String? value) {
     if (value == null || value.isEmpty) {
       return 'La serie es obligatoria';
     }
     // Patrón común: Letra inicial (F/B) seguida de letras o números
     if (!RegExp(r'^[FB][A-Z0-9]+$', caseSensitive: false).hasMatch(value)) {
       return 'Formato inválido (Ej: F001, B001)';
     }
     return null;
  }

  // Validador para Número
  String? _validateNumero(String? value) {
     if (value == null || value.isEmpty) {
       return 'El número es obligatorio';
     }
     if (int.tryParse(value) == null || int.parse(value) <= 0) {
       return 'Debe ser un número positivo';
     }
     return null;
  }


Future<void> _fetchData() async {
  // Ocultar teclado
  FocusScope.of(context).unfocus();

  // Validar campos antes de continuar
  if (!_validateFields()) {
    return;
  }

  setState(() { _isLoading = true; });

  try {
    // Forzar validación antes de hacer la petición
    if (!_formKey.currentState!.validate()) {
      setState(() { _isLoading = false; });
      _showErrorSnackbar('Por favor, corrija los errores en el formulario.');
      return;
    }

    final invoiceData = await _apiService.fetchInvoiceData(
      ruc: _rucController.text.trim(),
      tipo: _tipoController.text.trim(),
      serie: _serieController.text.trim().toUpperCase(), // Asegurar mayúsculas
      numero: _numeroController.text.trim(),
    );

    // Verificar si la API devolvió datos significativos (ej: razón social)
    if (invoiceData.razonSocialProveedor.isEmpty && invoiceData.metadatos.ruc.isEmpty) {
       // Considerar esto como un caso de "no encontrado" aunque la API devuelva 200
       throw Exception('No se encontraron datos para la factura especificada.');
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(invoiceData: invoiceData),
        ),
      );
    }
  } catch (e) {
    debugPrint("Error capturado en _fetchData: $e");
    final errorMsg = e.toString().replaceFirst("Exception: ", "");
    _showErrorSnackbar('Error al consultar: $errorMsg');
  } finally {
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }
}

  void _clearForm() {
    _formKey.currentState?.reset(); // Resetea validaciones
    setState(() {
      _rucController.clear();
      _tipoController.clear();
      _serieController.clear();
      _numeroController.clear();
    });
    _showSuccessSnackbar('Formulario limpiado');
    FocusScope.of(context).unfocus(); // Ocultar teclado
  }

  // Helper para mostrar Snackbars de error/advertencia
  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remover snackbar anterior si existe
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(8), // Margen para floating
        ),
      );
    }
  }

  // Helper para mostrar Snackbars de éxito
  void _showSuccessSnackbar(String message) {
    if (mounted) {
       ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remover snackbar anterior si existe
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.green[700],
          duration: const Duration(seconds: 3), // Duración ligeramente mayor para éxito
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
           margin: const EdgeInsets.all(8), // Margen para floating
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultar Facturas'), // Título más acorde
        elevation: 1, // Sombra sutil
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined), // Icono más descriptivo
            tooltip: 'Limpiar formulario',
            onPressed: _isLoading ? null : _clearForm,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0), // Más padding superior
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Consulta facturas', // Texto más conciso
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Tarjeta para escaneo QR
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'Escanear código QR',
                           style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Capturar QR'),
                          onPressed: _isLoading ? null : _scanQR,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary, // Color secundario
                            foregroundColor: Theme.of(context).colorScheme.onSecondary,
                            minimumSize: const Size(double.infinity, 48), // Altura estándar
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Row( // Divisor con texto
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        'O ingresar datos',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // Campo RUC
                TextFormField(
                  controller: _rucController,
                  decoration: const InputDecoration(
                    labelText: 'RUC',
                    hintText: 'Ingrese los 11 dígitos',
                    prefixIcon: Icon(Icons.business_center_outlined), // Icono diferente
                    border: OutlineInputBorder(), // Borde estándar
                    counterText: "", // Ocultar contador de maxLength
                  ),
                  validator: _validateRuc,
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),

                const SizedBox(height: 16), // Espaciado consistente

                // Campo Tipo de Documento
                TextFormField(
                  controller: _tipoController,
                  decoration: const InputDecoration(
                    labelText: 'Tipo Doc.',
                    hintText: 'Ej: 01',
                    prefixIcon: Icon(Icons.article_outlined), // Icono diferente
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  validator: _validateTipo, // Usar validador específico
                  keyboardType: TextInputType.text,
                  maxLength: 2,
                  // Podrías usar un Dropdown si los tipos son fijos
                ),

                const SizedBox(height: 16),

                // Campo Serie
                TextFormField(
                  controller: _serieController,
                  decoration: const InputDecoration(
                    labelText: 'Serie',
                    hintText: 'Ej: F001',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  validator: _validateSerie, // Usar validador específico
                  keyboardType: TextInputType.text,
                  maxLength: 6, // Ajustar si es necesario
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    // Convertir a mayúsculas automáticamente
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      return TextEditingValue(
                        text: newValue.text.toUpperCase(),
                        selection: newValue.selection,
                      );
                    }),
                    // Permitir solo letras y números
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                ),

                const SizedBox(height: 16),

                // Campo Número
                TextFormField(
                  controller: _numeroController,
                  decoration: const InputDecoration(
                    labelText: 'Número',
                    hintText: 'Ej: 12345',
                    prefixIcon: Icon(Icons.numbers_outlined), // Icono diferente
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                  validator: _validateNumero, // Usar validador específico
                  keyboardType: TextInputType.number,
                  maxLength: 8, // Ajustar si es necesario
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),

                const SizedBox(height: 24),

                // Mensaje de error persistente (opcional, ya se muestra en Snackbar)
                // if (_errorMessage != null && !_isLoading)
                //   Container(
                //     padding: const EdgeInsets.all(12),
                //     margin: const EdgeInsets.only(bottom: 16),
                //     decoration: BoxDecoration(
                //       color: Colors.red[50],
                //       border: Border.all(color: Colors.red[200]!),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: Row(
                //       children: [
                //         Icon(Icons.error_outline, color: Colors.red[700]),
                //         const SizedBox(width: 12),
                //         Expanded(
                //           child: Text(
                //             _errorMessage!,
                //             style: TextStyle(color: Colors.red[700]),
                //           ),
                //         ),
                //       ],
                //     ),
                //   ),

                // Botón principal
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _fetchData,
                    icon: const Icon(Icons.search),
                    label: const Text('Consultar Factura'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      minimumSize: const Size(double.infinity, 50), // Altura mayor
                      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 16), // Texto más grande
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}