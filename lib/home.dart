import 'package:flutter/material.dart';
import 'eventos.dart';
import 'catalogo.dart';

class HomeScreen extends StatelessWidget {
  final int idUsuario;
  final VoidCallback onLogout;
  final VoidCallback onTheme;

  const HomeScreen({
    super.key,
    required this.idUsuario,
    required this.onLogout,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('EventControl'),
        centerTitle: true,
        actions: [
          // BOTÃO TEMA CLARO / ESCURO
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: onTheme,
          ),
          // BOTÃO LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _confirmarLogout(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _botaoMenu(
              context,
              titulo: 'Eventos',
              icone: Icons.event,
              cor: isDark ? Colors.black : Colors.white, // ✅ só muda o fundo
              destino: EventosScreen(idUsuario: idUsuario),
            ),
            const SizedBox(height: 20),
            _botaoMenu(
              context,
              titulo: 'Catálogo',
              icone: Icons.inventory_2,
              cor: isDark ? Colors.black : Colors.white, // ✅ só muda o fundo
              destino: CatalogoScreen(idUsuario: idUsuario),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botaoMenu(
    BuildContext context, {
    required String titulo,
    required IconData icone,
    required Color cor,
    required Widget destino,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: cor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destino),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 32),
            const SizedBox(width: 16),
            Text(
              titulo,
              style: const TextStyle(fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja realmente sair da conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onLogout();
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
