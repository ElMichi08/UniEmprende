import 'package:flutter/material.dart';

class AdvancedFiltersWidget extends StatefulWidget {
  final String? sectorSeleccionado;
  final double? precioMinimo;
  final double? precioMaximo;
  final String? ordenarPor;
  final bool descendente;
  final List<String> sectoresDisponibles;
  final Function(String?) onSectorChanged;
  final Function(double?) onPrecioMinimoChanged;
  final Function(double?) onPrecioMaximoChanged;
  final Function(String?, bool) onOrdenamientoChanged;
  final VoidCallback onLimpiarFiltros;
  final VoidCallback onAplicarFiltros;

  const AdvancedFiltersWidget({
    super.key,
    this.sectorSeleccionado,
    this.precioMinimo,
    this.precioMaximo,
    this.ordenarPor,
    this.descendente = false,
    required this.sectoresDisponibles,
    required this.onSectorChanged,
    required this.onPrecioMinimoChanged,
    required this.onPrecioMaximoChanged,
    required this.onOrdenamientoChanged,
    required this.onLimpiarFiltros,
    required this.onAplicarFiltros,
  });

  @override
  State<AdvancedFiltersWidget> createState() => _AdvancedFiltersWidgetState();
}

class _AdvancedFiltersWidgetState extends State<AdvancedFiltersWidget> {
  final TextEditingController _precioMinimoController = TextEditingController();
  final TextEditingController _precioMaximoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _precioMinimoController.text = widget.precioMinimo?.toString() ?? '';
    _precioMaximoController.text = widget.precioMaximo?.toString() ?? '';
  }

  @override
  void dispose() {
    _precioMinimoController.dispose();
    _precioMaximoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtros Avanzados',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filtro por Sector
          const Text(
            'Sector',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.sectorSeleccionado,
                hint: const Text('Seleccionar sector'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos los sectores'),
                  ),
                  ...widget.sectoresDisponibles.map((sector) {
                    return DropdownMenuItem<String>(
                      value: sector,
                      child: Text(sector),
                    );
                  }).toList(),
                ],
                onChanged: widget.onSectorChanged,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Filtro por Precio
          const Text(
            'Rango de Precio',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _precioMinimoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio mínimo',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) {
                    final precio = double.tryParse(value);
                    widget.onPrecioMinimoChanged(precio);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _precioMaximoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Precio máximo',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) {
                    final precio = double.tryParse(value);
                    widget.onPrecioMaximoChanged(precio);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Ordenamiento
          const Text(
            'Ordenar por',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: const Text('Nombre A-Z'),
                selected: widget.ordenarPor == 'nombre' && !widget.descendente,
                onSelected: (selected) {
                  if (selected) {
                    widget.onOrdenamientoChanged('nombre', false);
                  }
                },
              ),
              FilterChip(
                label: const Text('Nombre Z-A'),
                selected: widget.ordenarPor == 'nombre' && widget.descendente,
                onSelected: (selected) {
                  if (selected) {
                    widget.onOrdenamientoChanged('nombre', true);
                  }
                },
              ),
              FilterChip(
                label: const Text('Precio ↑'),
                selected: widget.ordenarPor == 'precio' && !widget.descendente,
                onSelected: (selected) {
                  if (selected) {
                    widget.onOrdenamientoChanged('precio', false);
                  }
                },
              ),
              FilterChip(
                label: const Text('Precio ↓'),
                selected: widget.ordenarPor == 'precio' && widget.descendente,
                onSelected: (selected) {
                  if (selected) {
                    widget.onOrdenamientoChanged('precio', true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Botones
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onLimpiarFiltros,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: const Text('Limpiar'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAplicarFiltros();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
