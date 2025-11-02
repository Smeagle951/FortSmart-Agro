
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/providers.dart';
import '../../../../core/database/app_database.dart';
import 'organismo_form_page.dart';

class CulturaTabsPage extends ConsumerWidget {
  final int culturaId;
  final String culturaNome;
  const CulturaTabsPage({super.key, required this.culturaId, required this.culturaNome});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(culturaNome),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Variedades'),
              Tab(text: 'Pragas'),
              Tab(text: 'Doenças'),
              Tab(text: 'Plantas Daninhas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text('Variedades (implementar lista e CRUD)')),
            _OrganismoList(culturaId: culturaId, isDisease: false),
            _OrganismoList(culturaId: culturaId, isDisease: true),
            _OrganismoList(culturaId: culturaId, isDisease: false, isWeed: true),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (_)=> OrganismoFormPage(culturaId: culturaId)));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

class _OrganismoList extends ConsumerWidget {
  final int culturaId;
  final bool isDisease;
  final bool isWeed;
  const _OrganismoList({required this.culturaId, required this.isDisease, this.isWeed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = isWeed
        ? ref.watch(plantasDaninhasByCulturaProvider(culturaId))
        : isDisease
            ? ref.watch(doencasByCulturaProvider(culturaId))
            : ref.watch(pragasByCulturaProvider(culturaId));

    return provider.when(
      data: (list) {
        final organismos = list as List<Organismo>? ?? [];
        return ListView.separated(
          itemCount: organismos.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i){
            final o = organismos[i];
            return ListTile(
              title: Text(o.nomeComum),
              subtitle: Text(o.nomeCientifico ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: (){
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (_) => OrganismoFormPage(
                            culturaId: culturaId,
                            organismo: o, // Passar o organismo para edição
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar exclusão'),
                          content: Text('Deseja excluir "${o.nomeComum}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Excluir'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirm == true) {
                        try {
                          final repository = ref.read(organismRepositoryProvider);
                          await repository.deleteOrganismo(o.id);
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Organismo excluído com sucesso!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao excluir: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: ()=> const Center(child: CircularProgressIndicator()),
      error: (e, s)=> Center(child: Text('Erro: $e'))
    );
  }
}
