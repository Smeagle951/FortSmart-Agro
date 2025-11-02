import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

/// Tela que exibe os Termos de Uso do aplicativo
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Termos de Uso'),
        backgroundColor: const Color(0xFF2A4F3D),
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSection(
              '1. Aceitação dos Termos',
              'Ao utilizar o FortSmart Agro, você concorda com estes termos de uso. Se não concordar com qualquer parte destes termos, não deve utilizar o aplicativo.',
            ),
            _buildSection(
              '2. Descrição do Serviço',
              'O FortSmart Agro é um aplicativo de monitoramento agrícola que oferece:\n'
              '• Sistema de monitoramento de pragas e doenças\n'
              '• Mapa de infestação com IA integrada\n'
              '• Relatórios agronômicos inteligentes\n'
              '• Catálogo de organismos\n'
              '• Diagnóstico por sintomas e imagens',
            ),
            _buildSection(
              '3. Uso Responsável',
              'Você concorda em:\n'
              '• Fornecer informações precisas e atualizadas\n'
              '• Não utilizar o aplicativo para fins ilegais\n'
              '• Respeitar os direitos de propriedade intelectual\n'
              '• Manter a confidencialidade de dados sensíveis',
            ),
            _buildSection(
              '4. Propriedade Intelectual',
              'Todo o conteúdo do aplicativo, incluindo textos, imagens, algoritmos de IA e funcionalidades, é propriedade da FortSmart Agro e está protegido por leis de direitos autorais.',
            ),
            _buildSection(
              '5. Limitação de Responsabilidade',
              'O FortSmart Agro não se responsabiliza por:\n'
              '• Decisões tomadas com base nas informações do aplicativo\n'
              '• Perdas de produção ou danos agrícolas\n'
              '• Problemas técnicos ou interrupções do serviço\n'
              '• Uso inadequado das funcionalidades',
            ),
            _buildSection(
              '6. Privacidade e Dados',
              'Seus dados são tratados conforme nossa Política de Privacidade. Mantemos a confidencialidade das informações agrícolas e não compartilhamos dados com terceiros sem consentimento.',
            ),
            _buildSection(
              '7. Modificações',
              'Reservamo-nos o direito de modificar estes termos a qualquer momento. As alterações entrarão em vigor imediatamente após a publicação no aplicativo.',
            ),
            _buildSection(
              '8. Contato',
              'Para dúvidas sobre estes termos, entre em contato:\n'
              '📧 Email: fortsmart.agro@gmail.com\n'
              '📱 WhatsApp: +55 45 99126-1695',
            ),
            const SizedBox(height: 24),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A4F3D), Color(0xFF4A7C59)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.description,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Termos de Uso',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'FortSmart Agro - Versão 2.3.15',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A4F3D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Text(
            'Última atualização: Dezembro 2024',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '© 2024 FortSmart Agro. Todos os direitos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
