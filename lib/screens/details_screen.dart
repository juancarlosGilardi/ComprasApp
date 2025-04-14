import 'package:flutter/material.dart';
import 'package:compras_app/models/invoice_model.dart';
import 'package:intl/intl.dart'; // Necesitarás agregar este paquete para formateo

class DetailsScreen extends StatelessWidget {
  final InvoiceData invoiceData;

  const DetailsScreen({
    super.key,
    required this.invoiceData,
  });

  @override
  Widget build(BuildContext context) {
    // Formatear moneda para mostrar importes
    final currencyFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: invoiceData.moneda == 'USD' ? '\$' : 'S/',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de Factura'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Compartir',
            onPressed: () {
              // Implementar compartir factura (puedes agregar esta funcionalidad después)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función compartir en desarrollo')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de información principal
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera con datos de documento
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "FACTURA ELECTRÓNICA",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${invoiceData.metadatos.serie}-${invoiceData.metadatos.numero}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "FECHA DE EMISIÓN",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  invoiceData.fechaEmision,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Datos del proveedor
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PROVEEDOR",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoiceData.razonSocialProveedor,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text("RUC: ", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(invoiceData.metadatos.ruc),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invoiceData.direccionProveedor,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const Divider(height: 32),
                      
                      // Fechas y moneda
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "FECHA VENCIMIENTO",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                invoiceData.fechaVencimiento,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                "MONEDA",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                invoiceData.moneda == 'PEN' ? 'SOLES' : 
                                invoiceData.moneda == 'USD' ? 'DÓLARES' : 
                                invoiceData.moneda,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Detalle de los items
              const Text(
                "DETALLE DE PRODUCTOS/SERVICIOS",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: invoiceData.detalleComprobanteBean.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = invoiceData.detalleComprobanteBean[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        item.descripcion,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Text(
                              "${item.cantidad} x ${currencyFormat.format(item.valorUnitario)}",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.afectoIgv ? Colors.green[100] : Colors.amber[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                item.afectoIgv ? "Afecto IGV" : "Inafecto",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: item.afectoIgv ? Colors.green[800] : Colors.amber[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        currencyFormat.format(item.montoTotalSinIgv),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Resumen de totales
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTotalRow("Total Gravado", invoiceData.totalGravado, currencyFormat),
                      if (invoiceData.totalInafecto > 0)
                        _buildTotalRow("Total Inafecto", invoiceData.totalInafecto, currencyFormat),
                      _buildTotalRow("IGV (18%)", invoiceData.totalIgv, currencyFormat),
                      const Divider(height: 16),
                      _buildTotalRow(
                        "TOTAL A PAGAR", 
                        invoiceData.totalGeneral, 
                        currencyFormat,
                        isTotal: true
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.save_alt,
                    label: "Guardar",
                    color: Colors.blue,
                    onPressed: () {
                      // Implementar guardado local
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Factura guardada localmente')),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.print,
                    label: "Imprimir",
                    color: Colors.green,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función imprimir en desarrollo')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper para construir filas de totales
  Widget _buildTotalRow(String label, double amount, NumberFormat formatter, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper para construir botones de acción
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}