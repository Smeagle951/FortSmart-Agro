import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';

/// Tela que exibe a Política de Privacidade do aplicativo
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidade'),
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
              '1. Informações que Coletamos',
              'Coletamos apenas as informações necessárias para o funcionamento do aplicativo:\n\n'
              '• Dados de monitoramento agrícola (coordenadas GPS, observações)\n'
              '• Informações de talhões e culturas\n'
              '• Dados de infestação e ocorrências\n'
              '• Imagens para diagnóstico (opcional)\n'
              '• Configurações do aplicativo',
            ),
            _buildSection(
              '2. Como Utilizamos suas Informações',
              'Utilizamos seus dados exclusivamente para:\n\n'
              '• Processar análises agronômicas\n'
              '• Gerar relatórios e mapas de infestação\n'
              '• Melhorar a precisão do diagnóstico por IA\n'
              '• Personalizar recomendações\n'
              '• Manter a funcionalidade do aplicativo',
            ),
            _buildSection(
              '3. Compartilhamento de Dados',
              'NÃO compartilhamos seus dados com terceiros. Suas informações agrícolas permanecem:\n\n'
              '• Confidenciais e seguras\n'
              '• Armazenadas localmente no seu dispositivo\n'
              '• Protegidas por criptografia\n'
              '• Acessíveis apenas por você',
            ),
            _buildSection(
              '4. Armazenamento e Segurança',
              'Implementamos medidas de segurança rigorosas:\n\n'
              '• Criptografia de dados sensíveis\n'
              '• Armazenamento local seguro\n'
              '• Acesso protegido por autenticação\n'
              '• Backup automático dos seus dados',
            ),
            _buildSection(
              '5. Seus Direitos',
              'Você tem o direito de:\n\n'
              '• Acessar seus dados a qualquer momento\n'
              '• Exportar suas informações\n'
              '• Excluir dados específicos\n'
              '• Solicitar correção de informações\n'
              '• Revogar consentimentos',
            ),
            _buildSection(
              '6. Dados de Localização',
              'O aplicativo utiliza sua localização GPS para:\n\n'
              '• Marcar pontos de monitoramento\n'
              '• Gerar mapas precisos de infestação\n'
              '• Calcular áreas afetadas\n\n'
              'Estes dados são armazenados apenas no seu dispositivo e não são transmitidos para servidores externos.',
            ),
            _buildSection(
              '7. Menores de Idade',
              'O FortSmart Agro não coleta intencionalmente dados de menores de 18 anos. Se você é menor de idade, deve obter autorização dos pais ou responsáveis antes de utilizar o aplicativo.',
            ),
            _buildSection(
              '8. Alterações na Política',
              'Podemos atualizar esta política periodicamente. Notificaremos sobre mudanças significativas através do aplicativo. Recomendamos revisar esta política regularmente.',
            ),
            _buildSection(
              '9. Contato sobre Privacidade',
              'Para questões sobre privacidade e proteção de dados:\n\n'
              '📧 Email: fortsmart.agro@gmail.com\n'
              '📱 WhatsApp: +55 45 99126-1695\n\n'
              'Responderemos em até 48 horas úteis.',
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
            Icons.privacy_tip,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Política de Privacidade',
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
