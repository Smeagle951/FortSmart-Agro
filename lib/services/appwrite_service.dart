import 'package:appwrite/appwrite.dart';
import '../utils/logger.dart';

/// Serviço de integração com Appwrite
/// Autenticação, Storage e Database
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final Storage storage;

  bool _initialized = false;

  /// Inicializa o Appwrite
  Future<void> initialize({
    required String endpoint,
    required String projectId,
  }) async {
    if (_initialized) return;

    try {
      client = Client()
        ..setEndpoint(endpoint)
        ..setProject(projectId)
        ..setSelfSigned(status: true); // Para Render

      account = Account(client);
      databases = Databases(client);
      storage = Storage(client);

      _initialized = true;
      Logger.info('✅ Appwrite inicializado');
    } catch (e) {
      Logger.error('❌ Erro ao inicializar Appwrite: $e');
    }
  }

  // ========================================================================
  // AUTENTICAÇÃO (Desabilitado por enquanto)
  // ========================================================================

  /// Criar conta (quando habilitar autenticação)
  Future<Map<String, dynamic>> createAccount({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      Logger.info('✅ Conta criada com sucesso');
      return {'success': true, 'message': 'Conta criada'};
    } catch (e) {
      Logger.error('❌ Erro ao criar conta: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Login (quando habilitar autenticação)
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      Logger.info('✅ Login realizado');
      return {'success': true, 'message': 'Login realizado'};
    } catch (e) {
      Logger.error('❌ Erro no login: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      Logger.info('✅ Logout realizado');
    } catch (e) {
      Logger.error('❌ Erro no logout: $e');
    }
  }

  // ========================================================================
  // DATABASE
  // ========================================================================

  /// Criar documento
  Future<Map<String, dynamic>> createDocument({
    required String databaseId,
    required String collectionId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final document = await databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: data,
      );

      return {'success': true, 'document_id': document.$id};
    } catch (e) {
      Logger.error('❌ Erro ao criar documento: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Listar documentos
  Future<List<Map<String, dynamic>>> listDocuments({
    required String databaseId,
    required String collectionId,
    List<String>? queries,
  }) async {
    try {
      final documents = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries,
      );

      return documents.documents.map((d) => d.data).toList();
    } catch (e) {
      Logger.error('❌ Erro ao listar documentos: $e');
      return [];
    }
  }

  // ========================================================================
  // STORAGE (Upload de Imagens)
  // ========================================================================

  /// Upload de arquivo
  Future<Map<String, dynamic>> uploadFile({
    required String bucketId,
    required String filePath,
  }) async {
    try {
      final file = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: filePath),
      );

      Logger.info('✅ Arquivo enviado: ${file.$id}');

      return {
        'success': true,
        'file_id': file.$id,
      };
    } catch (e) {
      Logger.error('❌ Erro no upload: $e');
      return {'success': false, 'message': 'Erro: $e'};
    }
  }

  /// Obter URL de visualização do arquivo
  String getFilePreview({
    required String bucketId,
    required String fileId,
    int? width,
    int? height,
  }) {
    return '${client.endPoint}/storage/buckets/$bucketId/files/$fileId/preview?width=${width ?? 400}&height=${height ?? 400}&project=${client.config['project']}';
  }
}

