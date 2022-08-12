import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:presente/server.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presente',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: Body(),
      ),
    );
  }
}

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  State<Body> createState() => _BodyState();
}

class _BodyState extends State<Body> {
  bool loading = false;
  int? _legajo;
  String _mensaje = '';
  bool _error = false;

  final _presenteFormKey = GlobalKey<FormState>();

  final _legajoController = TextEditingController();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  void _mostrarMensaje(String msg, bool error) {
    setState(() {
      _mensaje = msg;
      _error = error;
    });
  }

  Future<bool> _dioPresente() async {
    final SharedPreferences prefs = await _prefs;
    String? fechaPresente = prefs.getString('presente');
    if (fechaPresente == null) {
      return false;
    }
    DateTime fecha = DateTime.parse(fechaPresente);
    DateTime hoy = DateTime.now();
    if (fecha.day != hoy.day) {
      return false;
    }
    if (fecha.month != hoy.month) {
      return false;
    }
    if (fecha.year != hoy.year) {
      return false;
    }
    return true;
  }

  void _enviarPresente() async {
    if (loading) return;
    setState(() {
      loading = true;
    });
    FocusScope.of(context).unfocus();

    if (await _dioPresente()) {
      _mostrarMensaje('YA DISTE TU PRESENTE HOY', false);
      setState(() {
        loading = false;
      });
      return;
    }

    if (_presenteFormKey.currentState!.validate()) {
      _presenteFormKey.currentState!.save();
      String ip = await Server.obtenerIp();
      if (ip.isEmpty) {
        _mostrarMensaje('ERROR - Volver a Intentar', true);
      } else {
        bool exito = await Server.darPresente(_legajo!, ip);
        if (exito) {
          SharedPreferences prefs = await _prefs;
          await prefs.setString('presente', DateTime.now().toIso8601String());
          _mostrarMensaje('PRESENTE CONFIRMADO', false);
        } else {
          _mostrarMensaje('ERROR - Volver a Intentar', true);
        }
      }
    }
    setState(() {
      loading = false;
    });
  }

  String? _validarLegajo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingrese su legajo';
    }
    if (int.tryParse(value) == null) {
      return 'Por favor, ingrese su legajo usando números';
    }
    return null;
  }

  String? _validarConfirmacionLegajo(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, confirme su legajo';
    }
    if (_legajoController.text != value) {
      return 'La confirmación del legajo debe ser igual al legajo';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _error || _mensaje.isEmpty
            ? const SizedBox.shrink()
            : Align(
                alignment: Alignment.center,
                child: Image.asset('images/confetti.gif'),
              ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Form(
                key: _presenteFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextFormField(
                      textInputAction: TextInputAction.next,
                      controller: _legajoController,
                      onSaved: (value) => _legajo = int.parse(value!),
                      validator: (value) => _validarLegajo(value),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Ingrese su Legajo',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    TextFormField(
                      textInputAction: TextInputAction.done,
                      validator: (value) => _validarConfirmacionLegajo(value),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Confirme su Legajo',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    loading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () {
                              _enviarPresente();
                            },
                            child: const Text('DAR PRESENTE'),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Text(
                _mensaje,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(color: _error ? Colors.red : Colors.green),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
