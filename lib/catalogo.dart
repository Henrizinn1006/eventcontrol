import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'api.dart';

/// =======================================================
/// TELA PRINCIPAL — CATEGORIAS
/// =======================================================

class CatalogoScreen extends StatefulWidget {
  final int idUsuario;
  const CatalogoScreen({super.key, required this.idUsuario});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final api = ApiService();
  late Future<List<dynamic>> categoriasFuture;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    categoriasFuture = api.categorias(widget.idUsuario);
  }

  Future<void> _novaCategoria() async {
    final ctrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nova categoria'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final nome = ctrl.text.trim();
    if (nome.isEmpty) return;

    try {
      await api.criarCategoria(widget.idUsuario, nome);
      if (!mounted) return;
      setState(_recarregar);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      floatingActionButton: FloatingActionButton(
        onPressed: _novaCategoria,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: categoriasFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final categorias = snap.data ?? [];
          if (categorias.isEmpty) {
            return const Center(child: Text('Nenhuma categoria'));
          }

          return ListView.separated(
            itemCount: categorias.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = categorias[i];
              return ListTile(
                title: Text(c['nome_categoria'] ?? '-'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItensCategoriaScreen(
                        idUsuario: widget.idUsuario,
                        idCategoria: c['id_categoria'],
                        nomeCategoria: c['nome_categoria'] ?? 'Categoria',
                      ),
                    ),
                  );
                  if (!mounted) return;
                  setState(_recarregar);
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// =======================================================
/// TELA — ITENS DA CATEGORIA (COM IMAGEM)
/// =======================================================

class ItensCategoriaScreen extends StatefulWidget {
  final int idUsuario;
  final int idCategoria;
  final String nomeCategoria;

  const ItensCategoriaScreen({
    super.key,
    required this.idUsuario,
    required this.idCategoria,
    required this.nomeCategoria,
  });

  @override
  State<ItensCategoriaScreen> createState() => _ItensCategoriaScreenState();
}

class _ItensCategoriaScreenState extends State<ItensCategoriaScreen> {
  final api = ApiService();
  late Future<List<dynamic>> itensFuture;

  // Cache para não baixar a mesma imagem repetidamente
  final Map<int, Future<Uint8List>> _imgCache = {};

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    itensFuture = api.itensCategoria(widget.idCategoria, widget.idUsuario);
  }

  int? _readInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<Uint8List> _imgFuture(int idItem) {
    return _imgCache.putIfAbsent(
      idItem,
      () => api.imagemItem(widget.idUsuario, idItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.nomeCategoria)),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemFormScreen(
                idUsuario: widget.idUsuario,
                idCategoria: widget.idCategoria,
              ),
            ),
          );
          if (ok == true) {
            _imgCache.clear(); // evita mostrar imagem antiga
            setState(_recarregar);
          }
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: itensFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final itens = snap.data ?? [];
          if (itens.isEmpty) {
            return const Center(child: Text('Nenhum item nesta categoria'));
          }

          return ListView.separated(
            itemCount: itens.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final it = itens[i];
              final idItem = _readInt(it['id_item']);
              
              print(it);
              
              final disponivel = it['quantidade_disponivel'];
              final int total = it['quantidade_total'] ?? 0;

              final imageUrl =
                  '${ApiService.baseUrl}/catalogo/imagens/itens/${it['id_item']}'
                  '?id_usuario=${widget.idUsuario}';
              print('🖼️ URL da imagem: $imageUrl');

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  ),
                ),
                title: Text(it['nome_item'] ?? '-'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${it['abreviacao'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text(
                      disponivel == null
                          ? 'Erro'
                          : disponivel == 0
                              ? 'Indisponível'
                              : 'Disponível: $disponivel',
                      style: TextStyle(
                        color: disponivel == 0 ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final ok = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemFormScreen(
                              idUsuario: widget.idUsuario,
                              idCategoria: widget.idCategoria,
                              item: Map<String, dynamic>.from(it),
                            ),
                          ),
                        );
                        if (ok == true) {
                          _imgCache.remove(idItem); // recarrega só esse item
                          setState(_recarregar);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Excluir item'),
                            content: const Text('Deseja realmente excluir este item?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Excluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirmar != true || idItem == null) return;

                        try {
                          await api.excluirItem(widget.idUsuario, idItem);
                          _imgCache.remove(idItem);
                          setState(_recarregar);
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erro: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Miniatura: baixa bytes pela API e mostra com Image.memory
class _ThumbBytes extends StatelessWidget {
  final int? idItem;
  final Future<Uint8List> Function(int idItem) carregar;
  final void Function(Uint8List bytes) onAbrir;

  const _ThumbBytes({
    required this.idItem,
    required this.carregar,
    required this.onAbrir,
  });

  @override
  Widget build(BuildContext context) {
    if (idItem == null) return _placeholder();

    return FutureBuilder<Uint8List>(
      future: carregar(idItem!),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snap.hasError) {
          print('ERRO IMAGEM idItem=$idItem -> ${snap.error}');
          return _placeholder();
        }

        if (!snap.hasData) {
          return _placeholder();
        }

        final bytes = snap.data!;
        return GestureDetector(
          onTap: () => onAbrir(bytes),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.memory(
              bytes,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return Container(
      width: 52,
      height: 52,
      color: Colors.grey.shade300,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }
}

/// =======================================================
/// FORM — CRIAR / EDITAR ITEM (com imagem)
/// =======================================================

class ItemFormScreen extends StatefulWidget {
  final int idUsuario;
  final int idCategoria;
  final Map<String, dynamic>? item;

  const ItemFormScreen({
    super.key,
    required this.idUsuario,
    required this.idCategoria,
    this.item,
  });

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final api = ApiService();

  final nomeCtrl = TextEditingController();
  final abrevCtrl = TextEditingController();
  final qtdCtrl = TextEditingController();

  XFile? imagem;
  bool salvando = false;

  bool get isEdicao => widget.item != null;

  @override
  void initState() {
    super.initState();
    if (isEdicao) {
      nomeCtrl.text = widget.item!['nome_item'] ?? '';
      abrevCtrl.text = widget.item!['abreviacao'] ?? '';
      qtdCtrl.text = widget.item!['quantidade_total']?.toString() ?? '';
    }
  }

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (img == null) return;

    setState(() => imagem = img);
  }

  void _erro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _salvar() async {
    final nome = nomeCtrl.text.trim();
    final abrev = abrevCtrl.text.trim();
    final qtd = int.tryParse(qtdCtrl.text.trim());

    if (nome.isEmpty || qtd == null || qtd <= 0) {
      _erro('Dados inválidos');
      return;
    }

    setState(() => salvando = true);

    try {
      if (isEdicao) {
        final idItem = widget.item!['id_item'];

        await api.editarItemCategoria(
          idUsuario: widget.idUsuario,
          idItem: idItem,
          nomeItem: nome,
          abreviacao: abrev,
          quantidade: qtd,
        );

        if (imagem != null) {
          await api.atualizarImagemItem(
            idUsuario: widget.idUsuario,
            idItem: idItem,
            imagemFile: File(imagem!.path),
          );
        }
      } else {
        if (imagem == null) {
          _erro('Selecione uma imagem');
          return;
        }

        await api.criarItemCategoria(
          idUsuario: widget.idUsuario,
          idCategoria: widget.idCategoria,
          nomeItem: nome,
          abreviacao: abrev,
          quantidade: qtd,
          imagemFile: File(imagem!.path),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _erro(e.toString());
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar item' : 'Novo item'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nomeCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: abrevCtrl,
              decoration: const InputDecoration(labelText: 'Abreviação (opcional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtdCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade total'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _escolherImagem,
                  icon: const Icon(Icons.photo),
                  label: const Text('Imagem'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    imagem == null
                        ? (isEdicao ? 'Imagem atual mantida' : 'Nenhuma imagem')
                        : imagem!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salvando ? null : _salvar,
                child: Text(salvando ? 'Salvando...' : 'Salvar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// VISUALIZAR IMAGEM (BYTES)
/// =======================================================

class VisualizarImagemBytesScreen extends StatelessWidget {
  final Uint8List bytes;
  const VisualizarImagemBytesScreen({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
