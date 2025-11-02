
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers/providers.dart';
import 'cultura_tabs_page.dart';

class CulturaPage extends ConsumerWidget {
  const CulturaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final culturas = ref.watch(culturasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Culturas')),
      body: culturas.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (ctx, i){
            final c = list[i];
            return ListTile(
              title: Text(c.nome),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (_)=> CulturaTabsPage(culturaId: c.id, culturaNome: c.nome)));
              },
            );
          },
        ),
        loading: ()=> const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erro: $e')),
      ),
    );
  }
}
