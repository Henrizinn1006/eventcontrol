import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ApiService {
  // =========================
  // CONFIG
  // =========================
  static const String baseUrl = 'http://eventcontrolmaster.shop:8000';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // =========================
  // AUTH
  // =========================

  Future<Map<String, dynamic>> login(String email, String senha) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(res.body);
  }

  Future<void> cadastro(
    String nome,
    String email,
    String senha,
    String confirmar,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/cadastro'),
      headers: _headers,
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'senha': senha,
        'confirmar_senha': confirmar,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  Future<void> recuperarSenha(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/recuperar-senha'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );

    if (res.statusCode != 200) { 
      throw Exception(res.body);
    }
  }

  Future<void> novaSenha(
    String email,
    String codigo,
    String nova,
    String confirmar,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/nova-senha'),
      headers: _headers,
      body: jsonEncode({
        'email': email,
        'codigo': codigo,
        'nova_senha': nova,
        'confirmar_senha': confirmar,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // =========================
  // HOME
  // =========================

  Future<Map<String, dynamic>> painel(int idUsuario) async {
    final res = await http.get(
      Uri.parse('$baseUrl/home/painel/$idUsuario'),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw Exception(res.body);
  }

  // =========================
  // CATEGORIAS
  // =========================

  Future<List<dynamic>> categorias(int idUsuario) async {
    final res = await http.get(
      Uri.parse('$baseUrl/catalogo/categorias/$idUsuario'),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('dados')) {
        return List.from(decoded['dados']);
      }
      if (decoded is List) return decoded;
      return [];
    }

    throw Exception(res.body);
  }

  Future<void> criarCategoria(int idUsuario, String nome) async {
    final uri = Uri.parse('$baseUrl/catalogo/categorias');
    final request = http.MultipartRequest('POST', uri);

    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['nome_categoria'] = nome;

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception(body);
    }
  }

  Future<void> editarCategoria(
    int idUsuario,
    int idCategoria,
    String nome,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/catalogo/categorias/$idCategoria'),
      headers: _headers,
      body: jsonEncode({
        'id_usuario': idUsuario,
        'nome': nome,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  Future<void> excluirCategoria(int idUsuario, int idCategoria) async {
    final res = await http.delete(
      Uri.parse(
        '$baseUrl/catalogo/categorias/$idCategoria?id_usuario=$idUsuario',
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // =========================
  // ITENS DO CATÁLOGO
  // =========================

  Future<List<dynamic>> itensCategoria(
    int idCategoria,
    int idUsuario,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/catalogo/itens/$idCategoria/$idUsuario'),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('dados')) {
        return List.from(decoded['dados']);
      }
      if (decoded is List) return decoded;
      return [];
    }

    throw Exception(res.body);
  }

  Future<void> criarItemCategoria({
    required int idUsuario,
    required int idCategoria,
    required String nomeItem,
    required String abreviacao,
    required int quantidade,
    required File imagemFile,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/catalogo/itens'),
    );

    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['id_categoria'] = idCategoria.toString();
    request.fields['nome'] = nomeItem;
    request.fields['abreviacao'] = abreviacao;
    request.fields['quantidade_total'] = quantidade.toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'imagem',
        imagemFile.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception(await response.stream.bytesToString());
    }
  }

  Future<void> editarItemCategoria({
    required int idUsuario,
    required int idItem,
    required String nomeItem,
    required String abreviacao,
    required int quantidade,
  }) async {
    final uri = Uri.parse('$baseUrl/catalogo/itens/$idItem');

    final request = http.MultipartRequest('PUT', uri);

    // O BACKEND EXIGE id_usuario NO FORM
    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['nome'] = nomeItem;
    request.fields['abreviacao'] = abreviacao;
    request.fields['quantidade_total'] = quantidade.toString();

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('HTTP ${response.statusCode}: $body');
    }
  }

  Future<Uint8List> imagemItem(int idUsuario, int idItem) async {
    final res = await http.get(
      Uri.parse('$baseUrl/catalogo/itens/imagem/$idItem?id_usuario=$idUsuario'),
    );

    if (res.statusCode == 200) return res.bodyBytes;
    throw Exception(res.body);
  }

  Future<void> atualizarImagemItem({
    required int idUsuario,
    required int idItem,
    required File imagemFile,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/catalogo/itens/$idItem/imagem?id_usuario=$idUsuario',
    );

    final request = http.MultipartRequest('PUT', uri);

    request.files.add(
      await http.MultipartFile.fromPath(
        'imagem',
        imagemFile.path,
      ),
    );

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception(await response.stream.bytesToString());
    }
  }

  Future<void> excluirItem(int idUsuario, int idItem) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/catalogo/itens/$idItem?id_usuario=$idUsuario'),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // =========================
  // EVENTOS
  // =========================

  Future<List<dynamic>> eventos(int idUsuario) async {
    final res = await http.get(
      Uri.parse('$baseUrl/eventos/$idUsuario'),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('dados')) {
        return List.from(decoded['dados']);
      }
      if (decoded is List) return decoded;
      return [];
    }

    throw Exception(res.body);
  }

  Future<void> criarEvento(
    int idUsuario,
    String nomeEvento,
    String cliente,
    String local,
    String data,
    String? hora,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/eventos/'),
    );

    request.fields['id_usuario'] = idUsuario.toString();
    request.fields['nome_evento'] = nomeEvento;
    request.fields['nome_cliente'] = cliente;
    request.fields['endereco_evento'] = local;
    request.fields['data_evento'] = data;

    if (hora != null && hora.trim().isNotEmpty) {
      request.fields['hora_evento'] = hora.trim();
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw Exception('HTTP ${response.statusCode}: $body');
    }
  }

  Future<void> editarEvento(
    int idUsuario,
    int idEvento,
    String nomeEvento,
    String cliente,
    String local,
    String data,
    String hora,
  ) async {
    final uri = Uri.parse(
      '$baseUrl/eventos/$idEvento'
      '?id_usuario=$idUsuario'
      '&nome_evento=${Uri.encodeQueryComponent(nomeEvento)}'
      '&nome_cliente=${Uri.encodeQueryComponent(cliente)}'
      '&endereco_evento=${Uri.encodeQueryComponent(local)}'
      '&data_evento=$data'
      '&hora_evento=$hora',
    );

    final res = await http.put(uri);

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  Future<void> excluirEvento({
    required int idEvento,
    required int idUsuario,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/eventos/$idEvento?id_usuario=$idUsuario',
    );

    final res = await http.delete(uri);

    if (res.statusCode != 200) {
      throw Exception('Erro ao excluir evento');
    }
  }

  Future<void> ativarEvento(int idUsuario, int idEvento) async {
    final url = Uri.parse('$baseUrl/eventos/$idEvento/ativar')
        .replace(queryParameters: {'id_usuario': '$idUsuario'});

    final res = await http.post(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Falha ao ativar: ${res.statusCode} - ${res.body}');
    }
  }

  Future<void> finalizarEvento(
    int idUsuario,
    int idEvento,
    String status,
    String devolucoes,
  ) async {
    final url = Uri.parse('$baseUrl/eventos/$idEvento/finalizar').replace(
      queryParameters: {
        'id_usuario': '$idUsuario',
        'status': status,
        'devolucoes': devolucoes,
      },
    );

    final res = await http.post(url);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Falha ao finalizar: ${res.statusCode} - ${res.body}');
    }
  }

  Future<void> finalizarEventoJson(
    int idUsuario,
    int idEvento,
    String status,
    List<Map<String, dynamic>> devolucoes,
  ) async {
    final url = Uri.parse('$baseUrl/eventos/$idEvento/finalizar-json')
        .replace(queryParameters: {'id_usuario': '$idUsuario'});

    final res = await http.post(
      url,
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'devolucoes': devolucoes, // [{id_item: 1, qtd_devolvida: 3}, ...]
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Falha ao finalizar: ${res.statusCode} - ${res.body}');
    }
  }

  // =========================
  // ITENS DO EVENTO (CORRIGIDO)
  // =========================

  Future<List<dynamic>> itensEvento(int idUsuario, int idEvento) async {
    // ✅ rota coerente com o padrão de /eventos
    final res = await http.get(
      Uri.parse('$baseUrl/eventos/$idEvento/itens?id_usuario=$idUsuario'),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is Map && decoded.containsKey('dados')) {
        return List.from(decoded['dados']);
      }
      if (decoded is List) return decoded;
      return [];
    }

    throw Exception(res.body);
  }

  Future<void> adicionarItemEvento(
    int idUsuario,
    int idEvento,
    int idItem,
    int quantidade,
  ) async {
    final res = await http.post(
      Uri.parse(
        '$baseUrl/eventos/$idEvento/itens'
        '?id_usuario=$idUsuario'
        '&id_item=$idItem'
        '&quantidade=$quantidade',
      ),
    );

    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  // =========================
  // PDF EVENTO
  // =========================

  Future<void> abrirPdfEvento(int idUsuario, int idEvento) async {
    final url = Uri.parse(
      '$baseUrl/eventos/$idEvento/pdf?id_usuario=$idUsuario',
    );

    final ok = await launchUrl(
      url,
      mode: Platform.isAndroid
          ? LaunchMode.externalApplication
          : LaunchMode.platformDefault,
    );

    if (!ok) {
      throw Exception('Não foi possível abrir o PDF');
    }
  }

  // =========================
  // URL IMAGEM ITEM
  // =========================

  String imagemItemUrl(int idUsuario, int idItem) {
    return '$baseUrl/catalogo/itens/imagem/$idItem?id_usuario=$idUsuario';
  }
}
 