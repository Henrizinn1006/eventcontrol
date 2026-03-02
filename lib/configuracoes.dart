import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _controller = TextEditingController();
  bool _loading = false;

  final String baseUrl = "http://eventcontrolmaster.shop:8000";

  @override
  void initState() {
    super.initState();
    _carregarNomeSalvo();
  }

  Future<void> _carregarNomeSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final nome = prefs.getString("nome_empresa") ?? "";
    _controller.text = nome;
  }

  Future<void> salvarNomeEmpresa() async {
    if (_loading) return;

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final idUsuario = prefs.getInt('id_usuario');
      final nome = _controller.text.trim();

      if (idUsuario == null) {
        throw Exception("id_usuario não encontrado no SharedPreferences.");
      }
      if (nome.isEmpty) {
        throw Exception("Digite o nome da empresa.");
      }

      final url = Uri.parse('$baseUrl/home/empresa');

      final response = await http
          .put(
            url,
            headers: {"Content-Type": "application/x-www-form-urlencoded"},
            body: {
              "id_usuario": idUsuario.toString(),
              "nome_empresa": nome,
            },
          )
          .timeout(const Duration(seconds: 8));

      print("STATUS: ${response.statusCode}");
      print("BODY: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        await prefs.setString("nome_empresa", nome);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nome da empresa atualizado!")),
        );

        Navigator.pop(context);
      } else {
        final body = utf8.decode(response.bodyBytes);
        throw Exception("Erro ${response.statusCode}: $body");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Falha ao salvar: $e")),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: "Nome da empresa",
                hintText: "Ex: Minha Empresa",
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : salvarNomeEmpresa,
                child: Text(_loading ? "Salvando..." : "Salvar"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
