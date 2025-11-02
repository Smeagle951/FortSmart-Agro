enum MovementType {
  entry,
  exit,
}

extension MovementTypeExtension on MovementType {
  String get label {
    switch (this) {
      case MovementType.entry:
        return 'Entrada';
      case MovementType.exit:
        return 'Saída';
    }
  }
  
  String get icon {
    switch (this) {
      case MovementType.entry:
        return 'add_circle';
      case MovementType.exit:
        return 'remove_circle';
    }
  }
  
  bool get isEntry => this == MovementType.entry;
  bool get isExit => this == MovementType.exit;
}
