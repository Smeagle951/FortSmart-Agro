import 'package:flutter/material.dart';

class Validators {
  static FormFieldValidator<String> required(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return message;
      }
      return null;
    };
  }

  static FormFieldValidator<String> email() {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'E-mail é obrigatório';
      }
      
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'E-mail inválido';
      }
      
      return null;
    };
  }

  static FormFieldValidator<String> minLength(int length, String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Campo obrigatório';
      }
      
      if (value.length < length) {
        return message;
      }
      
      return null;
    };
  }

  static FormFieldValidator<String> numeric(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Campo obrigatório';
      }
      
      if (double.tryParse(value) == null) {
        return message;
      }
      
      return null;
    };
  }

  static FormFieldValidator<String> date(String message) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Data é obrigatória';
      }
      
      try {
        DateTime.parse(value);
        return null;
      } catch (e) {
        return message;
      }
    };
  }
}
