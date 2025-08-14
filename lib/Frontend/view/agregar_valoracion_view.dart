import 'package:flutter/material.dart';
import 'package:lata_emprende/Backend/controller/valoracion_controller.dart';

class AgregarValoracionView extends StatefulWidget {
  final String idEmprendimiento;
  final String nombreEmprendimiento;

  const AgregarValoracionView({
    super.key,
    required this.idEmprendimiento,
    required this.nombreEmprendimiento,
  });

  @override
  State<AgregarValoracionView> createState() => _AgregarValoracionViewState();
}

class _AgregarValoracionViewState extends State<AgregarValoracionView> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  int _puntajeSeleccionado = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Valoración'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Valorar: ${widget.nombreEmprendimiento}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Calificación:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),

              const SizedBox(height: 10),

              // Estrellas para calificación
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _puntajeSeleccionado = index + 1;
                      });
                    },
                    child: Icon(
                      Icons.star,
                      size: 40,
                      color: index < _puntajeSeleccionado
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  '$_puntajeSeleccionado estrella${_puntajeSeleccionado > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.redAccent,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              TextFormField(
                controller: _comentarioController,
                decoration: const InputDecoration(
                  labelText: 'Comentario',
                  border: OutlineInputBorder(),
                  hintText: 'Comparte tu experiencia...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Escribe un comentario';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final controller = ValoracionController();
                      controller.crearValoracion(
                        context: context,
                        comentario: _comentarioController.text.trim(),
                        puntaje: _puntajeSeleccionado,
                        idEmprendimiento: widget.idEmprendimiento,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Enviar Valoración',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }
}
