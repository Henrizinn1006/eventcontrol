import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api.dart';

/// =======================================================
/// TELA PRINCIPAL — LISTA DE EVENTOS
/// =======================================================

class EventosScreen extends StatefulWidget {
  final int idUsuario;
  const EventosScreen({super.key, required this.idUsuario});

  @override
  State<EventosScreen> createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final api = ApiService();
  late Future<List<dynamic>> eventosFuture;

  @override
  void initState() {
    super.initState();
    _recarregar();
  }

  void _recarregar() {
    eventosFuture = api.eventos(widget.idUsuario);
  }

  Future<void> _novoEvento() async {
    final nomeCtrl = TextEditingController();
    final clienteCtrl = TextEditingController();
    final localCtrl = TextEditingController();
    final dataCtrl = TextEditingController();
    final horaCtrl = TextEditingController();

    final criado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Novo Evento'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: nomeCtrl, decoration: const InputDecoration(labelText: 'Nome')),
              TextField(controller: clienteCtrl, decoration: const InputDecoration(labelText: 'Cliente')),
              TextField(controller: localCtrl, decoration: const InputDecoration(labelText: 'Local')),
              TextField(controller: dataCtrl, decoration: const InputDecoration(labelText: 'Data (AAAA-MM-DD)')),
              TextField(controller: horaCtrl, decoration: const InputDecoration(labelText: 'Hora (HH:MM)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await api.criarEvento(
                widget.idUsuario,
                nomeCtrl.text,
                clienteCtrl.text,
                localCtrl.text,
                dataCtrl.text,
                horaCtrl.text,
              );
              if (context.mounted) Navigator.pop(context, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (criado == true) {
      setState(() => _recarregar());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      floatingActionButton: FloatingActionButton(
        onPressed: _novoEvento,
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: eventosFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }

          final eventos = snap.data ?? [];
          if (eventos.isEmpty) {
            return const Center(child: Text('Nenhum evento'));
          }

          return ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (_, i) {
              final e = eventos[i];
              return ListTile(
                title: Text(e['nome_evento']),
                subtitle: Text('${e['data_evento']} • ${e['status']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventoDetalheScreen(
                        idUsuario: widget.idUsuario,
                        evento: e,
                      ),
                    ),
                  ).then((_) => setState(() => _recarregar()));
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
/// DETALHE DO EVENTO
/// =======================================================

class EventoDetalheScreen extends StatefulWidget {
  final int idUsuario;
  final Map evento;

  const EventoDetalheScreen({
    super.key,
    required this.idUsuario,
    required this.evento,
  });

  @override
  State<EventoDetalheScreen> createState() => _EventoDetalheScreenState();
}

class _EventoDetalheScreenState extends State<EventoDetalheScreen> {
  final api = ApiService();
  bool _carregando = false;

  void _abrirPdf() {
    launchUrl(
      Uri.parse(
        '${ApiService.baseUrl}/eventos/${widget.evento['id_evento']}/pdf?id_usuario=${widget.idUsuario}',
      ),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _ativar() async {
    setState(() => _carregando = true);
    try {
      await api.ativarEvento(widget.idUsuario, widget.evento['id_evento']);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao ativar: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _concluir() async {
    setState(() => _carregando = true);
    try {
      await api.finalizarEvento(
        widget.idUsuario,
        widget.evento['id_evento'],
        'concluido',
        '',
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir: $e')),
      );
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.evento['status'];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evento['nome_evento']),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${widget.evento['nome_cliente'] ?? '-'}'),
            Text('Local: ${widget.evento['endereco_evento'] ?? '-'}'),
            Text('Data: ${widget.evento['data_evento']}'),
            Text('Hora: ${widget.evento['hora_evento'] ?? '-'}'),
            Text('Status: $status'),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.inventory),
              label: const Text('Itens do Evento'),
              onPressed: _carregando
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EventoItensScreen(
                            idUsuario: widget.idUsuario,
                            idEvento: widget.evento['id_evento'],
                          ),
                        ),
                      );
                    },
            ),

            ElevatedButton.icon(
              icon: _carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('Ativar evento'),
              onPressed: (!_carregando && status == 'agendado') ? _ativar : null,
            ),

            ElevatedButton.icon(
              icon: _carregando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: const Text('Concluir evento'),
              onPressed: widget.evento['status'] == 'ativo'
                  ? () async {
                      try {
                        final itens =
                            await api.itensEvento(widget.idUsuario, widget.evento['id_evento']);

                        // cria controllers para cada item
                        final ctrls = <int, TextEditingController>{};
                        for (final it in itens) {
                          final locada = (it['quantidade_locada'] ?? 0).toString();
                          ctrls[it['id_item']] = TextEditingController(
                              text: locada); // default: tudo voltou
                        }

                        final confirmado = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Devolução de itens'),
                            content: SizedBox(
                              width: 380,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    for (final it in itens) ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          '${it['nome_item']} (Locado: ${it['quantidade_locada']})',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      TextField(
                                        controller: ctrls[it['id_item']],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: 'Quantidade devolvida',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Concluir'),
                              ),
                            ],
                          ),
                        );

                        if (confirmado != true) return;

                        // monta payload
                        final devolucoes = <Map<String, dynamic>>[];
                        for (final it in itens) {
                          final idItem = it['id_item'] as int;
                          final locada = (it['quantidade_locada'] ?? 0) as int;
                          final txt = ctrls[idItem]!.text.trim();
                          final devolvida = int.tryParse(txt) ?? -1;

                          if (devolvida < 0 || devolvida > locada) {
                            throw Exception(
                                'Quantidade inválida para ${it['nome_item']}');
                          }

                          devolucoes.add({
                            'id_item': idItem,
                            'qtd_devolvida': devolvida
                          });
                        }

                        await api.finalizarEventoJson(
                          widget.idUsuario,
                          widget.evento['id_evento'],
                          'concluido',
                          devolucoes,
                        );

                        if (context.mounted) Navigator.pop(context, true);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao concluir: $e')),
                        );
                      }
                    }
                  : null,
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Baixar PDF'),
              onPressed: _carregando ? null : _abrirPdf,
            ),
          ],
        ),
      ),
    );
  }
}

