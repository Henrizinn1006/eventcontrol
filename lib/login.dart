import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class LoginScreen extends StatefulWidget {
  final Function(int idUsuario) onLogin;
  final VoidCallback onTheme;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onTheme,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum RecuperarEtapa { email, codigo, novaSenha }

class _LoginScreenState extends State<LoginScreen> {
  final api = ApiService();

  final emailCtrl = TextEditingController();
  final senhaCtrl = TextEditingController();

  bool verSenha = false;
  bool loading = false;
  bool lembrarMe = false;

  // LOGIN


  Future<void> entrar() async {
    setState(() => loading = true);
    try {
      final user = await api.login(
        emailCtrl.text.trim(),
        senhaCtrl.text,
      );

      if (lembrarMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_usuario', user['id_usuario']);
        await prefs.setString('nome', user['nome'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setBool('logado', true);
      }

      widget.onLogin(user['id_usuario']);
    } catch (e) {
      _msg(e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // CADASTRO


  void dialogCadastro() {
    final nome = TextEditingController();
    final email = TextEditingController();
    final senha = TextEditingController();
    final conf = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cadastro'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha')),
              TextField(controller: conf, obscureText: true, decoration: const InputDecoration(labelText: 'Confirmar senha')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await api.cadastro(
                  nome.text.trim(),
                  email.text.trim(),
                  senha.text,
                  conf.text,
                );
                Navigator.pop(context);
                _msg('Cadastro realizado com sucesso');
              } catch (e) {
                _msg(e.toString());
              }
            },
            child: const Text('Cadastrar'),
          ),
        ],
      ),
    );
  }

  // RECUPERAÇÃO DE SENHA (3 ETAPAS CORRETAS)

  void dialogRecuperarSenha() {
    final email = TextEditingController();
    final codigo = TextEditingController();
    final nova = TextEditingController();
    final conf = TextEditingController();

    RecuperarEtapa etapa = RecuperarEtapa.email;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Recuperar senha'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    if (etapa == RecuperarEtapa.email)
                      TextField(
                        controller: email,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),

                    if (etapa == RecuperarEtapa.codigo)
                      TextField(
                        controller: codigo,
                        decoration: const InputDecoration(labelText: 'Código recebido'),
                      ),

                    if (etapa == RecuperarEtapa.novaSenha) ...[
                      TextField(
                        controller: nova,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Nova senha'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: conf,
                        obscureText: true,
                        decoration: const InputDecoration(labelText: 'Confirmar nova senha'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      // ETAPA 1 → envia código
                      if (etapa == RecuperarEtapa.email) {
                        await api.recuperarSenha(email.text.trim());
                        setStateDialog(() => etapa = RecuperarEtapa.codigo);
                        _msg('Código enviado para o email');
                      }

                      // ETAPA 2 → avança para senha
                      else if (etapa == RecuperarEtapa.codigo) {
                        if (codigo.text.trim().isEmpty) {
                          _msg('Informe o código');
                          return;
                        }
                        setStateDialog(() => etapa = RecuperarEtapa.novaSenha);
                      }

                      // ETAPA 3 → salva nova senha
                      else {
                        await api.novaSenha(
                          email.text.trim(),
                          codigo.text.trim(),
                          nova.text,
                          conf.text,
                        );
                        Navigator.pop(context);
                        _msg('Senha alterada com sucesso');
                      }
                    } catch (e) {
                      _msg(e.toString());
                    }
                  },
                  child: Text(
                    etapa == RecuperarEtapa.email
                        ? 'Enviar código'
                        : etapa == RecuperarEtapa.codigo
                            ? 'Validar código'
                            : 'Salvar nova senha',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // UTIL

  void _msg(String txt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(txt)),
    );
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    senhaCtrl.dispose();
    super.dispose();
  }

  // UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dark_mode),
            onPressed: widget.onTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: senhaCtrl,
              obscureText: !verSenha,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  icon: Icon(verSenha ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => verSenha = !verSenha),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Checkbox(
                  value: lembrarMe,
                  onChanged: (val) => setState(() => lembrarMe = val ?? false),
                ),
                const Text('Lembrar de mim'),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : entrar,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text('Entrar'),
              ),
            ),
            TextButton(
              onPressed: dialogCadastro,
              child: const Text('Cadastrar'),
            ),
            TextButton(
              onPressed: dialogRecuperarSenha,
              child: const Text('Esqueci minha senha'),
            ),
          ],
        ),
      ),
    );
  }
}

