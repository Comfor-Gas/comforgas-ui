enum UserRole { chofer, vendedor, admin, gerente, adminIt, unknown }

class UserRoleMapper {
  static UserRole fromValue(dynamic value) {
    if (value == null) return UserRole.unknown;

    if (value is int) {
      switch (value) {
        case 1:
          return UserRole.chofer;
        case 2:
          return UserRole.vendedor;
        case 3:
          return UserRole.admin;
        case 4:
          return UserRole.gerente;
        case 5:
          return UserRole.adminIt;
        default:
          return UserRole.unknown;
      }
    }

    final normalized = value.toString().trim().toLowerCase();
    switch (normalized) {
      case '1':
      case 'chofer':
        return UserRole.chofer;
      case '2':
      case 'vendedor':
        return UserRole.vendedor;
      case '3':
      case 'admin':
      case 'administrador':
        return UserRole.admin;
      case '4':
      case 'gerente':
        return UserRole.gerente;
      case '5':
      case 'admin_it':
      case 'adminit':
      case 'administrador_it':
        return UserRole.adminIt;
      default:
        return UserRole.unknown;
    }
  }
}