/// =======================================================
/// ITENS DO EVENTO
/// =======================================================

class EventoItensScreen extends StatefulWidget {
  final int idUsuario;
  final int idEvento;

  const EventoItensScreen({
    super.key,
    required this.idUsuario,
    required this.idEvento,
  });

  @override
  State<EventoItensScreen> createState() => _EventoItensScreenState();
}

class _EventoItensScreenState extends State<EventoItensScreen> {
  final api = ApiService();
  late Future<List<dynamic>> itensFuture;

  @override
  void initState() {
    super.initState();
    carregarItensEvento();
  }

  void carregarItensEvento() {
    setState(() {
      itensFuture = api.itensEvento(widget.idUsuario, widget.idEvento);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Itens do Evento'),
        leading: const BackButton(),
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
            return const Center(child: Text('Nenhum item no evento'));
          }

          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (_, i) {
              final it = itens[i];
              return ListTile(
                title: Text(it['nome_item']),
                subtitle: Text(
                  'Locado: ${it['quantidade_locada']} | Devolvido: ${it['quantidade_devolvida']}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CatalogoCategoriasScreen(
                idUsuario: widget.idUsuario,
                idEvento: widget.idEvento,
              ),
            ),
          );

          if (added == true) {
            carregarItensEvento();
          }
        },
      ),
    );
  }
}

/// =======================================================
/// CATÁLOGO - CATEGORIAS
/// =======================================================

class CatalogoCategoriasScreen extends StatelessWidget {
  final int idUsuario;
  final int idEvento;

  const CatalogoCategoriasScreen({
    super.key,
    required this.idUsuario,
    required this.idEvento,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().categorias(idUsuario),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final categorias = snap.data!;

          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (_, i) {
              final c = categorias[i];

              return ListTile(
                title: Text(c['nome_categoria']),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CatalogoItensScreen(
                        idUsuario: idUsuario,
                        idEvento: idEvento,
                        idCategoria: c['id_categoria'],
                      ),
                    ),
                  );
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
/// CATÁLOGO - ITENS DA CATEGORIA
/// =======================================================

class CatalogoItensScreen extends StatelessWidget {
  final int idUsuario;
  final int idEvento;
  final int idCategoria;

  const CatalogoItensScreen({
    super.key,
    required this.idUsuario,
    required this.idEvento,
    required this.idCategoria,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens')),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService().itensCategoria(idCategoria, idUsuario),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final itens = snap.data!;

          return ListView.builder(
            itemCount: itens.length,
            itemBuilder: (_, i) {
              final item = itens[i];

              return ListTile(
                title: Text(item['nome_item']),
                subtitle: Text('Disponível: ${item['quantidade_disponivel']}'),
                onTap: () async {
                  final ctrl = TextEditingController();

                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(item['nome_item']),
                      content: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await ApiService().adicionarItemEvento(
                              idUsuario,
                              idEvento,
                              item['id_item'],
                              int.parse(ctrl.text),
                            );
                            if (context.mounted) Navigator.pop(context, true);
                          },
                          child: const Text('Adicionar'),
                        ),
                      ],
                    ),
                  );

                  if (ok == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
