import 'package:flutter/material.dart';
import 'eventos.dart';
import 'catalogo.dart';
import 'configuracoes.dart';
import 'widgets/action_card.dart';

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

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF11172A),
                  const Color(0xFF0B0F1A),
                ]
              : [
                  const Color(0xFFECEFF6),
                  const Color(0xFFF5F7FB),
                ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('EventControl'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ConfiguracoesPage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: onTheme,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _confirmarLogout(context);
              },
            ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'O que você deseja gerenciar?',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          ActionCard(
            icon: Icons.calendar_month,
            title: 'Eventos',
            subtitle: 'Gerencie seus eventos e datas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EventosScreen(idUsuario: idUsuario),
                ),
              );
            },
          ),
          ActionCard(
            icon: Icons.inventory_2,
            title: 'Catálogo',
            subtitle: 'Itens, categorias e estoque',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CatalogoScreen(idUsuario: idUsuario),
                ),
              );
            },
          ),
        ],
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
