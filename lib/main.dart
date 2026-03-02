import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'login.dart';
import 'home.dart';

void main() {
  runApp(const EventControlApp());
}

class EventControlApp extends StatefulWidget {
  const EventControlApp({super.key});

  @override
  State<EventControlApp> createState() => _EventControlAppState();
}

class _EventControlAppState extends State<EventControlApp> {
  bool darkMode = true; // já inicia no escuro (recomendado)
  int? idUsuario;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _verificarLogin();
  }

  Future<void> _verificarLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final logado = prefs.getBool('logado') ?? false;

    if (logado) {
      final id = prefs.getInt('id_usuario');
      if (id != null) {
        idUsuario = id;
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  // CONTROLE DE TEMA
  void toggleTheme() {
    setState(() {
      darkMode = !darkMode;
    });
  }

  // LOGIN / LOGOUT
  void login(int id) {
    setState(() {
      idUsuario = id;
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    setState(() {
      idUsuario = null;
    });
  }

  // APP
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // TEMAS
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,

      // CONTROLE DE TELAS
      home: isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : idUsuario == null
              ? LoginScreen(
                  onLogin: login,
                  onTheme: toggleTheme,
                )
              : HomeScreen(
                  idUsuario: idUsuario!,
                  onLogout: logout,
                  onTheme: toggleTheme,
                ),
    );
  }
}
