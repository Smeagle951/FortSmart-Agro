import 'package:shared_preferences/shared_preferences.dart';

/// Enum que define os tipos de usuário do sistema
enum UserRole {
  /// Administrador com acesso total ao sistema
  admin,
  
  /// Gerente com acesso a maioria das funcionalidades, exceto configurações avançadas
  manager,
  
  /// Técnico com acesso a monitoramento e aplicações
  technician,
  
  /// Operador com acesso limitado a registros de campo
  operator,
  
  /// Visualizador com acesso apenas para leitura
  viewer,
}

/// Enum que define as permissões disponíveis no sistema
enum Permission {
  // Permissões de estoque
  viewInventory,
  manageInventory,
  importInventory,
  exportInventory,
  
  // Permissões de movimentação de estoque
  viewInventoryMovements,
  createInventoryEntry,
  createInventoryExit,
  
  // Permissões de aplicação de defensivos
  viewPesticideApplications,
  createPesticideApplication,
  editPesticideApplication,
  deletePesticideApplication,
  
  // Permissões de monitoramento
  viewMonitoring,
  createMonitoring,
  editMonitoring,
  deleteMonitoring,
  
  // Permissões de administração
  manageUsers,
  manageSettings,
  viewReports,
  exportReports,
  performBackup,
  restoreBackup,
}

/// Classe para gerenciar permissões de usuário no sistema
class PermissionManager {
  static const String _userRoleKey = 'user_role';
  
  /// Mapa que define as permissões para cada tipo de usuário
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.admin: {
      // Administrador tem todas as permissões
      ...Permission.values.toSet(),
    },
    
    UserRole.manager: {
      // Permissões de estoque
      Permission.viewInventory,
      Permission.manageInventory,
      Permission.importInventory,
      Permission.exportInventory,
      
      // Permissões de movimentação de estoque
      Permission.viewInventoryMovements,
      Permission.createInventoryEntry,
      Permission.createInventoryExit,
      
      // Permissões de aplicação de defensivos
      Permission.viewPesticideApplications,
      Permission.createPesticideApplication,
      Permission.editPesticideApplication,
      Permission.deletePesticideApplication,
      
      // Permissões de monitoramento
      Permission.viewMonitoring,
      Permission.createMonitoring,
      Permission.editMonitoring,
      Permission.deleteMonitoring,
      
      // Permissões de administração (parcial)
      Permission.viewReports,
      Permission.exportReports,
      Permission.performBackup,
    },
    
    UserRole.technician: {
      // Permissões de estoque (parcial)
      Permission.viewInventory,
      
      // Permissões de movimentação de estoque (parcial)
      Permission.viewInventoryMovements,
      Permission.createInventoryExit,
      
      // Permissões de aplicação de defensivos
      Permission.viewPesticideApplications,
      Permission.createPesticideApplication,
      Permission.editPesticideApplication,
      
      // Permissões de monitoramento
      Permission.viewMonitoring,
      Permission.createMonitoring,
      Permission.editMonitoring,
      
      // Permissões de administração (parcial)
      Permission.viewReports,
    },
    
    UserRole.operator: {
      // Permissões de estoque (somente visualização)
      Permission.viewInventory,
      
      // Permissões de movimentação de estoque (somente visualização)
      Permission.viewInventoryMovements,
      
      // Permissões de aplicação de defensivos (parcial)
      Permission.viewPesticideApplications,
      Permission.createPesticideApplication,
      
      // Permissões de monitoramento (parcial)
      Permission.viewMonitoring,
      Permission.createMonitoring,
    },
    
    UserRole.viewer: {
      // Permissões somente de visualização
      Permission.viewInventory,
      Permission.viewInventoryMovements,
      Permission.viewPesticideApplications,
      Permission.viewMonitoring,
      Permission.viewReports,
    },
  };
  
  /// Obtém o papel do usuário atual
  static Future<UserRole> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleString = prefs.getString(_userRoleKey) ?? UserRole.viewer.name;
    return UserRole.values.firstWhere(
      (role) => role.name == roleString,
      orElse: () => UserRole.viewer,
    );
  }
  
  /// Define o papel do usuário atual
  static Future<void> setCurrentUserRole(UserRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userRoleKey, role.name);
  }
  
  /// Verifica se o usuário atual tem uma permissão específica
  static Future<bool> hasPermission(Permission permission) async {
    final userRole = await getCurrentUserRole();
    return _rolePermissions[userRole]?.contains(permission) ?? false;
  }
  
  /// Verifica se o usuário atual tem todas as permissões especificadas
  static Future<bool> hasAllPermissions(List<Permission> permissions) async {
    final userRole = await getCurrentUserRole();
    final userPermissions = _rolePermissions[userRole] ?? {};
    return permissions.every((permission) => userPermissions.contains(permission));
  }
  
  /// Verifica se o usuário atual tem pelo menos uma das permissões especificadas
  static Future<bool> hasAnyPermission(List<Permission> permissions) async {
    final userRole = await getCurrentUserRole();
    final userPermissions = _rolePermissions[userRole] ?? {};
    return permissions.any((permission) => userPermissions.contains(permission));
  }
  
  /// Obtém todas as permissões do usuário atual
  static Future<Set<Permission>> getCurrentUserPermissions() async {
    final userRole = await getCurrentUserRole();
    return _rolePermissions[userRole] ?? {};
  }
  
  /// Obtém o nome formatado do papel do usuário
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.manager:
        return 'Gerente';
      case UserRole.technician:
        return 'Técnico';
      case UserRole.operator:
        return 'Operador';
      case UserRole.viewer:
        return 'Visualizador';
    }
  }
  
  /// Obtém a descrição do papel do usuário
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Acesso total ao sistema, incluindo configurações avançadas e gerenciamento de usuários.';
      case UserRole.manager:
        return 'Acesso à maioria das funcionalidades, exceto configurações avançadas e gerenciamento de usuários.';
      case UserRole.technician:
        return 'Acesso a monitoramento, aplicações e visualização de estoque.';
      case UserRole.operator:
        return 'Acesso limitado a registros de campo e visualização de dados.';
      case UserRole.viewer:
        return 'Acesso somente para visualização de dados, sem permissão para criar ou editar.';
    }
  }
}
