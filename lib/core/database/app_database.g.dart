// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CulturasTable extends Culturas with TableInfo<$CulturasTable, Cultura> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CulturasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconePathMeta =
      const VerificationMeta('iconePath');
  @override
  late final GeneratedColumn<String> iconePath = GeneratedColumn<String>(
      'icone_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [id, nome, iconePath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'culturas';
  @override
  VerificationContext validateIntegrity(Insertable<Cultura> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('icone_path')) {
      context.handle(_iconePathMeta,
          iconePath.isAcceptableOrUnknown(data['icone_path']!, _iconePathMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Cultura map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cultura(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      iconePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icone_path']),
    );
  }

  @override
  $CulturasTable createAlias(String alias) {
    return $CulturasTable(attachedDatabase, alias);
  }
}

class Cultura extends DataClass implements Insertable<Cultura> {
  final int id;
  final String nome;
  final String? iconePath;
  const Cultura({required this.id, required this.nome, this.iconePath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || iconePath != null) {
      map['icone_path'] = Variable<String>(iconePath);
    }
    return map;
  }

  CulturasCompanion toCompanion(bool nullToAbsent) {
    return CulturasCompanion(
      id: Value(id),
      nome: Value(nome),
      iconePath: iconePath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconePath),
    );
  }

  factory Cultura.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cultura(
      id: serializer.fromJson<int>(json['id']),
      nome: serializer.fromJson<String>(json['nome']),
      iconePath: serializer.fromJson<String?>(json['iconePath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nome': serializer.toJson<String>(nome),
      'iconePath': serializer.toJson<String?>(iconePath),
    };
  }

  Cultura copyWith(
          {int? id,
          String? nome,
          Value<String?> iconePath = const Value.absent()}) =>
      Cultura(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        iconePath: iconePath.present ? iconePath.value : this.iconePath,
      );
  Cultura copyWithCompanion(CulturasCompanion data) {
    return Cultura(
      id: data.id.present ? data.id.value : this.id,
      nome: data.nome.present ? data.nome.value : this.nome,
      iconePath: data.iconePath.present ? data.iconePath.value : this.iconePath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cultura(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('iconePath: $iconePath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nome, iconePath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cultura &&
          other.id == this.id &&
          other.nome == this.nome &&
          other.iconePath == this.iconePath);
}

class CulturasCompanion extends UpdateCompanion<Cultura> {
  final Value<int> id;
  final Value<String> nome;
  final Value<String?> iconePath;
  const CulturasCompanion({
    this.id = const Value.absent(),
    this.nome = const Value.absent(),
    this.iconePath = const Value.absent(),
  });
  CulturasCompanion.insert({
    this.id = const Value.absent(),
    required String nome,
    this.iconePath = const Value.absent(),
  }) : nome = Value(nome);
  static Insertable<Cultura> custom({
    Expression<int>? id,
    Expression<String>? nome,
    Expression<String>? iconePath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nome != null) 'nome': nome,
      if (iconePath != null) 'icone_path': iconePath,
    });
  }

  CulturasCompanion copyWith(
      {Value<int>? id, Value<String>? nome, Value<String?>? iconePath}) {
    return CulturasCompanion(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      iconePath: iconePath ?? this.iconePath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (iconePath.present) {
      map['icone_path'] = Variable<String>(iconePath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CulturasCompanion(')
          ..write('id: $id, ')
          ..write('nome: $nome, ')
          ..write('iconePath: $iconePath')
          ..write(')'))
        .toString();
  }
}

class $VariedadesTable extends Variedades
    with TableInfo<$VariedadesTable, Variedade> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VariedadesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _culturaIdMeta =
      const VerificationMeta('culturaId');
  @override
  late final GeneratedColumn<int> culturaId = GeneratedColumn<int>(
      'cultura_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES culturas (id)'));
  static const VerificationMeta _nomeMeta = const VerificationMeta('nome');
  @override
  late final GeneratedColumn<String> nome = GeneratedColumn<String>(
      'nome', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cicloMeta = const VerificationMeta('ciclo');
  @override
  late final GeneratedColumn<String> ciclo = GeneratedColumn<String>(
      'ciclo', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, culturaId, nome, ciclo, observacoes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'variedades';
  @override
  VerificationContext validateIntegrity(Insertable<Variedade> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cultura_id')) {
      context.handle(_culturaIdMeta,
          culturaId.isAcceptableOrUnknown(data['cultura_id']!, _culturaIdMeta));
    } else if (isInserting) {
      context.missing(_culturaIdMeta);
    }
    if (data.containsKey('nome')) {
      context.handle(
          _nomeMeta, nome.isAcceptableOrUnknown(data['nome']!, _nomeMeta));
    } else if (isInserting) {
      context.missing(_nomeMeta);
    }
    if (data.containsKey('ciclo')) {
      context.handle(
          _cicloMeta, ciclo.isAcceptableOrUnknown(data['ciclo']!, _cicloMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Variedade map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Variedade(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      culturaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cultura_id'])!,
      nome: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome'])!,
      ciclo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ciclo']),
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
    );
  }

  @override
  $VariedadesTable createAlias(String alias) {
    return $VariedadesTable(attachedDatabase, alias);
  }
}

class Variedade extends DataClass implements Insertable<Variedade> {
  final int id;
  final int culturaId;
  final String nome;
  final String? ciclo;
  final String? observacoes;
  const Variedade(
      {required this.id,
      required this.culturaId,
      required this.nome,
      this.ciclo,
      this.observacoes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cultura_id'] = Variable<int>(culturaId);
    map['nome'] = Variable<String>(nome);
    if (!nullToAbsent || ciclo != null) {
      map['ciclo'] = Variable<String>(ciclo);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    return map;
  }

  VariedadesCompanion toCompanion(bool nullToAbsent) {
    return VariedadesCompanion(
      id: Value(id),
      culturaId: Value(culturaId),
      nome: Value(nome),
      ciclo:
          ciclo == null && nullToAbsent ? const Value.absent() : Value(ciclo),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
    );
  }

  factory Variedade.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Variedade(
      id: serializer.fromJson<int>(json['id']),
      culturaId: serializer.fromJson<int>(json['culturaId']),
      nome: serializer.fromJson<String>(json['nome']),
      ciclo: serializer.fromJson<String?>(json['ciclo']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'culturaId': serializer.toJson<int>(culturaId),
      'nome': serializer.toJson<String>(nome),
      'ciclo': serializer.toJson<String?>(ciclo),
      'observacoes': serializer.toJson<String?>(observacoes),
    };
  }

  Variedade copyWith(
          {int? id,
          int? culturaId,
          String? nome,
          Value<String?> ciclo = const Value.absent(),
          Value<String?> observacoes = const Value.absent()}) =>
      Variedade(
        id: id ?? this.id,
        culturaId: culturaId ?? this.culturaId,
        nome: nome ?? this.nome,
        ciclo: ciclo.present ? ciclo.value : this.ciclo,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
      );
  Variedade copyWithCompanion(VariedadesCompanion data) {
    return Variedade(
      id: data.id.present ? data.id.value : this.id,
      culturaId: data.culturaId.present ? data.culturaId.value : this.culturaId,
      nome: data.nome.present ? data.nome.value : this.nome,
      ciclo: data.ciclo.present ? data.ciclo.value : this.ciclo,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Variedade(')
          ..write('id: $id, ')
          ..write('culturaId: $culturaId, ')
          ..write('nome: $nome, ')
          ..write('ciclo: $ciclo, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, culturaId, nome, ciclo, observacoes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Variedade &&
          other.id == this.id &&
          other.culturaId == this.culturaId &&
          other.nome == this.nome &&
          other.ciclo == this.ciclo &&
          other.observacoes == this.observacoes);
}

class VariedadesCompanion extends UpdateCompanion<Variedade> {
  final Value<int> id;
  final Value<int> culturaId;
  final Value<String> nome;
  final Value<String?> ciclo;
  final Value<String?> observacoes;
  const VariedadesCompanion({
    this.id = const Value.absent(),
    this.culturaId = const Value.absent(),
    this.nome = const Value.absent(),
    this.ciclo = const Value.absent(),
    this.observacoes = const Value.absent(),
  });
  VariedadesCompanion.insert({
    this.id = const Value.absent(),
    required int culturaId,
    required String nome,
    this.ciclo = const Value.absent(),
    this.observacoes = const Value.absent(),
  })  : culturaId = Value(culturaId),
        nome = Value(nome);
  static Insertable<Variedade> custom({
    Expression<int>? id,
    Expression<int>? culturaId,
    Expression<String>? nome,
    Expression<String>? ciclo,
    Expression<String>? observacoes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (culturaId != null) 'cultura_id': culturaId,
      if (nome != null) 'nome': nome,
      if (ciclo != null) 'ciclo': ciclo,
      if (observacoes != null) 'observacoes': observacoes,
    });
  }

  VariedadesCompanion copyWith(
      {Value<int>? id,
      Value<int>? culturaId,
      Value<String>? nome,
      Value<String?>? ciclo,
      Value<String?>? observacoes}) {
    return VariedadesCompanion(
      id: id ?? this.id,
      culturaId: culturaId ?? this.culturaId,
      nome: nome ?? this.nome,
      ciclo: ciclo ?? this.ciclo,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (culturaId.present) {
      map['cultura_id'] = Variable<int>(culturaId.value);
    }
    if (nome.present) {
      map['nome'] = Variable<String>(nome.value);
    }
    if (ciclo.present) {
      map['ciclo'] = Variable<String>(ciclo.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VariedadesCompanion(')
          ..write('id: $id, ')
          ..write('culturaId: $culturaId, ')
          ..write('nome: $nome, ')
          ..write('ciclo: $ciclo, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }
}

class $OrganismosTable extends Organismos
    with TableInfo<$OrganismosTable, Organismo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrganismosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
      'tipo', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeComumMeta =
      const VerificationMeta('nomeComum');
  @override
  late final GeneratedColumn<String> nomeComum = GeneratedColumn<String>(
      'nome_comum', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nomeCientificoMeta =
      const VerificationMeta('nomeCientifico');
  @override
  late final GeneratedColumn<String> nomeCientifico = GeneratedColumn<String>(
      'nome_cientifico', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoriaMeta =
      const VerificationMeta('categoria');
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
      'categoria', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _iconePathMeta =
      const VerificationMeta('iconePath');
  @override
  late final GeneratedColumn<String> iconePath = GeneratedColumn<String>(
      'icone_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sintomaDescricaoMeta =
      const VerificationMeta('sintomaDescricao');
  @override
  late final GeneratedColumn<String> sintomaDescricao = GeneratedColumn<String>(
      'sintoma_descricao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _danoEconomicoMeta =
      const VerificationMeta('danoEconomico');
  @override
  late final GeneratedColumn<String> danoEconomico = GeneratedColumn<String>(
      'dano_economico', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _partesAfetadasMeta =
      const VerificationMeta('partesAfetadas');
  @override
  late final GeneratedColumn<String> partesAfetadas = GeneratedColumn<String>(
      'partes_afetadas', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _fenologiaMeta =
      const VerificationMeta('fenologia');
  @override
  late final GeneratedColumn<String> fenologia = GeneratedColumn<String>(
      'fenologia', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _niveisAcaoMeta =
      const VerificationMeta('niveisAcao');
  @override
  late final GeneratedColumn<String> niveisAcao = GeneratedColumn<String>(
      'niveis_acao', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _manejoQuimicoMeta =
      const VerificationMeta('manejoQuimico');
  @override
  late final GeneratedColumn<String> manejoQuimico = GeneratedColumn<String>(
      'manejo_quimico', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _manejoBiologicoMeta =
      const VerificationMeta('manejoBiologico');
  @override
  late final GeneratedColumn<String> manejoBiologico = GeneratedColumn<String>(
      'manejo_biologico', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _manejoCulturalMeta =
      const VerificationMeta('manejoCultural');
  @override
  late final GeneratedColumn<String> manejoCultural = GeneratedColumn<String>(
      'manejo_cultural', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _observacoesMeta =
      const VerificationMeta('observacoes');
  @override
  late final GeneratedColumn<String> observacoes = GeneratedColumn<String>(
      'observacoes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tipo,
        nomeComum,
        nomeCientifico,
        categoria,
        iconePath,
        sintomaDescricao,
        danoEconomico,
        partesAfetadas,
        fenologia,
        niveisAcao,
        manejoQuimico,
        manejoBiologico,
        manejoCultural,
        observacoes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'organismos';
  @override
  VerificationContext validateIntegrity(Insertable<Organismo> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tipo')) {
      context.handle(
          _tipoMeta, tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta));
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('nome_comum')) {
      context.handle(_nomeComumMeta,
          nomeComum.isAcceptableOrUnknown(data['nome_comum']!, _nomeComumMeta));
    } else if (isInserting) {
      context.missing(_nomeComumMeta);
    }
    if (data.containsKey('nome_cientifico')) {
      context.handle(
          _nomeCientificoMeta,
          nomeCientifico.isAcceptableOrUnknown(
              data['nome_cientifico']!, _nomeCientificoMeta));
    }
    if (data.containsKey('categoria')) {
      context.handle(_categoriaMeta,
          categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta));
    }
    if (data.containsKey('icone_path')) {
      context.handle(_iconePathMeta,
          iconePath.isAcceptableOrUnknown(data['icone_path']!, _iconePathMeta));
    }
    if (data.containsKey('sintoma_descricao')) {
      context.handle(
          _sintomaDescricaoMeta,
          sintomaDescricao.isAcceptableOrUnknown(
              data['sintoma_descricao']!, _sintomaDescricaoMeta));
    }
    if (data.containsKey('dano_economico')) {
      context.handle(
          _danoEconomicoMeta,
          danoEconomico.isAcceptableOrUnknown(
              data['dano_economico']!, _danoEconomicoMeta));
    }
    if (data.containsKey('partes_afetadas')) {
      context.handle(
          _partesAfetadasMeta,
          partesAfetadas.isAcceptableOrUnknown(
              data['partes_afetadas']!, _partesAfetadasMeta));
    }
    if (data.containsKey('fenologia')) {
      context.handle(_fenologiaMeta,
          fenologia.isAcceptableOrUnknown(data['fenologia']!, _fenologiaMeta));
    }
    if (data.containsKey('niveis_acao')) {
      context.handle(
          _niveisAcaoMeta,
          niveisAcao.isAcceptableOrUnknown(
              data['niveis_acao']!, _niveisAcaoMeta));
    }
    if (data.containsKey('manejo_quimico')) {
      context.handle(
          _manejoQuimicoMeta,
          manejoQuimico.isAcceptableOrUnknown(
              data['manejo_quimico']!, _manejoQuimicoMeta));
    }
    if (data.containsKey('manejo_biologico')) {
      context.handle(
          _manejoBiologicoMeta,
          manejoBiologico.isAcceptableOrUnknown(
              data['manejo_biologico']!, _manejoBiologicoMeta));
    }
    if (data.containsKey('manejo_cultural')) {
      context.handle(
          _manejoCulturalMeta,
          manejoCultural.isAcceptableOrUnknown(
              data['manejo_cultural']!, _manejoCulturalMeta));
    }
    if (data.containsKey('observacoes')) {
      context.handle(
          _observacoesMeta,
          observacoes.isAcceptableOrUnknown(
              data['observacoes']!, _observacoesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Organismo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Organismo(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tipo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tipo'])!,
      nomeComum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome_comum'])!,
      nomeCientifico: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nome_cientifico']),
      categoria: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}categoria']),
      iconePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icone_path']),
      sintomaDescricao: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}sintoma_descricao']),
      danoEconomico: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dano_economico']),
      partesAfetadas: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}partes_afetadas']),
      fenologia: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}fenologia']),
      niveisAcao: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}niveis_acao']),
      manejoQuimico: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manejo_quimico']),
      manejoBiologico: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}manejo_biologico']),
      manejoCultural: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}manejo_cultural']),
      observacoes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}observacoes']),
    );
  }

  @override
  $OrganismosTable createAlias(String alias) {
    return $OrganismosTable(attachedDatabase, alias);
  }
}

class Organismo extends DataClass implements Insertable<Organismo> {
  final int id;
  final String tipo;
  final String nomeComum;
  final String? nomeCientifico;
  final String? categoria;
  final String? iconePath;
  final String? sintomaDescricao;
  final String? danoEconomico;
  final String? partesAfetadas;
  final String? fenologia;
  final String? niveisAcao;
  final String? manejoQuimico;
  final String? manejoBiologico;
  final String? manejoCultural;
  final String? observacoes;
  const Organismo(
      {required this.id,
      required this.tipo,
      required this.nomeComum,
      this.nomeCientifico,
      this.categoria,
      this.iconePath,
      this.sintomaDescricao,
      this.danoEconomico,
      this.partesAfetadas,
      this.fenologia,
      this.niveisAcao,
      this.manejoQuimico,
      this.manejoBiologico,
      this.manejoCultural,
      this.observacoes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tipo'] = Variable<String>(tipo);
    map['nome_comum'] = Variable<String>(nomeComum);
    if (!nullToAbsent || nomeCientifico != null) {
      map['nome_cientifico'] = Variable<String>(nomeCientifico);
    }
    if (!nullToAbsent || categoria != null) {
      map['categoria'] = Variable<String>(categoria);
    }
    if (!nullToAbsent || iconePath != null) {
      map['icone_path'] = Variable<String>(iconePath);
    }
    if (!nullToAbsent || sintomaDescricao != null) {
      map['sintoma_descricao'] = Variable<String>(sintomaDescricao);
    }
    if (!nullToAbsent || danoEconomico != null) {
      map['dano_economico'] = Variable<String>(danoEconomico);
    }
    if (!nullToAbsent || partesAfetadas != null) {
      map['partes_afetadas'] = Variable<String>(partesAfetadas);
    }
    if (!nullToAbsent || fenologia != null) {
      map['fenologia'] = Variable<String>(fenologia);
    }
    if (!nullToAbsent || niveisAcao != null) {
      map['niveis_acao'] = Variable<String>(niveisAcao);
    }
    if (!nullToAbsent || manejoQuimico != null) {
      map['manejo_quimico'] = Variable<String>(manejoQuimico);
    }
    if (!nullToAbsent || manejoBiologico != null) {
      map['manejo_biologico'] = Variable<String>(manejoBiologico);
    }
    if (!nullToAbsent || manejoCultural != null) {
      map['manejo_cultural'] = Variable<String>(manejoCultural);
    }
    if (!nullToAbsent || observacoes != null) {
      map['observacoes'] = Variable<String>(observacoes);
    }
    return map;
  }

  OrganismosCompanion toCompanion(bool nullToAbsent) {
    return OrganismosCompanion(
      id: Value(id),
      tipo: Value(tipo),
      nomeComum: Value(nomeComum),
      nomeCientifico: nomeCientifico == null && nullToAbsent
          ? const Value.absent()
          : Value(nomeCientifico),
      categoria: categoria == null && nullToAbsent
          ? const Value.absent()
          : Value(categoria),
      iconePath: iconePath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconePath),
      sintomaDescricao: sintomaDescricao == null && nullToAbsent
          ? const Value.absent()
          : Value(sintomaDescricao),
      danoEconomico: danoEconomico == null && nullToAbsent
          ? const Value.absent()
          : Value(danoEconomico),
      partesAfetadas: partesAfetadas == null && nullToAbsent
          ? const Value.absent()
          : Value(partesAfetadas),
      fenologia: fenologia == null && nullToAbsent
          ? const Value.absent()
          : Value(fenologia),
      niveisAcao: niveisAcao == null && nullToAbsent
          ? const Value.absent()
          : Value(niveisAcao),
      manejoQuimico: manejoQuimico == null && nullToAbsent
          ? const Value.absent()
          : Value(manejoQuimico),
      manejoBiologico: manejoBiologico == null && nullToAbsent
          ? const Value.absent()
          : Value(manejoBiologico),
      manejoCultural: manejoCultural == null && nullToAbsent
          ? const Value.absent()
          : Value(manejoCultural),
      observacoes: observacoes == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoes),
    );
  }

  factory Organismo.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Organismo(
      id: serializer.fromJson<int>(json['id']),
      tipo: serializer.fromJson<String>(json['tipo']),
      nomeComum: serializer.fromJson<String>(json['nomeComum']),
      nomeCientifico: serializer.fromJson<String?>(json['nomeCientifico']),
      categoria: serializer.fromJson<String?>(json['categoria']),
      iconePath: serializer.fromJson<String?>(json['iconePath']),
      sintomaDescricao: serializer.fromJson<String?>(json['sintomaDescricao']),
      danoEconomico: serializer.fromJson<String?>(json['danoEconomico']),
      partesAfetadas: serializer.fromJson<String?>(json['partesAfetadas']),
      fenologia: serializer.fromJson<String?>(json['fenologia']),
      niveisAcao: serializer.fromJson<String?>(json['niveisAcao']),
      manejoQuimico: serializer.fromJson<String?>(json['manejoQuimico']),
      manejoBiologico: serializer.fromJson<String?>(json['manejoBiologico']),
      manejoCultural: serializer.fromJson<String?>(json['manejoCultural']),
      observacoes: serializer.fromJson<String?>(json['observacoes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tipo': serializer.toJson<String>(tipo),
      'nomeComum': serializer.toJson<String>(nomeComum),
      'nomeCientifico': serializer.toJson<String?>(nomeCientifico),
      'categoria': serializer.toJson<String?>(categoria),
      'iconePath': serializer.toJson<String?>(iconePath),
      'sintomaDescricao': serializer.toJson<String?>(sintomaDescricao),
      'danoEconomico': serializer.toJson<String?>(danoEconomico),
      'partesAfetadas': serializer.toJson<String?>(partesAfetadas),
      'fenologia': serializer.toJson<String?>(fenologia),
      'niveisAcao': serializer.toJson<String?>(niveisAcao),
      'manejoQuimico': serializer.toJson<String?>(manejoQuimico),
      'manejoBiologico': serializer.toJson<String?>(manejoBiologico),
      'manejoCultural': serializer.toJson<String?>(manejoCultural),
      'observacoes': serializer.toJson<String?>(observacoes),
    };
  }

  Organismo copyWith(
          {int? id,
          String? tipo,
          String? nomeComum,
          Value<String?> nomeCientifico = const Value.absent(),
          Value<String?> categoria = const Value.absent(),
          Value<String?> iconePath = const Value.absent(),
          Value<String?> sintomaDescricao = const Value.absent(),
          Value<String?> danoEconomico = const Value.absent(),
          Value<String?> partesAfetadas = const Value.absent(),
          Value<String?> fenologia = const Value.absent(),
          Value<String?> niveisAcao = const Value.absent(),
          Value<String?> manejoQuimico = const Value.absent(),
          Value<String?> manejoBiologico = const Value.absent(),
          Value<String?> manejoCultural = const Value.absent(),
          Value<String?> observacoes = const Value.absent()}) =>
      Organismo(
        id: id ?? this.id,
        tipo: tipo ?? this.tipo,
        nomeComum: nomeComum ?? this.nomeComum,
        nomeCientifico:
            nomeCientifico.present ? nomeCientifico.value : this.nomeCientifico,
        categoria: categoria.present ? categoria.value : this.categoria,
        iconePath: iconePath.present ? iconePath.value : this.iconePath,
        sintomaDescricao: sintomaDescricao.present
            ? sintomaDescricao.value
            : this.sintomaDescricao,
        danoEconomico:
            danoEconomico.present ? danoEconomico.value : this.danoEconomico,
        partesAfetadas:
            partesAfetadas.present ? partesAfetadas.value : this.partesAfetadas,
        fenologia: fenologia.present ? fenologia.value : this.fenologia,
        niveisAcao: niveisAcao.present ? niveisAcao.value : this.niveisAcao,
        manejoQuimico:
            manejoQuimico.present ? manejoQuimico.value : this.manejoQuimico,
        manejoBiologico: manejoBiologico.present
            ? manejoBiologico.value
            : this.manejoBiologico,
        manejoCultural:
            manejoCultural.present ? manejoCultural.value : this.manejoCultural,
        observacoes: observacoes.present ? observacoes.value : this.observacoes,
      );
  Organismo copyWithCompanion(OrganismosCompanion data) {
    return Organismo(
      id: data.id.present ? data.id.value : this.id,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      nomeComum: data.nomeComum.present ? data.nomeComum.value : this.nomeComum,
      nomeCientifico: data.nomeCientifico.present
          ? data.nomeCientifico.value
          : this.nomeCientifico,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      iconePath: data.iconePath.present ? data.iconePath.value : this.iconePath,
      sintomaDescricao: data.sintomaDescricao.present
          ? data.sintomaDescricao.value
          : this.sintomaDescricao,
      danoEconomico: data.danoEconomico.present
          ? data.danoEconomico.value
          : this.danoEconomico,
      partesAfetadas: data.partesAfetadas.present
          ? data.partesAfetadas.value
          : this.partesAfetadas,
      fenologia: data.fenologia.present ? data.fenologia.value : this.fenologia,
      niveisAcao:
          data.niveisAcao.present ? data.niveisAcao.value : this.niveisAcao,
      manejoQuimico: data.manejoQuimico.present
          ? data.manejoQuimico.value
          : this.manejoQuimico,
      manejoBiologico: data.manejoBiologico.present
          ? data.manejoBiologico.value
          : this.manejoBiologico,
      manejoCultural: data.manejoCultural.present
          ? data.manejoCultural.value
          : this.manejoCultural,
      observacoes:
          data.observacoes.present ? data.observacoes.value : this.observacoes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Organismo(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('nomeComum: $nomeComum, ')
          ..write('nomeCientifico: $nomeCientifico, ')
          ..write('categoria: $categoria, ')
          ..write('iconePath: $iconePath, ')
          ..write('sintomaDescricao: $sintomaDescricao, ')
          ..write('danoEconomico: $danoEconomico, ')
          ..write('partesAfetadas: $partesAfetadas, ')
          ..write('fenologia: $fenologia, ')
          ..write('niveisAcao: $niveisAcao, ')
          ..write('manejoQuimico: $manejoQuimico, ')
          ..write('manejoBiologico: $manejoBiologico, ')
          ..write('manejoCultural: $manejoCultural, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tipo,
      nomeComum,
      nomeCientifico,
      categoria,
      iconePath,
      sintomaDescricao,
      danoEconomico,
      partesAfetadas,
      fenologia,
      niveisAcao,
      manejoQuimico,
      manejoBiologico,
      manejoCultural,
      observacoes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Organismo &&
          other.id == this.id &&
          other.tipo == this.tipo &&
          other.nomeComum == this.nomeComum &&
          other.nomeCientifico == this.nomeCientifico &&
          other.categoria == this.categoria &&
          other.iconePath == this.iconePath &&
          other.sintomaDescricao == this.sintomaDescricao &&
          other.danoEconomico == this.danoEconomico &&
          other.partesAfetadas == this.partesAfetadas &&
          other.fenologia == this.fenologia &&
          other.niveisAcao == this.niveisAcao &&
          other.manejoQuimico == this.manejoQuimico &&
          other.manejoBiologico == this.manejoBiologico &&
          other.manejoCultural == this.manejoCultural &&
          other.observacoes == this.observacoes);
}

class OrganismosCompanion extends UpdateCompanion<Organismo> {
  final Value<int> id;
  final Value<String> tipo;
  final Value<String> nomeComum;
  final Value<String?> nomeCientifico;
  final Value<String?> categoria;
  final Value<String?> iconePath;
  final Value<String?> sintomaDescricao;
  final Value<String?> danoEconomico;
  final Value<String?> partesAfetadas;
  final Value<String?> fenologia;
  final Value<String?> niveisAcao;
  final Value<String?> manejoQuimico;
  final Value<String?> manejoBiologico;
  final Value<String?> manejoCultural;
  final Value<String?> observacoes;
  const OrganismosCompanion({
    this.id = const Value.absent(),
    this.tipo = const Value.absent(),
    this.nomeComum = const Value.absent(),
    this.nomeCientifico = const Value.absent(),
    this.categoria = const Value.absent(),
    this.iconePath = const Value.absent(),
    this.sintomaDescricao = const Value.absent(),
    this.danoEconomico = const Value.absent(),
    this.partesAfetadas = const Value.absent(),
    this.fenologia = const Value.absent(),
    this.niveisAcao = const Value.absent(),
    this.manejoQuimico = const Value.absent(),
    this.manejoBiologico = const Value.absent(),
    this.manejoCultural = const Value.absent(),
    this.observacoes = const Value.absent(),
  });
  OrganismosCompanion.insert({
    this.id = const Value.absent(),
    required String tipo,
    required String nomeComum,
    this.nomeCientifico = const Value.absent(),
    this.categoria = const Value.absent(),
    this.iconePath = const Value.absent(),
    this.sintomaDescricao = const Value.absent(),
    this.danoEconomico = const Value.absent(),
    this.partesAfetadas = const Value.absent(),
    this.fenologia = const Value.absent(),
    this.niveisAcao = const Value.absent(),
    this.manejoQuimico = const Value.absent(),
    this.manejoBiologico = const Value.absent(),
    this.manejoCultural = const Value.absent(),
    this.observacoes = const Value.absent(),
  })  : tipo = Value(tipo),
        nomeComum = Value(nomeComum);
  static Insertable<Organismo> custom({
    Expression<int>? id,
    Expression<String>? tipo,
    Expression<String>? nomeComum,
    Expression<String>? nomeCientifico,
    Expression<String>? categoria,
    Expression<String>? iconePath,
    Expression<String>? sintomaDescricao,
    Expression<String>? danoEconomico,
    Expression<String>? partesAfetadas,
    Expression<String>? fenologia,
    Expression<String>? niveisAcao,
    Expression<String>? manejoQuimico,
    Expression<String>? manejoBiologico,
    Expression<String>? manejoCultural,
    Expression<String>? observacoes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tipo != null) 'tipo': tipo,
      if (nomeComum != null) 'nome_comum': nomeComum,
      if (nomeCientifico != null) 'nome_cientifico': nomeCientifico,
      if (categoria != null) 'categoria': categoria,
      if (iconePath != null) 'icone_path': iconePath,
      if (sintomaDescricao != null) 'sintoma_descricao': sintomaDescricao,
      if (danoEconomico != null) 'dano_economico': danoEconomico,
      if (partesAfetadas != null) 'partes_afetadas': partesAfetadas,
      if (fenologia != null) 'fenologia': fenologia,
      if (niveisAcao != null) 'niveis_acao': niveisAcao,
      if (manejoQuimico != null) 'manejo_quimico': manejoQuimico,
      if (manejoBiologico != null) 'manejo_biologico': manejoBiologico,
      if (manejoCultural != null) 'manejo_cultural': manejoCultural,
      if (observacoes != null) 'observacoes': observacoes,
    });
  }

  OrganismosCompanion copyWith(
      {Value<int>? id,
      Value<String>? tipo,
      Value<String>? nomeComum,
      Value<String?>? nomeCientifico,
      Value<String?>? categoria,
      Value<String?>? iconePath,
      Value<String?>? sintomaDescricao,
      Value<String?>? danoEconomico,
      Value<String?>? partesAfetadas,
      Value<String?>? fenologia,
      Value<String?>? niveisAcao,
      Value<String?>? manejoQuimico,
      Value<String?>? manejoBiologico,
      Value<String?>? manejoCultural,
      Value<String?>? observacoes}) {
    return OrganismosCompanion(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      nomeComum: nomeComum ?? this.nomeComum,
      nomeCientifico: nomeCientifico ?? this.nomeCientifico,
      categoria: categoria ?? this.categoria,
      iconePath: iconePath ?? this.iconePath,
      sintomaDescricao: sintomaDescricao ?? this.sintomaDescricao,
      danoEconomico: danoEconomico ?? this.danoEconomico,
      partesAfetadas: partesAfetadas ?? this.partesAfetadas,
      fenologia: fenologia ?? this.fenologia,
      niveisAcao: niveisAcao ?? this.niveisAcao,
      manejoQuimico: manejoQuimico ?? this.manejoQuimico,
      manejoBiologico: manejoBiologico ?? this.manejoBiologico,
      manejoCultural: manejoCultural ?? this.manejoCultural,
      observacoes: observacoes ?? this.observacoes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (nomeComum.present) {
      map['nome_comum'] = Variable<String>(nomeComum.value);
    }
    if (nomeCientifico.present) {
      map['nome_cientifico'] = Variable<String>(nomeCientifico.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (iconePath.present) {
      map['icone_path'] = Variable<String>(iconePath.value);
    }
    if (sintomaDescricao.present) {
      map['sintoma_descricao'] = Variable<String>(sintomaDescricao.value);
    }
    if (danoEconomico.present) {
      map['dano_economico'] = Variable<String>(danoEconomico.value);
    }
    if (partesAfetadas.present) {
      map['partes_afetadas'] = Variable<String>(partesAfetadas.value);
    }
    if (fenologia.present) {
      map['fenologia'] = Variable<String>(fenologia.value);
    }
    if (niveisAcao.present) {
      map['niveis_acao'] = Variable<String>(niveisAcao.value);
    }
    if (manejoQuimico.present) {
      map['manejo_quimico'] = Variable<String>(manejoQuimico.value);
    }
    if (manejoBiologico.present) {
      map['manejo_biologico'] = Variable<String>(manejoBiologico.value);
    }
    if (manejoCultural.present) {
      map['manejo_cultural'] = Variable<String>(manejoCultural.value);
    }
    if (observacoes.present) {
      map['observacoes'] = Variable<String>(observacoes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrganismosCompanion(')
          ..write('id: $id, ')
          ..write('tipo: $tipo, ')
          ..write('nomeComum: $nomeComum, ')
          ..write('nomeCientifico: $nomeCientifico, ')
          ..write('categoria: $categoria, ')
          ..write('iconePath: $iconePath, ')
          ..write('sintomaDescricao: $sintomaDescricao, ')
          ..write('danoEconomico: $danoEconomico, ')
          ..write('partesAfetadas: $partesAfetadas, ')
          ..write('fenologia: $fenologia, ')
          ..write('niveisAcao: $niveisAcao, ')
          ..write('manejoQuimico: $manejoQuimico, ')
          ..write('manejoBiologico: $manejoBiologico, ')
          ..write('manejoCultural: $manejoCultural, ')
          ..write('observacoes: $observacoes')
          ..write(')'))
        .toString();
  }
}

class $CulturaOrganismoTable extends CulturaOrganismo
    with TableInfo<$CulturaOrganismoTable, CulturaOrganismoData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CulturaOrganismoTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _culturaIdMeta =
      const VerificationMeta('culturaId');
  @override
  late final GeneratedColumn<int> culturaId = GeneratedColumn<int>(
      'cultura_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES culturas (id)'));
  static const VerificationMeta _organismoIdMeta =
      const VerificationMeta('organismoId');
  @override
  late final GeneratedColumn<int> organismoId = GeneratedColumn<int>(
      'organismo_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organismos (id)'));
  static const VerificationMeta _severidadeMediaMeta =
      const VerificationMeta('severidadeMedia');
  @override
  late final GeneratedColumn<double> severidadeMedia = GeneratedColumn<double>(
      'severidade_media', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _observacoesEspecificasMeta =
      const VerificationMeta('observacoesEspecificas');
  @override
  late final GeneratedColumn<String> observacoesEspecificas =
      GeneratedColumn<String>('observacoes_especificas', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, culturaId, organismoId, severidadeMedia, observacoesEspecificas];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cultura_organismo';
  @override
  VerificationContext validateIntegrity(
      Insertable<CulturaOrganismoData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cultura_id')) {
      context.handle(_culturaIdMeta,
          culturaId.isAcceptableOrUnknown(data['cultura_id']!, _culturaIdMeta));
    } else if (isInserting) {
      context.missing(_culturaIdMeta);
    }
    if (data.containsKey('organismo_id')) {
      context.handle(
          _organismoIdMeta,
          organismoId.isAcceptableOrUnknown(
              data['organismo_id']!, _organismoIdMeta));
    } else if (isInserting) {
      context.missing(_organismoIdMeta);
    }
    if (data.containsKey('severidade_media')) {
      context.handle(
          _severidadeMediaMeta,
          severidadeMedia.isAcceptableOrUnknown(
              data['severidade_media']!, _severidadeMediaMeta));
    }
    if (data.containsKey('observacoes_especificas')) {
      context.handle(
          _observacoesEspecificasMeta,
          observacoesEspecificas.isAcceptableOrUnknown(
              data['observacoes_especificas']!, _observacoesEspecificasMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CulturaOrganismoData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CulturaOrganismoData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      culturaId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}cultura_id'])!,
      organismoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organismo_id'])!,
      severidadeMedia: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}severidade_media']),
      observacoesEspecificas: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}observacoes_especificas']),
    );
  }

  @override
  $CulturaOrganismoTable createAlias(String alias) {
    return $CulturaOrganismoTable(attachedDatabase, alias);
  }
}

class CulturaOrganismoData extends DataClass
    implements Insertable<CulturaOrganismoData> {
  final int id;
  final int culturaId;
  final int organismoId;
  final double? severidadeMedia;
  final String? observacoesEspecificas;
  const CulturaOrganismoData(
      {required this.id,
      required this.culturaId,
      required this.organismoId,
      this.severidadeMedia,
      this.observacoesEspecificas});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cultura_id'] = Variable<int>(culturaId);
    map['organismo_id'] = Variable<int>(organismoId);
    if (!nullToAbsent || severidadeMedia != null) {
      map['severidade_media'] = Variable<double>(severidadeMedia);
    }
    if (!nullToAbsent || observacoesEspecificas != null) {
      map['observacoes_especificas'] = Variable<String>(observacoesEspecificas);
    }
    return map;
  }

  CulturaOrganismoCompanion toCompanion(bool nullToAbsent) {
    return CulturaOrganismoCompanion(
      id: Value(id),
      culturaId: Value(culturaId),
      organismoId: Value(organismoId),
      severidadeMedia: severidadeMedia == null && nullToAbsent
          ? const Value.absent()
          : Value(severidadeMedia),
      observacoesEspecificas: observacoesEspecificas == null && nullToAbsent
          ? const Value.absent()
          : Value(observacoesEspecificas),
    );
  }

  factory CulturaOrganismoData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CulturaOrganismoData(
      id: serializer.fromJson<int>(json['id']),
      culturaId: serializer.fromJson<int>(json['culturaId']),
      organismoId: serializer.fromJson<int>(json['organismoId']),
      severidadeMedia: serializer.fromJson<double?>(json['severidadeMedia']),
      observacoesEspecificas:
          serializer.fromJson<String?>(json['observacoesEspecificas']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'culturaId': serializer.toJson<int>(culturaId),
      'organismoId': serializer.toJson<int>(organismoId),
      'severidadeMedia': serializer.toJson<double?>(severidadeMedia),
      'observacoesEspecificas':
          serializer.toJson<String?>(observacoesEspecificas),
    };
  }

  CulturaOrganismoData copyWith(
          {int? id,
          int? culturaId,
          int? organismoId,
          Value<double?> severidadeMedia = const Value.absent(),
          Value<String?> observacoesEspecificas = const Value.absent()}) =>
      CulturaOrganismoData(
        id: id ?? this.id,
        culturaId: culturaId ?? this.culturaId,
        organismoId: organismoId ?? this.organismoId,
        severidadeMedia: severidadeMedia.present
            ? severidadeMedia.value
            : this.severidadeMedia,
        observacoesEspecificas: observacoesEspecificas.present
            ? observacoesEspecificas.value
            : this.observacoesEspecificas,
      );
  CulturaOrganismoData copyWithCompanion(CulturaOrganismoCompanion data) {
    return CulturaOrganismoData(
      id: data.id.present ? data.id.value : this.id,
      culturaId: data.culturaId.present ? data.culturaId.value : this.culturaId,
      organismoId:
          data.organismoId.present ? data.organismoId.value : this.organismoId,
      severidadeMedia: data.severidadeMedia.present
          ? data.severidadeMedia.value
          : this.severidadeMedia,
      observacoesEspecificas: data.observacoesEspecificas.present
          ? data.observacoesEspecificas.value
          : this.observacoesEspecificas,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CulturaOrganismoData(')
          ..write('id: $id, ')
          ..write('culturaId: $culturaId, ')
          ..write('organismoId: $organismoId, ')
          ..write('severidadeMedia: $severidadeMedia, ')
          ..write('observacoesEspecificas: $observacoesEspecificas')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, culturaId, organismoId, severidadeMedia, observacoesEspecificas);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CulturaOrganismoData &&
          other.id == this.id &&
          other.culturaId == this.culturaId &&
          other.organismoId == this.organismoId &&
          other.severidadeMedia == this.severidadeMedia &&
          other.observacoesEspecificas == this.observacoesEspecificas);
}

class CulturaOrganismoCompanion extends UpdateCompanion<CulturaOrganismoData> {
  final Value<int> id;
  final Value<int> culturaId;
  final Value<int> organismoId;
  final Value<double?> severidadeMedia;
  final Value<String?> observacoesEspecificas;
  const CulturaOrganismoCompanion({
    this.id = const Value.absent(),
    this.culturaId = const Value.absent(),
    this.organismoId = const Value.absent(),
    this.severidadeMedia = const Value.absent(),
    this.observacoesEspecificas = const Value.absent(),
  });
  CulturaOrganismoCompanion.insert({
    this.id = const Value.absent(),
    required int culturaId,
    required int organismoId,
    this.severidadeMedia = const Value.absent(),
    this.observacoesEspecificas = const Value.absent(),
  })  : culturaId = Value(culturaId),
        organismoId = Value(organismoId);
  static Insertable<CulturaOrganismoData> custom({
    Expression<int>? id,
    Expression<int>? culturaId,
    Expression<int>? organismoId,
    Expression<double>? severidadeMedia,
    Expression<String>? observacoesEspecificas,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (culturaId != null) 'cultura_id': culturaId,
      if (organismoId != null) 'organismo_id': organismoId,
      if (severidadeMedia != null) 'severidade_media': severidadeMedia,
      if (observacoesEspecificas != null)
        'observacoes_especificas': observacoesEspecificas,
    });
  }

  CulturaOrganismoCompanion copyWith(
      {Value<int>? id,
      Value<int>? culturaId,
      Value<int>? organismoId,
      Value<double?>? severidadeMedia,
      Value<String?>? observacoesEspecificas}) {
    return CulturaOrganismoCompanion(
      id: id ?? this.id,
      culturaId: culturaId ?? this.culturaId,
      organismoId: organismoId ?? this.organismoId,
      severidadeMedia: severidadeMedia ?? this.severidadeMedia,
      observacoesEspecificas:
          observacoesEspecificas ?? this.observacoesEspecificas,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (culturaId.present) {
      map['cultura_id'] = Variable<int>(culturaId.value);
    }
    if (organismoId.present) {
      map['organismo_id'] = Variable<int>(organismoId.value);
    }
    if (severidadeMedia.present) {
      map['severidade_media'] = Variable<double>(severidadeMedia.value);
    }
    if (observacoesEspecificas.present) {
      map['observacoes_especificas'] =
          Variable<String>(observacoesEspecificas.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CulturaOrganismoCompanion(')
          ..write('id: $id, ')
          ..write('culturaId: $culturaId, ')
          ..write('organismoId: $organismoId, ')
          ..write('severidadeMedia: $severidadeMedia, ')
          ..write('observacoesEspecificas: $observacoesEspecificas')
          ..write(')'))
        .toString();
  }
}

class $FotosTable extends Fotos with TableInfo<$FotosTable, Foto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FotosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _organismoIdMeta =
      const VerificationMeta('organismoId');
  @override
  late final GeneratedColumn<int> organismoId = GeneratedColumn<int>(
      'organismo_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES organismos (id)'));
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
      'path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isIconMeta = const VerificationMeta('isIcon');
  @override
  late final GeneratedColumn<bool> isIcon = GeneratedColumn<bool>(
      'is_icon', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_icon" IN (0, 1))'),
      defaultValue: Constant(false));
  @override
  List<GeneratedColumn> get $columns => [id, organismoId, path, isIcon];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fotos';
  @override
  VerificationContext validateIntegrity(Insertable<Foto> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('organismo_id')) {
      context.handle(
          _organismoIdMeta,
          organismoId.isAcceptableOrUnknown(
              data['organismo_id']!, _organismoIdMeta));
    } else if (isInserting) {
      context.missing(_organismoIdMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
          _pathMeta, path.isAcceptableOrUnknown(data['path']!, _pathMeta));
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('is_icon')) {
      context.handle(_isIconMeta,
          isIcon.isAcceptableOrUnknown(data['is_icon']!, _isIconMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Foto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Foto(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      organismoId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organismo_id'])!,
      path: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}path'])!,
      isIcon: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_icon'])!,
    );
  }

  @override
  $FotosTable createAlias(String alias) {
    return $FotosTable(attachedDatabase, alias);
  }
}

class Foto extends DataClass implements Insertable<Foto> {
  final int id;
  final int organismoId;
  final String path;
  final bool isIcon;
  const Foto(
      {required this.id,
      required this.organismoId,
      required this.path,
      required this.isIcon});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['organismo_id'] = Variable<int>(organismoId);
    map['path'] = Variable<String>(path);
    map['is_icon'] = Variable<bool>(isIcon);
    return map;
  }

  FotosCompanion toCompanion(bool nullToAbsent) {
    return FotosCompanion(
      id: Value(id),
      organismoId: Value(organismoId),
      path: Value(path),
      isIcon: Value(isIcon),
    );
  }

  factory Foto.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Foto(
      id: serializer.fromJson<int>(json['id']),
      organismoId: serializer.fromJson<int>(json['organismoId']),
      path: serializer.fromJson<String>(json['path']),
      isIcon: serializer.fromJson<bool>(json['isIcon']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'organismoId': serializer.toJson<int>(organismoId),
      'path': serializer.toJson<String>(path),
      'isIcon': serializer.toJson<bool>(isIcon),
    };
  }

  Foto copyWith({int? id, int? organismoId, String? path, bool? isIcon}) =>
      Foto(
        id: id ?? this.id,
        organismoId: organismoId ?? this.organismoId,
        path: path ?? this.path,
        isIcon: isIcon ?? this.isIcon,
      );
  Foto copyWithCompanion(FotosCompanion data) {
    return Foto(
      id: data.id.present ? data.id.value : this.id,
      organismoId:
          data.organismoId.present ? data.organismoId.value : this.organismoId,
      path: data.path.present ? data.path.value : this.path,
      isIcon: data.isIcon.present ? data.isIcon.value : this.isIcon,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Foto(')
          ..write('id: $id, ')
          ..write('organismoId: $organismoId, ')
          ..write('path: $path, ')
          ..write('isIcon: $isIcon')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, organismoId, path, isIcon);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Foto &&
          other.id == this.id &&
          other.organismoId == this.organismoId &&
          other.path == this.path &&
          other.isIcon == this.isIcon);
}

class FotosCompanion extends UpdateCompanion<Foto> {
  final Value<int> id;
  final Value<int> organismoId;
  final Value<String> path;
  final Value<bool> isIcon;
  const FotosCompanion({
    this.id = const Value.absent(),
    this.organismoId = const Value.absent(),
    this.path = const Value.absent(),
    this.isIcon = const Value.absent(),
  });
  FotosCompanion.insert({
    this.id = const Value.absent(),
    required int organismoId,
    required String path,
    this.isIcon = const Value.absent(),
  })  : organismoId = Value(organismoId),
        path = Value(path);
  static Insertable<Foto> custom({
    Expression<int>? id,
    Expression<int>? organismoId,
    Expression<String>? path,
    Expression<bool>? isIcon,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (organismoId != null) 'organismo_id': organismoId,
      if (path != null) 'path': path,
      if (isIcon != null) 'is_icon': isIcon,
    });
  }

  FotosCompanion copyWith(
      {Value<int>? id,
      Value<int>? organismoId,
      Value<String>? path,
      Value<bool>? isIcon}) {
    return FotosCompanion(
      id: id ?? this.id,
      organismoId: organismoId ?? this.organismoId,
      path: path ?? this.path,
      isIcon: isIcon ?? this.isIcon,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (organismoId.present) {
      map['organismo_id'] = Variable<int>(organismoId.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (isIcon.present) {
      map['is_icon'] = Variable<bool>(isIcon.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FotosCompanion(')
          ..write('id: $id, ')
          ..write('organismoId: $organismoId, ')
          ..write('path: $path, ')
          ..write('isIcon: $isIcon')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tableNameMeta =
      const VerificationMeta('tableName');
  @override
  late final GeneratedColumn<String> tableName = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
      'record_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _oldValuesMeta =
      const VerificationMeta('oldValues');
  @override
  late final GeneratedColumn<String> oldValues = GeneratedColumn<String>(
      'old_values', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _newValuesMeta =
      const VerificationMeta('newValues');
  @override
  late final GeneratedColumn<String> newValues = GeneratedColumn<String>(
      'new_values', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
      'level', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _timestampMeta =
      const VerificationMeta('timestamp');
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
      'timestamp', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _deviceInfoMeta =
      const VerificationMeta('deviceInfo');
  @override
  late final GeneratedColumn<String> deviceInfo = GeneratedColumn<String>(
      'device_info', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ipAddressMeta =
      const VerificationMeta('ipAddress');
  @override
  late final GeneratedColumn<String> ipAddress = GeneratedColumn<String>(
      'ip_address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _userAgentMeta =
      const VerificationMeta('userAgent');
  @override
  late final GeneratedColumn<String> userAgent = GeneratedColumn<String>(
      'user_agent', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tableName,
        recordId,
        action,
        oldValues,
        newValues,
        userId,
        notes,
        level,
        timestamp,
        deviceInfo,
        ipAddress,
        userAgent
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(Insertable<AuditLogData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(_tableNameMeta,
          tableName.isAcceptableOrUnknown(data['table_name']!, _tableNameMeta));
    } else if (isInserting) {
      context.missing(_tableNameMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('old_values')) {
      context.handle(_oldValuesMeta,
          oldValues.isAcceptableOrUnknown(data['old_values']!, _oldValuesMeta));
    }
    if (data.containsKey('new_values')) {
      context.handle(_newValuesMeta,
          newValues.isAcceptableOrUnknown(data['new_values']!, _newValuesMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('level')) {
      context.handle(
          _levelMeta, level.isAcceptableOrUnknown(data['level']!, _levelMeta));
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(_timestampMeta,
          timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta));
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('device_info')) {
      context.handle(
          _deviceInfoMeta,
          deviceInfo.isAcceptableOrUnknown(
              data['device_info']!, _deviceInfoMeta));
    }
    if (data.containsKey('ip_address')) {
      context.handle(_ipAddressMeta,
          ipAddress.isAcceptableOrUnknown(data['ip_address']!, _ipAddressMeta));
    }
    if (data.containsKey('user_agent')) {
      context.handle(_userAgentMeta,
          userAgent.isAcceptableOrUnknown(data['user_agent']!, _userAgentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}record_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      oldValues: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}old_values']),
      newValues: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}new_values']),
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      level: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}level'])!,
      timestamp: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}timestamp'])!,
      deviceInfo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}device_info']),
      ipAddress: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ip_address']),
      userAgent: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_agent']),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogData extends DataClass implements Insertable<AuditLogData> {
  final int id;
  final String tableName;
  final int recordId;
  final String action;
  final String? oldValues;
  final String? newValues;
  final String? userId;
  final String? notes;
  final String level;
  final DateTime timestamp;
  final String? deviceInfo;
  final String? ipAddress;
  final String? userAgent;
  const AuditLogData(
      {required this.id,
      required this.tableName,
      required this.recordId,
      required this.action,
      this.oldValues,
      this.newValues,
      this.userId,
      this.notes,
      required this.level,
      required this.timestamp,
      this.deviceInfo,
      this.ipAddress,
      this.userAgent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(tableName);
    map['record_id'] = Variable<int>(recordId);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || oldValues != null) {
      map['old_values'] = Variable<String>(oldValues);
    }
    if (!nullToAbsent || newValues != null) {
      map['new_values'] = Variable<String>(newValues);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['level'] = Variable<String>(level);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || deviceInfo != null) {
      map['device_info'] = Variable<String>(deviceInfo);
    }
    if (!nullToAbsent || ipAddress != null) {
      map['ip_address'] = Variable<String>(ipAddress);
    }
    if (!nullToAbsent || userAgent != null) {
      map['user_agent'] = Variable<String>(userAgent);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      tableName: Value(tableName),
      recordId: Value(recordId),
      action: Value(action),
      oldValues: oldValues == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValues),
      newValues: newValues == null && nullToAbsent
          ? const Value.absent()
          : Value(newValues),
      userId:
          userId == null && nullToAbsent ? const Value.absent() : Value(userId),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      level: Value(level),
      timestamp: Value(timestamp),
      deviceInfo: deviceInfo == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceInfo),
      ipAddress: ipAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(ipAddress),
      userAgent: userAgent == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgent),
    );
  }

  factory AuditLogData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogData(
      id: serializer.fromJson<int>(json['id']),
      tableName: serializer.fromJson<String>(json['tableName']),
      recordId: serializer.fromJson<int>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      oldValues: serializer.fromJson<String?>(json['oldValues']),
      newValues: serializer.fromJson<String?>(json['newValues']),
      userId: serializer.fromJson<String?>(json['userId']),
      notes: serializer.fromJson<String?>(json['notes']),
      level: serializer.fromJson<String>(json['level']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      deviceInfo: serializer.fromJson<String?>(json['deviceInfo']),
      ipAddress: serializer.fromJson<String?>(json['ipAddress']),
      userAgent: serializer.fromJson<String?>(json['userAgent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tableName': serializer.toJson<String>(tableName),
      'recordId': serializer.toJson<int>(recordId),
      'action': serializer.toJson<String>(action),
      'oldValues': serializer.toJson<String?>(oldValues),
      'newValues': serializer.toJson<String?>(newValues),
      'userId': serializer.toJson<String?>(userId),
      'notes': serializer.toJson<String?>(notes),
      'level': serializer.toJson<String>(level),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'deviceInfo': serializer.toJson<String?>(deviceInfo),
      'ipAddress': serializer.toJson<String?>(ipAddress),
      'userAgent': serializer.toJson<String?>(userAgent),
    };
  }

  AuditLogData copyWith(
          {int? id,
          String? tableName,
          int? recordId,
          String? action,
          Value<String?> oldValues = const Value.absent(),
          Value<String?> newValues = const Value.absent(),
          Value<String?> userId = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          String? level,
          DateTime? timestamp,
          Value<String?> deviceInfo = const Value.absent(),
          Value<String?> ipAddress = const Value.absent(),
          Value<String?> userAgent = const Value.absent()}) =>
      AuditLogData(
        id: id ?? this.id,
        tableName: tableName ?? this.tableName,
        recordId: recordId ?? this.recordId,
        action: action ?? this.action,
        oldValues: oldValues.present ? oldValues.value : this.oldValues,
        newValues: newValues.present ? newValues.value : this.newValues,
        userId: userId.present ? userId.value : this.userId,
        notes: notes.present ? notes.value : this.notes,
        level: level ?? this.level,
        timestamp: timestamp ?? this.timestamp,
        deviceInfo: deviceInfo.present ? deviceInfo.value : this.deviceInfo,
        ipAddress: ipAddress.present ? ipAddress.value : this.ipAddress,
        userAgent: userAgent.present ? userAgent.value : this.userAgent,
      );
  AuditLogData copyWithCompanion(AuditLogCompanion data) {
    return AuditLogData(
      id: data.id.present ? data.id.value : this.id,
      tableName: data.tableName.present ? data.tableName.value : this.tableName,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      oldValues: data.oldValues.present ? data.oldValues.value : this.oldValues,
      newValues: data.newValues.present ? data.newValues.value : this.newValues,
      userId: data.userId.present ? data.userId.value : this.userId,
      notes: data.notes.present ? data.notes.value : this.notes,
      level: data.level.present ? data.level.value : this.level,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      deviceInfo:
          data.deviceInfo.present ? data.deviceInfo.value : this.deviceInfo,
      ipAddress: data.ipAddress.present ? data.ipAddress.value : this.ipAddress,
      userAgent: data.userAgent.present ? data.userAgent.value : this.userAgent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogData(')
          ..write('id: $id, ')
          ..write('tableName: $tableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('oldValues: $oldValues, ')
          ..write('newValues: $newValues, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('level: $level, ')
          ..write('timestamp: $timestamp, ')
          ..write('deviceInfo: $deviceInfo, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('userAgent: $userAgent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tableName,
      recordId,
      action,
      oldValues,
      newValues,
      userId,
      notes,
      level,
      timestamp,
      deviceInfo,
      ipAddress,
      userAgent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogData &&
          other.id == this.id &&
          other.tableName == this.tableName &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          other.oldValues == this.oldValues &&
          other.newValues == this.newValues &&
          other.userId == this.userId &&
          other.notes == this.notes &&
          other.level == this.level &&
          other.timestamp == this.timestamp &&
          other.deviceInfo == this.deviceInfo &&
          other.ipAddress == this.ipAddress &&
          other.userAgent == this.userAgent);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogData> {
  final Value<int> id;
  final Value<String> tableName;
  final Value<int> recordId;
  final Value<String> action;
  final Value<String?> oldValues;
  final Value<String?> newValues;
  final Value<String?> userId;
  final Value<String?> notes;
  final Value<String> level;
  final Value<DateTime> timestamp;
  final Value<String?> deviceInfo;
  final Value<String?> ipAddress;
  final Value<String?> userAgent;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.tableName = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.oldValues = const Value.absent(),
    this.newValues = const Value.absent(),
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    this.level = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.deviceInfo = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.userAgent = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required String tableName,
    required int recordId,
    required String action,
    this.oldValues = const Value.absent(),
    this.newValues = const Value.absent(),
    this.userId = const Value.absent(),
    this.notes = const Value.absent(),
    required String level,
    required DateTime timestamp,
    this.deviceInfo = const Value.absent(),
    this.ipAddress = const Value.absent(),
    this.userAgent = const Value.absent(),
  })  : tableName = Value(tableName),
        recordId = Value(recordId),
        action = Value(action),
        level = Value(level),
        timestamp = Value(timestamp);
  static Insertable<AuditLogData> custom({
    Expression<int>? id,
    Expression<String>? tableName,
    Expression<int>? recordId,
    Expression<String>? action,
    Expression<String>? oldValues,
    Expression<String>? newValues,
    Expression<String>? userId,
    Expression<String>? notes,
    Expression<String>? level,
    Expression<DateTime>? timestamp,
    Expression<String>? deviceInfo,
    Expression<String>? ipAddress,
    Expression<String>? userAgent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableName != null) 'table_name': tableName,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (oldValues != null) 'old_values': oldValues,
      if (newValues != null) 'new_values': newValues,
      if (userId != null) 'user_id': userId,
      if (notes != null) 'notes': notes,
      if (level != null) 'level': level,
      if (timestamp != null) 'timestamp': timestamp,
      if (deviceInfo != null) 'device_info': deviceInfo,
      if (ipAddress != null) 'ip_address': ipAddress,
      if (userAgent != null) 'user_agent': userAgent,
    });
  }

  AuditLogCompanion copyWith(
      {Value<int>? id,
      Value<String>? tableName,
      Value<int>? recordId,
      Value<String>? action,
      Value<String?>? oldValues,
      Value<String?>? newValues,
      Value<String?>? userId,
      Value<String?>? notes,
      Value<String>? level,
      Value<DateTime>? timestamp,
      Value<String?>? deviceInfo,
      Value<String?>? ipAddress,
      Value<String?>? userAgent}) {
    return AuditLogCompanion(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      userId: userId ?? this.userId,
      notes: notes ?? this.notes,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tableName.present) {
      map['table_name'] = Variable<String>(tableName.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (oldValues.present) {
      map['old_values'] = Variable<String>(oldValues.value);
    }
    if (newValues.present) {
      map['new_values'] = Variable<String>(newValues.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (deviceInfo.present) {
      map['device_info'] = Variable<String>(deviceInfo.value);
    }
    if (ipAddress.present) {
      map['ip_address'] = Variable<String>(ipAddress.value);
    }
    if (userAgent.present) {
      map['user_agent'] = Variable<String>(userAgent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('tableName: $tableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('oldValues: $oldValues, ')
          ..write('newValues: $newValues, ')
          ..write('userId: $userId, ')
          ..write('notes: $notes, ')
          ..write('level: $level, ')
          ..write('timestamp: $timestamp, ')
          ..write('deviceInfo: $deviceInfo, ')
          ..write('ipAddress: $ipAddress, ')
          ..write('userAgent: $userAgent')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tableNameMeta =
      const VerificationMeta('tableName');
  @override
  late final GeneratedColumn<String> tableName = GeneratedColumn<String>(
      'table_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordIdMeta =
      const VerificationMeta('recordId');
  @override
  late final GeneratedColumn<int> recordId = GeneratedColumn<int>(
      'record_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
      'data', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _maxRetriesMeta =
      const VerificationMeta('maxRetries');
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
      'max_retries', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(3));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: Constant('pending'));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tableName,
        recordId,
        action,
        data,
        priority,
        retryCount,
        maxRetries,
        createdAt,
        updatedAt,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('table_name')) {
      context.handle(_tableNameMeta,
          tableName.isAcceptableOrUnknown(data['table_name']!, _tableNameMeta));
    } else if (isInserting) {
      context.missing(_tableNameMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(_recordIdMeta,
          recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta));
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
          _dataMeta, this.data.isAcceptableOrUnknown(data['data']!, _dataMeta));
    } else if (isInserting) {
      context.missing(_dataMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('max_retries')) {
      context.handle(
          _maxRetriesMeta,
          maxRetries.isAcceptableOrUnknown(
              data['max_retries']!, _maxRetriesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tableName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}table_name'])!,
      recordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}record_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      data: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!,
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      maxRetries: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}max_retries'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  final int id;
  final String tableName;
  final int recordId;
  final String action;
  final String data;
  final int priority;
  final int retryCount;
  final int maxRetries;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  const SyncQueueData(
      {required this.id,
      required this.tableName,
      required this.recordId,
      required this.action,
      required this.data,
      required this.priority,
      required this.retryCount,
      required this.maxRetries,
      required this.createdAt,
      required this.updatedAt,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['table_name'] = Variable<String>(tableName);
    map['record_id'] = Variable<int>(recordId);
    map['action'] = Variable<String>(action);
    map['data'] = Variable<String>(data);
    map['priority'] = Variable<int>(priority);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['status'] = Variable<String>(status);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      tableName: Value(tableName),
      recordId: Value(recordId),
      action: Value(action),
      data: Value(data),
      priority: Value(priority),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      status: Value(status),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      tableName: serializer.fromJson<String>(json['tableName']),
      recordId: serializer.fromJson<int>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      data: serializer.fromJson<String>(json['data']),
      priority: serializer.fromJson<int>(json['priority']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tableName': serializer.toJson<String>(tableName),
      'recordId': serializer.toJson<int>(recordId),
      'action': serializer.toJson<String>(action),
      'data': serializer.toJson<String>(data),
      'priority': serializer.toJson<int>(priority),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'status': serializer.toJson<String>(status),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? tableName,
          int? recordId,
          String? action,
          String? data,
          int? priority,
          int? retryCount,
          int? maxRetries,
          DateTime? createdAt,
          DateTime? updatedAt,
          String? status}) =>
      SyncQueueData(
        id: id ?? this.id,
        tableName: tableName ?? this.tableName,
        recordId: recordId ?? this.recordId,
        action: action ?? this.action,
        data: data ?? this.data,
        priority: priority ?? this.priority,
        retryCount: retryCount ?? this.retryCount,
        maxRetries: maxRetries ?? this.maxRetries,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        status: status ?? this.status,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      tableName: data.tableName.present ? data.tableName.value : this.tableName,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      data: data.data.present ? data.data.value : this.data,
      priority: data.priority.present ? data.priority.value : this.priority,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      maxRetries:
          data.maxRetries.present ? data.maxRetries.value : this.maxRetries,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('tableName: $tableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('data: $data, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tableName, recordId, action, data,
      priority, retryCount, maxRetries, createdAt, updatedAt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.tableName == this.tableName &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          other.data == this.data &&
          other.priority == this.priority &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.status == this.status);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> tableName;
  final Value<int> recordId;
  final Value<String> action;
  final Value<String> data;
  final Value<int> priority;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> status;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.tableName = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.data = const Value.absent(),
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.status = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String tableName,
    required int recordId,
    required String action,
    required String data,
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.status = const Value.absent(),
  })  : tableName = Value(tableName),
        recordId = Value(recordId),
        action = Value(action),
        data = Value(data),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? tableName,
    Expression<int>? recordId,
    Expression<String>? action,
    Expression<String>? data,
    Expression<int>? priority,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? status,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableName != null) 'table_name': tableName,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (data != null) 'data': data,
      if (priority != null) 'priority': priority,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (status != null) 'status': status,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? tableName,
      Value<int>? recordId,
      Value<String>? action,
      Value<String>? data,
      Value<int>? priority,
      Value<int>? retryCount,
      Value<int>? maxRetries,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<String>? status}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      tableName: tableName ?? this.tableName,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      data: data ?? this.data,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tableName.present) {
      map['table_name'] = Variable<String>(tableName.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<int>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('tableName: $tableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('data: $data, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }
}

class $SyncHistoryTable extends SyncHistory
    with TableInfo<$SyncHistoryTable, SyncHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _syncTypeMeta =
      const VerificationMeta('syncType');
  @override
  late final GeneratedColumn<String> syncType = GeneratedColumn<String>(
      'sync_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _recordsProcessedMeta =
      const VerificationMeta('recordsProcessed');
  @override
  late final GeneratedColumn<int> recordsProcessed = GeneratedColumn<int>(
      'records_processed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _recordsSuccessMeta =
      const VerificationMeta('recordsSuccess');
  @override
  late final GeneratedColumn<int> recordsSuccess = GeneratedColumn<int>(
      'records_success', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _recordsFailedMeta =
      const VerificationMeta('recordsFailed');
  @override
  late final GeneratedColumn<int> recordsFailed = GeneratedColumn<int>(
      'records_failed', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: Constant(0));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
      'start_time', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endTimeMeta =
      const VerificationMeta('endTime');
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
      'end_time', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        syncType,
        status,
        recordsProcessed,
        recordsSuccess,
        recordsFailed,
        startTime,
        endTime,
        errorMessage,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_history';
  @override
  VerificationContext validateIntegrity(Insertable<SyncHistoryData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('sync_type')) {
      context.handle(_syncTypeMeta,
          syncType.isAcceptableOrUnknown(data['sync_type']!, _syncTypeMeta));
    } else if (isInserting) {
      context.missing(_syncTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('records_processed')) {
      context.handle(
          _recordsProcessedMeta,
          recordsProcessed.isAcceptableOrUnknown(
              data['records_processed']!, _recordsProcessedMeta));
    }
    if (data.containsKey('records_success')) {
      context.handle(
          _recordsSuccessMeta,
          recordsSuccess.isAcceptableOrUnknown(
              data['records_success']!, _recordsSuccessMeta));
    }
    if (data.containsKey('records_failed')) {
      context.handle(
          _recordsFailedMeta,
          recordsFailed.isAcceptableOrUnknown(
              data['records_failed']!, _recordsFailedMeta));
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(_endTimeMeta,
          endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncHistoryData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      syncType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sync_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      recordsProcessed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}records_processed'])!,
      recordsSuccess: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}records_success'])!,
      recordsFailed: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}records_failed'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}start_time'])!,
      endTime: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}end_time']),
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SyncHistoryTable createAlias(String alias) {
    return $SyncHistoryTable(attachedDatabase, alias);
  }
}

class SyncHistoryData extends DataClass implements Insertable<SyncHistoryData> {
  final int id;
  final String syncType;
  final String status;
  final int recordsProcessed;
  final int recordsSuccess;
  final int recordsFailed;
  final DateTime startTime;
  final DateTime? endTime;
  final String? errorMessage;
  final DateTime createdAt;
  const SyncHistoryData(
      {required this.id,
      required this.syncType,
      required this.status,
      required this.recordsProcessed,
      required this.recordsSuccess,
      required this.recordsFailed,
      required this.startTime,
      this.endTime,
      this.errorMessage,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['sync_type'] = Variable<String>(syncType);
    map['status'] = Variable<String>(status);
    map['records_processed'] = Variable<int>(recordsProcessed);
    map['records_success'] = Variable<int>(recordsSuccess);
    map['records_failed'] = Variable<int>(recordsFailed);
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncHistoryCompanion toCompanion(bool nullToAbsent) {
    return SyncHistoryCompanion(
      id: Value(id),
      syncType: Value(syncType),
      status: Value(status),
      recordsProcessed: Value(recordsProcessed),
      recordsSuccess: Value(recordsSuccess),
      recordsFailed: Value(recordsFailed),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
    );
  }

  factory SyncHistoryData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncHistoryData(
      id: serializer.fromJson<int>(json['id']),
      syncType: serializer.fromJson<String>(json['syncType']),
      status: serializer.fromJson<String>(json['status']),
      recordsProcessed: serializer.fromJson<int>(json['recordsProcessed']),
      recordsSuccess: serializer.fromJson<int>(json['recordsSuccess']),
      recordsFailed: serializer.fromJson<int>(json['recordsFailed']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'syncType': serializer.toJson<String>(syncType),
      'status': serializer.toJson<String>(status),
      'recordsProcessed': serializer.toJson<int>(recordsProcessed),
      'recordsSuccess': serializer.toJson<int>(recordsSuccess),
      'recordsFailed': serializer.toJson<int>(recordsFailed),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncHistoryData copyWith(
          {int? id,
          String? syncType,
          String? status,
          int? recordsProcessed,
          int? recordsSuccess,
          int? recordsFailed,
          DateTime? startTime,
          Value<DateTime?> endTime = const Value.absent(),
          Value<String?> errorMessage = const Value.absent(),
          DateTime? createdAt}) =>
      SyncHistoryData(
        id: id ?? this.id,
        syncType: syncType ?? this.syncType,
        status: status ?? this.status,
        recordsProcessed: recordsProcessed ?? this.recordsProcessed,
        recordsSuccess: recordsSuccess ?? this.recordsSuccess,
        recordsFailed: recordsFailed ?? this.recordsFailed,
        startTime: startTime ?? this.startTime,
        endTime: endTime.present ? endTime.value : this.endTime,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
      );
  SyncHistoryData copyWithCompanion(SyncHistoryCompanion data) {
    return SyncHistoryData(
      id: data.id.present ? data.id.value : this.id,
      syncType: data.syncType.present ? data.syncType.value : this.syncType,
      status: data.status.present ? data.status.value : this.status,
      recordsProcessed: data.recordsProcessed.present
          ? data.recordsProcessed.value
          : this.recordsProcessed,
      recordsSuccess: data.recordsSuccess.present
          ? data.recordsSuccess.value
          : this.recordsSuccess,
      recordsFailed: data.recordsFailed.present
          ? data.recordsFailed.value
          : this.recordsFailed,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryData(')
          ..write('id: $id, ')
          ..write('syncType: $syncType, ')
          ..write('status: $status, ')
          ..write('recordsProcessed: $recordsProcessed, ')
          ..write('recordsSuccess: $recordsSuccess, ')
          ..write('recordsFailed: $recordsFailed, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      syncType,
      status,
      recordsProcessed,
      recordsSuccess,
      recordsFailed,
      startTime,
      endTime,
      errorMessage,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncHistoryData &&
          other.id == this.id &&
          other.syncType == this.syncType &&
          other.status == this.status &&
          other.recordsProcessed == this.recordsProcessed &&
          other.recordsSuccess == this.recordsSuccess &&
          other.recordsFailed == this.recordsFailed &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt);
}

class SyncHistoryCompanion extends UpdateCompanion<SyncHistoryData> {
  final Value<int> id;
  final Value<String> syncType;
  final Value<String> status;
  final Value<int> recordsProcessed;
  final Value<int> recordsSuccess;
  final Value<int> recordsFailed;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  const SyncHistoryCompanion({
    this.id = const Value.absent(),
    this.syncType = const Value.absent(),
    this.status = const Value.absent(),
    this.recordsProcessed = const Value.absent(),
    this.recordsSuccess = const Value.absent(),
    this.recordsFailed = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String syncType,
    required String status,
    this.recordsProcessed = const Value.absent(),
    this.recordsSuccess = const Value.absent(),
    this.recordsFailed = const Value.absent(),
    required DateTime startTime,
    this.endTime = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
  })  : syncType = Value(syncType),
        status = Value(status),
        startTime = Value(startTime),
        createdAt = Value(createdAt);
  static Insertable<SyncHistoryData> custom({
    Expression<int>? id,
    Expression<String>? syncType,
    Expression<String>? status,
    Expression<int>? recordsProcessed,
    Expression<int>? recordsSuccess,
    Expression<int>? recordsFailed,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncType != null) 'sync_type': syncType,
      if (status != null) 'status': status,
      if (recordsProcessed != null) 'records_processed': recordsProcessed,
      if (recordsSuccess != null) 'records_success': recordsSuccess,
      if (recordsFailed != null) 'records_failed': recordsFailed,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncHistoryCompanion copyWith(
      {Value<int>? id,
      Value<String>? syncType,
      Value<String>? status,
      Value<int>? recordsProcessed,
      Value<int>? recordsSuccess,
      Value<int>? recordsFailed,
      Value<DateTime>? startTime,
      Value<DateTime?>? endTime,
      Value<String?>? errorMessage,
      Value<DateTime>? createdAt}) {
    return SyncHistoryCompanion(
      id: id ?? this.id,
      syncType: syncType ?? this.syncType,
      status: status ?? this.status,
      recordsProcessed: recordsProcessed ?? this.recordsProcessed,
      recordsSuccess: recordsSuccess ?? this.recordsSuccess,
      recordsFailed: recordsFailed ?? this.recordsFailed,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (syncType.present) {
      map['sync_type'] = Variable<String>(syncType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recordsProcessed.present) {
      map['records_processed'] = Variable<int>(recordsProcessed.value);
    }
    if (recordsSuccess.present) {
      map['records_success'] = Variable<int>(recordsSuccess.value);
    }
    if (recordsFailed.present) {
      map['records_failed'] = Variable<int>(recordsFailed.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryCompanion(')
          ..write('id: $id, ')
          ..write('syncType: $syncType, ')
          ..write('status: $status, ')
          ..write('recordsProcessed: $recordsProcessed, ')
          ..write('recordsSuccess: $recordsSuccess, ')
          ..write('recordsFailed: $recordsFailed, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MonitoringTable extends Monitoring
    with TableInfo<$MonitoringTable, MonitoringData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonitoringTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
      'date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _weatherConditionMeta =
      const VerificationMeta('weatherCondition');
  @override
  late final GeneratedColumn<String> weatherCondition = GeneratedColumn<String>(
      'weather_condition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _temperatureMeta =
      const VerificationMeta('temperature');
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
      'temperature', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _humidityMeta =
      const VerificationMeta('humidity');
  @override
  late final GeneratedColumn<double> humidity = GeneratedColumn<double>(
      'humidity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        date,
        weatherCondition,
        temperature,
        humidity,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monitoring';
  @override
  VerificationContext validateIntegrity(Insertable<MonitoringData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('weather_condition')) {
      context.handle(
          _weatherConditionMeta,
          weatherCondition.isAcceptableOrUnknown(
              data['weather_condition']!, _weatherConditionMeta));
    }
    if (data.containsKey('temperature')) {
      context.handle(
          _temperatureMeta,
          temperature.isAcceptableOrUnknown(
              data['temperature']!, _temperatureMeta));
    }
    if (data.containsKey('humidity')) {
      context.handle(_humidityMeta,
          humidity.isAcceptableOrUnknown(data['humidity']!, _humidityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonitoringData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonitoringData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id']),
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}date'])!,
      weatherCondition: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}weather_condition']),
      temperature: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}temperature']),
      humidity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}humidity']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $MonitoringTable createAlias(String alias) {
    return $MonitoringTable(attachedDatabase, alias);
  }
}

class MonitoringData extends DataClass implements Insertable<MonitoringData> {
  final int id;
  final int? plotId;
  final String date;
  final String? weatherCondition;
  final double? temperature;
  final double? humidity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const MonitoringData(
      {required this.id,
      this.plotId,
      required this.date,
      this.weatherCondition,
      this.temperature,
      this.humidity,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || plotId != null) {
      map['plot_id'] = Variable<int>(plotId);
    }
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || weatherCondition != null) {
      map['weather_condition'] = Variable<String>(weatherCondition);
    }
    if (!nullToAbsent || temperature != null) {
      map['temperature'] = Variable<double>(temperature);
    }
    if (!nullToAbsent || humidity != null) {
      map['humidity'] = Variable<double>(humidity);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  MonitoringCompanion toCompanion(bool nullToAbsent) {
    return MonitoringCompanion(
      id: Value(id),
      plotId:
          plotId == null && nullToAbsent ? const Value.absent() : Value(plotId),
      date: Value(date),
      weatherCondition: weatherCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherCondition),
      temperature: temperature == null && nullToAbsent
          ? const Value.absent()
          : Value(temperature),
      humidity: humidity == null && nullToAbsent
          ? const Value.absent()
          : Value(humidity),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory MonitoringData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonitoringData(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int?>(json['plotId']),
      date: serializer.fromJson<String>(json['date']),
      weatherCondition: serializer.fromJson<String?>(json['weatherCondition']),
      temperature: serializer.fromJson<double?>(json['temperature']),
      humidity: serializer.fromJson<double?>(json['humidity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int?>(plotId),
      'date': serializer.toJson<String>(date),
      'weatherCondition': serializer.toJson<String?>(weatherCondition),
      'temperature': serializer.toJson<double?>(temperature),
      'humidity': serializer.toJson<double?>(humidity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  MonitoringData copyWith(
          {int? id,
          Value<int?> plotId = const Value.absent(),
          String? date,
          Value<String?> weatherCondition = const Value.absent(),
          Value<double?> temperature = const Value.absent(),
          Value<double?> humidity = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      MonitoringData(
        id: id ?? this.id,
        plotId: plotId.present ? plotId.value : this.plotId,
        date: date ?? this.date,
        weatherCondition: weatherCondition.present
            ? weatherCondition.value
            : this.weatherCondition,
        temperature: temperature.present ? temperature.value : this.temperature,
        humidity: humidity.present ? humidity.value : this.humidity,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  MonitoringData copyWithCompanion(MonitoringCompanion data) {
    return MonitoringData(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      date: data.date.present ? data.date.value : this.date,
      weatherCondition: data.weatherCondition.present
          ? data.weatherCondition.value
          : this.weatherCondition,
      temperature:
          data.temperature.present ? data.temperature.value : this.temperature,
      humidity: data.humidity.present ? data.humidity.value : this.humidity,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonitoringData(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('date: $date, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plotId, date, weatherCondition,
      temperature, humidity, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonitoringData &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.date == this.date &&
          other.weatherCondition == this.weatherCondition &&
          other.temperature == this.temperature &&
          other.humidity == this.humidity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MonitoringCompanion extends UpdateCompanion<MonitoringData> {
  final Value<int> id;
  final Value<int?> plotId;
  final Value<String> date;
  final Value<String?> weatherCondition;
  final Value<double?> temperature;
  final Value<double?> humidity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const MonitoringCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.date = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.temperature = const Value.absent(),
    this.humidity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  MonitoringCompanion.insert({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    required String date,
    this.weatherCondition = const Value.absent(),
    this.temperature = const Value.absent(),
    this.humidity = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<MonitoringData> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? date,
    Expression<String>? weatherCondition,
    Expression<double>? temperature,
    Expression<double>? humidity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (date != null) 'date': date,
      if (weatherCondition != null) 'weather_condition': weatherCondition,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  MonitoringCompanion copyWith(
      {Value<int>? id,
      Value<int?>? plotId,
      Value<String>? date,
      Value<String?>? weatherCondition,
      Value<double?>? temperature,
      Value<double?>? humidity,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return MonitoringCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      date: date ?? this.date,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (weatherCondition.present) {
      map['weather_condition'] = Variable<String>(weatherCondition.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (humidity.present) {
      map['humidity'] = Variable<double>(humidity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonitoringCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('date: $date, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('temperature: $temperature, ')
          ..write('humidity: $humidity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $MonitoringPointsTable extends MonitoringPoints
    with TableInfo<$MonitoringPointsTable, MonitoringPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonitoringPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monitoringIdMeta =
      const VerificationMeta('monitoringId');
  @override
  late final GeneratedColumn<int> monitoringId = GeneratedColumn<int>(
      'monitoring_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _organismIdMeta =
      const VerificationMeta('organismId');
  @override
  late final GeneratedColumn<int> organismId = GeneratedColumn<int>(
      'organism_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _severityLevelMeta =
      const VerificationMeta('severityLevel');
  @override
  late final GeneratedColumn<int> severityLevel = GeneratedColumn<int>(
      'severity_level', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        monitoringId,
        latitude,
        longitude,
        organismId,
        severityLevel,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monitoring_points';
  @override
  VerificationContext validateIntegrity(Insertable<MonitoringPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monitoring_id')) {
      context.handle(
          _monitoringIdMeta,
          monitoringId.isAcceptableOrUnknown(
              data['monitoring_id']!, _monitoringIdMeta));
    } else if (isInserting) {
      context.missing(_monitoringIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('organism_id')) {
      context.handle(
          _organismIdMeta,
          organismId.isAcceptableOrUnknown(
              data['organism_id']!, _organismIdMeta));
    }
    if (data.containsKey('severity_level')) {
      context.handle(
          _severityLevelMeta,
          severityLevel.isAcceptableOrUnknown(
              data['severity_level']!, _severityLevelMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonitoringPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonitoringPoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      monitoringId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}monitoring_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      organismId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organism_id']),
      severityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severity_level']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $MonitoringPointsTable createAlias(String alias) {
    return $MonitoringPointsTable(attachedDatabase, alias);
  }
}

class MonitoringPoint extends DataClass implements Insertable<MonitoringPoint> {
  final int id;
  final int monitoringId;
  final double latitude;
  final double longitude;
  final int? organismId;
  final int? severityLevel;
  final String? notes;
  final DateTime createdAt;
  const MonitoringPoint(
      {required this.id,
      required this.monitoringId,
      required this.latitude,
      required this.longitude,
      this.organismId,
      this.severityLevel,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monitoring_id'] = Variable<int>(monitoringId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || organismId != null) {
      map['organism_id'] = Variable<int>(organismId);
    }
    if (!nullToAbsent || severityLevel != null) {
      map['severity_level'] = Variable<int>(severityLevel);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MonitoringPointsCompanion toCompanion(bool nullToAbsent) {
    return MonitoringPointsCompanion(
      id: Value(id),
      monitoringId: Value(monitoringId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      organismId: organismId == null && nullToAbsent
          ? const Value.absent()
          : Value(organismId),
      severityLevel: severityLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(severityLevel),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory MonitoringPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonitoringPoint(
      id: serializer.fromJson<int>(json['id']),
      monitoringId: serializer.fromJson<int>(json['monitoringId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      organismId: serializer.fromJson<int?>(json['organismId']),
      severityLevel: serializer.fromJson<int?>(json['severityLevel']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monitoringId': serializer.toJson<int>(monitoringId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'organismId': serializer.toJson<int?>(organismId),
      'severityLevel': serializer.toJson<int?>(severityLevel),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MonitoringPoint copyWith(
          {int? id,
          int? monitoringId,
          double? latitude,
          double? longitude,
          Value<int?> organismId = const Value.absent(),
          Value<int?> severityLevel = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      MonitoringPoint(
        id: id ?? this.id,
        monitoringId: monitoringId ?? this.monitoringId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        organismId: organismId.present ? organismId.value : this.organismId,
        severityLevel:
            severityLevel.present ? severityLevel.value : this.severityLevel,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  MonitoringPoint copyWithCompanion(MonitoringPointsCompanion data) {
    return MonitoringPoint(
      id: data.id.present ? data.id.value : this.id,
      monitoringId: data.monitoringId.present
          ? data.monitoringId.value
          : this.monitoringId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      organismId:
          data.organismId.present ? data.organismId.value : this.organismId,
      severityLevel: data.severityLevel.present
          ? data.severityLevel.value
          : this.severityLevel,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonitoringPoint(')
          ..write('id: $id, ')
          ..write('monitoringId: $monitoringId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('organismId: $organismId, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monitoringId, latitude, longitude,
      organismId, severityLevel, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonitoringPoint &&
          other.id == this.id &&
          other.monitoringId == this.monitoringId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.organismId == this.organismId &&
          other.severityLevel == this.severityLevel &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class MonitoringPointsCompanion extends UpdateCompanion<MonitoringPoint> {
  final Value<int> id;
  final Value<int> monitoringId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int?> organismId;
  final Value<int?> severityLevel;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const MonitoringPointsCompanion({
    this.id = const Value.absent(),
    this.monitoringId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.organismId = const Value.absent(),
    this.severityLevel = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  MonitoringPointsCompanion.insert({
    this.id = const Value.absent(),
    required int monitoringId,
    required double latitude,
    required double longitude,
    this.organismId = const Value.absent(),
    this.severityLevel = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : monitoringId = Value(monitoringId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        createdAt = Value(createdAt);
  static Insertable<MonitoringPoint> custom({
    Expression<int>? id,
    Expression<int>? monitoringId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? organismId,
    Expression<int>? severityLevel,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monitoringId != null) 'monitoring_id': monitoringId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (organismId != null) 'organism_id': organismId,
      if (severityLevel != null) 'severity_level': severityLevel,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  MonitoringPointsCompanion copyWith(
      {Value<int>? id,
      Value<int>? monitoringId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<int?>? organismId,
      Value<int?>? severityLevel,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return MonitoringPointsCompanion(
      id: id ?? this.id,
      monitoringId: monitoringId ?? this.monitoringId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      organismId: organismId ?? this.organismId,
      severityLevel: severityLevel ?? this.severityLevel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monitoringId.present) {
      map['monitoring_id'] = Variable<int>(monitoringId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (organismId.present) {
      map['organism_id'] = Variable<int>(organismId.value);
    }
    if (severityLevel.present) {
      map['severity_level'] = Variable<int>(severityLevel.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonitoringPointsCompanion(')
          ..write('id: $id, ')
          ..write('monitoringId: $monitoringId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('organismId: $organismId, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InfestacoesTable extends Infestacoes
    with TableInfo<$InfestacoesTable, Infestacoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InfestacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _monitoringPointIdMeta =
      const VerificationMeta('monitoringPointId');
  @override
  late final GeneratedColumn<int> monitoringPointId = GeneratedColumn<int>(
      'monitoring_point_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _organismIdMeta =
      const VerificationMeta('organismId');
  @override
  late final GeneratedColumn<int> organismId = GeneratedColumn<int>(
      'organism_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _severityLevelMeta =
      const VerificationMeta('severityLevel');
  @override
  late final GeneratedColumn<int> severityLevel = GeneratedColumn<int>(
      'severity_level', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _affectedAreaMeta =
      const VerificationMeta('affectedArea');
  @override
  late final GeneratedColumn<double> affectedArea = GeneratedColumn<double>(
      'affected_area', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _treatmentAppliedMeta =
      const VerificationMeta('treatmentApplied');
  @override
  late final GeneratedColumn<String> treatmentApplied = GeneratedColumn<String>(
      'treatment_applied', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        monitoringPointId,
        organismId,
        severityLevel,
        affectedArea,
        treatmentApplied,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'infestacoes';
  @override
  VerificationContext validateIntegrity(Insertable<Infestacoe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('monitoring_point_id')) {
      context.handle(
          _monitoringPointIdMeta,
          monitoringPointId.isAcceptableOrUnknown(
              data['monitoring_point_id']!, _monitoringPointIdMeta));
    } else if (isInserting) {
      context.missing(_monitoringPointIdMeta);
    }
    if (data.containsKey('organism_id')) {
      context.handle(
          _organismIdMeta,
          organismId.isAcceptableOrUnknown(
              data['organism_id']!, _organismIdMeta));
    } else if (isInserting) {
      context.missing(_organismIdMeta);
    }
    if (data.containsKey('severity_level')) {
      context.handle(
          _severityLevelMeta,
          severityLevel.isAcceptableOrUnknown(
              data['severity_level']!, _severityLevelMeta));
    } else if (isInserting) {
      context.missing(_severityLevelMeta);
    }
    if (data.containsKey('affected_area')) {
      context.handle(
          _affectedAreaMeta,
          affectedArea.isAcceptableOrUnknown(
              data['affected_area']!, _affectedAreaMeta));
    }
    if (data.containsKey('treatment_applied')) {
      context.handle(
          _treatmentAppliedMeta,
          treatmentApplied.isAcceptableOrUnknown(
              data['treatment_applied']!, _treatmentAppliedMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Infestacoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Infestacoe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      monitoringPointId: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}monitoring_point_id'])!,
      organismId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}organism_id'])!,
      severityLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}severity_level'])!,
      affectedArea: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}affected_area']),
      treatmentApplied: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}treatment_applied']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InfestacoesTable createAlias(String alias) {
    return $InfestacoesTable(attachedDatabase, alias);
  }
}

class Infestacoe extends DataClass implements Insertable<Infestacoe> {
  final int id;
  final int monitoringPointId;
  final int organismId;
  final int severityLevel;
  final double? affectedArea;
  final String? treatmentApplied;
  final String? notes;
  final DateTime createdAt;
  const Infestacoe(
      {required this.id,
      required this.monitoringPointId,
      required this.organismId,
      required this.severityLevel,
      this.affectedArea,
      this.treatmentApplied,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['monitoring_point_id'] = Variable<int>(monitoringPointId);
    map['organism_id'] = Variable<int>(organismId);
    map['severity_level'] = Variable<int>(severityLevel);
    if (!nullToAbsent || affectedArea != null) {
      map['affected_area'] = Variable<double>(affectedArea);
    }
    if (!nullToAbsent || treatmentApplied != null) {
      map['treatment_applied'] = Variable<String>(treatmentApplied);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InfestacoesCompanion toCompanion(bool nullToAbsent) {
    return InfestacoesCompanion(
      id: Value(id),
      monitoringPointId: Value(monitoringPointId),
      organismId: Value(organismId),
      severityLevel: Value(severityLevel),
      affectedArea: affectedArea == null && nullToAbsent
          ? const Value.absent()
          : Value(affectedArea),
      treatmentApplied: treatmentApplied == null && nullToAbsent
          ? const Value.absent()
          : Value(treatmentApplied),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory Infestacoe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Infestacoe(
      id: serializer.fromJson<int>(json['id']),
      monitoringPointId: serializer.fromJson<int>(json['monitoringPointId']),
      organismId: serializer.fromJson<int>(json['organismId']),
      severityLevel: serializer.fromJson<int>(json['severityLevel']),
      affectedArea: serializer.fromJson<double?>(json['affectedArea']),
      treatmentApplied: serializer.fromJson<String?>(json['treatmentApplied']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monitoringPointId': serializer.toJson<int>(monitoringPointId),
      'organismId': serializer.toJson<int>(organismId),
      'severityLevel': serializer.toJson<int>(severityLevel),
      'affectedArea': serializer.toJson<double?>(affectedArea),
      'treatmentApplied': serializer.toJson<String?>(treatmentApplied),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Infestacoe copyWith(
          {int? id,
          int? monitoringPointId,
          int? organismId,
          int? severityLevel,
          Value<double?> affectedArea = const Value.absent(),
          Value<String?> treatmentApplied = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      Infestacoe(
        id: id ?? this.id,
        monitoringPointId: monitoringPointId ?? this.monitoringPointId,
        organismId: organismId ?? this.organismId,
        severityLevel: severityLevel ?? this.severityLevel,
        affectedArea:
            affectedArea.present ? affectedArea.value : this.affectedArea,
        treatmentApplied: treatmentApplied.present
            ? treatmentApplied.value
            : this.treatmentApplied,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  Infestacoe copyWithCompanion(InfestacoesCompanion data) {
    return Infestacoe(
      id: data.id.present ? data.id.value : this.id,
      monitoringPointId: data.monitoringPointId.present
          ? data.monitoringPointId.value
          : this.monitoringPointId,
      organismId:
          data.organismId.present ? data.organismId.value : this.organismId,
      severityLevel: data.severityLevel.present
          ? data.severityLevel.value
          : this.severityLevel,
      affectedArea: data.affectedArea.present
          ? data.affectedArea.value
          : this.affectedArea,
      treatmentApplied: data.treatmentApplied.present
          ? data.treatmentApplied.value
          : this.treatmentApplied,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Infestacoe(')
          ..write('id: $id, ')
          ..write('monitoringPointId: $monitoringPointId, ')
          ..write('organismId: $organismId, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('affectedArea: $affectedArea, ')
          ..write('treatmentApplied: $treatmentApplied, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monitoringPointId, organismId,
      severityLevel, affectedArea, treatmentApplied, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Infestacoe &&
          other.id == this.id &&
          other.monitoringPointId == this.monitoringPointId &&
          other.organismId == this.organismId &&
          other.severityLevel == this.severityLevel &&
          other.affectedArea == this.affectedArea &&
          other.treatmentApplied == this.treatmentApplied &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class InfestacoesCompanion extends UpdateCompanion<Infestacoe> {
  final Value<int> id;
  final Value<int> monitoringPointId;
  final Value<int> organismId;
  final Value<int> severityLevel;
  final Value<double?> affectedArea;
  final Value<String?> treatmentApplied;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const InfestacoesCompanion({
    this.id = const Value.absent(),
    this.monitoringPointId = const Value.absent(),
    this.organismId = const Value.absent(),
    this.severityLevel = const Value.absent(),
    this.affectedArea = const Value.absent(),
    this.treatmentApplied = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InfestacoesCompanion.insert({
    this.id = const Value.absent(),
    required int monitoringPointId,
    required int organismId,
    required int severityLevel,
    this.affectedArea = const Value.absent(),
    this.treatmentApplied = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : monitoringPointId = Value(monitoringPointId),
        organismId = Value(organismId),
        severityLevel = Value(severityLevel),
        createdAt = Value(createdAt);
  static Insertable<Infestacoe> custom({
    Expression<int>? id,
    Expression<int>? monitoringPointId,
    Expression<int>? organismId,
    Expression<int>? severityLevel,
    Expression<double>? affectedArea,
    Expression<String>? treatmentApplied,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monitoringPointId != null) 'monitoring_point_id': monitoringPointId,
      if (organismId != null) 'organism_id': organismId,
      if (severityLevel != null) 'severity_level': severityLevel,
      if (affectedArea != null) 'affected_area': affectedArea,
      if (treatmentApplied != null) 'treatment_applied': treatmentApplied,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InfestacoesCompanion copyWith(
      {Value<int>? id,
      Value<int>? monitoringPointId,
      Value<int>? organismId,
      Value<int>? severityLevel,
      Value<double?>? affectedArea,
      Value<String?>? treatmentApplied,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return InfestacoesCompanion(
      id: id ?? this.id,
      monitoringPointId: monitoringPointId ?? this.monitoringPointId,
      organismId: organismId ?? this.organismId,
      severityLevel: severityLevel ?? this.severityLevel,
      affectedArea: affectedArea ?? this.affectedArea,
      treatmentApplied: treatmentApplied ?? this.treatmentApplied,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monitoringPointId.present) {
      map['monitoring_point_id'] = Variable<int>(monitoringPointId.value);
    }
    if (organismId.present) {
      map['organism_id'] = Variable<int>(organismId.value);
    }
    if (severityLevel.present) {
      map['severity_level'] = Variable<int>(severityLevel.value);
    }
    if (affectedArea.present) {
      map['affected_area'] = Variable<double>(affectedArea.value);
    }
    if (treatmentApplied.present) {
      map['treatment_applied'] = Variable<String>(treatmentApplied.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InfestacoesCompanion(')
          ..write('id: $id, ')
          ..write('monitoringPointId: $monitoringPointId, ')
          ..write('organismId: $organismId, ')
          ..write('severityLevel: $severityLevel, ')
          ..write('affectedArea: $affectedArea, ')
          ..write('treatmentApplied: $treatmentApplied, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PlotsTable extends Plots with TableInfo<$PlotsTable, Plot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  @override
  late final GeneratedColumn<double> area = GeneratedColumn<double>(
      'area', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _cultureIdMeta =
      const VerificationMeta('cultureId');
  @override
  late final GeneratedColumn<int> cultureId = GeneratedColumn<int>(
      'culture_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _varietyIdMeta =
      const VerificationMeta('varietyId');
  @override
  late final GeneratedColumn<int> varietyId = GeneratedColumn<int>(
      'variety_id', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _plantingDateMeta =
      const VerificationMeta('plantingDate');
  @override
  late final GeneratedColumn<String> plantingDate = GeneratedColumn<String>(
      'planting_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _harvestDateMeta =
      const VerificationMeta('harvestDate');
  @override
  late final GeneratedColumn<String> harvestDate = GeneratedColumn<String>(
      'harvest_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        area,
        cultureId,
        varietyId,
        plantingDate,
        harvestDate,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plots';
  @override
  VerificationContext validateIntegrity(Insertable<Plot> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('area')) {
      context.handle(
          _areaMeta, area.isAcceptableOrUnknown(data['area']!, _areaMeta));
    }
    if (data.containsKey('culture_id')) {
      context.handle(_cultureIdMeta,
          cultureId.isAcceptableOrUnknown(data['culture_id']!, _cultureIdMeta));
    }
    if (data.containsKey('variety_id')) {
      context.handle(_varietyIdMeta,
          varietyId.isAcceptableOrUnknown(data['variety_id']!, _varietyIdMeta));
    }
    if (data.containsKey('planting_date')) {
      context.handle(
          _plantingDateMeta,
          plantingDate.isAcceptableOrUnknown(
              data['planting_date']!, _plantingDateMeta));
    }
    if (data.containsKey('harvest_date')) {
      context.handle(
          _harvestDateMeta,
          harvestDate.isAcceptableOrUnknown(
              data['harvest_date']!, _harvestDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Plot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Plot(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      area: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}area']),
      cultureId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}culture_id']),
      varietyId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}variety_id']),
      plantingDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}planting_date']),
      harvestDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}harvest_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PlotsTable createAlias(String alias) {
    return $PlotsTable(attachedDatabase, alias);
  }
}

class Plot extends DataClass implements Insertable<Plot> {
  final int id;
  final String name;
  final double? area;
  final int? cultureId;
  final int? varietyId;
  final String? plantingDate;
  final String? harvestDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Plot(
      {required this.id,
      required this.name,
      this.area,
      this.cultureId,
      this.varietyId,
      this.plantingDate,
      this.harvestDate,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || area != null) {
      map['area'] = Variable<double>(area);
    }
    if (!nullToAbsent || cultureId != null) {
      map['culture_id'] = Variable<int>(cultureId);
    }
    if (!nullToAbsent || varietyId != null) {
      map['variety_id'] = Variable<int>(varietyId);
    }
    if (!nullToAbsent || plantingDate != null) {
      map['planting_date'] = Variable<String>(plantingDate);
    }
    if (!nullToAbsent || harvestDate != null) {
      map['harvest_date'] = Variable<String>(harvestDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PlotsCompanion toCompanion(bool nullToAbsent) {
    return PlotsCompanion(
      id: Value(id),
      name: Value(name),
      area: area == null && nullToAbsent ? const Value.absent() : Value(area),
      cultureId: cultureId == null && nullToAbsent
          ? const Value.absent()
          : Value(cultureId),
      varietyId: varietyId == null && nullToAbsent
          ? const Value.absent()
          : Value(varietyId),
      plantingDate: plantingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(plantingDate),
      harvestDate: harvestDate == null && nullToAbsent
          ? const Value.absent()
          : Value(harvestDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Plot.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Plot(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      area: serializer.fromJson<double?>(json['area']),
      cultureId: serializer.fromJson<int?>(json['cultureId']),
      varietyId: serializer.fromJson<int?>(json['varietyId']),
      plantingDate: serializer.fromJson<String?>(json['plantingDate']),
      harvestDate: serializer.fromJson<String?>(json['harvestDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'area': serializer.toJson<double?>(area),
      'cultureId': serializer.toJson<int?>(cultureId),
      'varietyId': serializer.toJson<int?>(varietyId),
      'plantingDate': serializer.toJson<String?>(plantingDate),
      'harvestDate': serializer.toJson<String?>(harvestDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Plot copyWith(
          {int? id,
          String? name,
          Value<double?> area = const Value.absent(),
          Value<int?> cultureId = const Value.absent(),
          Value<int?> varietyId = const Value.absent(),
          Value<String?> plantingDate = const Value.absent(),
          Value<String?> harvestDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Plot(
        id: id ?? this.id,
        name: name ?? this.name,
        area: area.present ? area.value : this.area,
        cultureId: cultureId.present ? cultureId.value : this.cultureId,
        varietyId: varietyId.present ? varietyId.value : this.varietyId,
        plantingDate:
            plantingDate.present ? plantingDate.value : this.plantingDate,
        harvestDate: harvestDate.present ? harvestDate.value : this.harvestDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Plot copyWithCompanion(PlotsCompanion data) {
    return Plot(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      area: data.area.present ? data.area.value : this.area,
      cultureId: data.cultureId.present ? data.cultureId.value : this.cultureId,
      varietyId: data.varietyId.present ? data.varietyId.value : this.varietyId,
      plantingDate: data.plantingDate.present
          ? data.plantingDate.value
          : this.plantingDate,
      harvestDate:
          data.harvestDate.present ? data.harvestDate.value : this.harvestDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Plot(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('area: $area, ')
          ..write('cultureId: $cultureId, ')
          ..write('varietyId: $varietyId, ')
          ..write('plantingDate: $plantingDate, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, area, cultureId, varietyId,
      plantingDate, harvestDate, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Plot &&
          other.id == this.id &&
          other.name == this.name &&
          other.area == this.area &&
          other.cultureId == this.cultureId &&
          other.varietyId == this.varietyId &&
          other.plantingDate == this.plantingDate &&
          other.harvestDate == this.harvestDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PlotsCompanion extends UpdateCompanion<Plot> {
  final Value<int> id;
  final Value<String> name;
  final Value<double?> area;
  final Value<int?> cultureId;
  final Value<int?> varietyId;
  final Value<String?> plantingDate;
  final Value<String?> harvestDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PlotsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.area = const Value.absent(),
    this.cultureId = const Value.absent(),
    this.varietyId = const Value.absent(),
    this.plantingDate = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PlotsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.area = const Value.absent(),
    this.cultureId = const Value.absent(),
    this.varietyId = const Value.absent(),
    this.plantingDate = const Value.absent(),
    this.harvestDate = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Plot> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? area,
    Expression<int>? cultureId,
    Expression<int>? varietyId,
    Expression<String>? plantingDate,
    Expression<String>? harvestDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (area != null) 'area': area,
      if (cultureId != null) 'culture_id': cultureId,
      if (varietyId != null) 'variety_id': varietyId,
      if (plantingDate != null) 'planting_date': plantingDate,
      if (harvestDate != null) 'harvest_date': harvestDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PlotsCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<double?>? area,
      Value<int?>? cultureId,
      Value<int?>? varietyId,
      Value<String?>? plantingDate,
      Value<String?>? harvestDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PlotsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      cultureId: cultureId ?? this.cultureId,
      varietyId: varietyId ?? this.varietyId,
      plantingDate: plantingDate ?? this.plantingDate,
      harvestDate: harvestDate ?? this.harvestDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (area.present) {
      map['area'] = Variable<double>(area.value);
    }
    if (cultureId.present) {
      map['culture_id'] = Variable<int>(cultureId.value);
    }
    if (varietyId.present) {
      map['variety_id'] = Variable<int>(varietyId.value);
    }
    if (plantingDate.present) {
      map['planting_date'] = Variable<String>(plantingDate.value);
    }
    if (harvestDate.present) {
      map['harvest_date'] = Variable<String>(harvestDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlotsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('area: $area, ')
          ..write('cultureId: $cultureId, ')
          ..write('varietyId: $varietyId, ')
          ..write('plantingDate: $plantingDate, ')
          ..write('harvestDate: $harvestDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PolygonsTable extends Polygons with TableInfo<$PolygonsTable, Polygon> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PolygonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, plotId, latitude, longitude, orderIndex, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'polygons';
  @override
  VerificationContext validateIntegrity(Insertable<Polygon> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Polygon map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Polygon(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PolygonsTable createAlias(String alias) {
    return $PolygonsTable(attachedDatabase, alias);
  }
}

class Polygon extends DataClass implements Insertable<Polygon> {
  final int id;
  final int plotId;
  final double latitude;
  final double longitude;
  final int orderIndex;
  final DateTime createdAt;
  const Polygon(
      {required this.id,
      required this.plotId,
      required this.latitude,
      required this.longitude,
      required this.orderIndex,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['order_index'] = Variable<int>(orderIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PolygonsCompanion toCompanion(bool nullToAbsent) {
    return PolygonsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      orderIndex: Value(orderIndex),
      createdAt: Value(createdAt),
    );
  }

  factory Polygon.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Polygon(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Polygon copyWith(
          {int? id,
          int? plotId,
          double? latitude,
          double? longitude,
          int? orderIndex,
          DateTime? createdAt}) =>
      Polygon(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        orderIndex: orderIndex ?? this.orderIndex,
        createdAt: createdAt ?? this.createdAt,
      );
  Polygon copyWithCompanion(PolygonsCompanion data) {
    return Polygon(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Polygon(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, plotId, latitude, longitude, orderIndex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Polygon &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.orderIndex == this.orderIndex &&
          other.createdAt == this.createdAt);
}

class PolygonsCompanion extends UpdateCompanion<Polygon> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<int> orderIndex;
  final Value<DateTime> createdAt;
  const PolygonsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PolygonsCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required double latitude,
    required double longitude,
    required int orderIndex,
    required DateTime createdAt,
  })  : plotId = Value(plotId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        orderIndex = Value(orderIndex),
        createdAt = Value(createdAt);
  static Insertable<Polygon> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? orderIndex,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (orderIndex != null) 'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PolygonsCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<int>? orderIndex,
      Value<DateTime>? createdAt}) {
    return PolygonsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PolygonsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AplicacoesTable extends Aplicacoes
    with TableInfo<$AplicacoesTable, Aplicacoe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AplicacoesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _applicationDateMeta =
      const VerificationMeta('applicationDate');
  @override
  late final GeneratedColumn<String> applicationDate = GeneratedColumn<String>(
      'application_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<double> dosage = GeneratedColumn<double>(
      'dosage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dosageUnitMeta =
      const VerificationMeta('dosageUnit');
  @override
  late final GeneratedColumn<String> dosageUnit = GeneratedColumn<String>(
      'dosage_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _applicationMethodMeta =
      const VerificationMeta('applicationMethod');
  @override
  late final GeneratedColumn<String> applicationMethod =
      GeneratedColumn<String>('application_method', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _weatherConditionMeta =
      const VerificationMeta('weatherCondition');
  @override
  late final GeneratedColumn<String> weatherCondition = GeneratedColumn<String>(
      'weather_condition', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        productName,
        applicationDate,
        dosage,
        dosageUnit,
        applicationMethod,
        weatherCondition,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aplicacoes';
  @override
  VerificationContext validateIntegrity(Insertable<Aplicacoe> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('application_date')) {
      context.handle(
          _applicationDateMeta,
          applicationDate.isAcceptableOrUnknown(
              data['application_date']!, _applicationDateMeta));
    } else if (isInserting) {
      context.missing(_applicationDateMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    }
    if (data.containsKey('dosage_unit')) {
      context.handle(
          _dosageUnitMeta,
          dosageUnit.isAcceptableOrUnknown(
              data['dosage_unit']!, _dosageUnitMeta));
    }
    if (data.containsKey('application_method')) {
      context.handle(
          _applicationMethodMeta,
          applicationMethod.isAcceptableOrUnknown(
              data['application_method']!, _applicationMethodMeta));
    }
    if (data.containsKey('weather_condition')) {
      context.handle(
          _weatherConditionMeta,
          weatherCondition.isAcceptableOrUnknown(
              data['weather_condition']!, _weatherConditionMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Aplicacoe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Aplicacoe(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      applicationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}application_date'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dosage']),
      dosageUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage_unit']),
      applicationMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}application_method']),
      weatherCondition: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}weather_condition']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $AplicacoesTable createAlias(String alias) {
    return $AplicacoesTable(attachedDatabase, alias);
  }
}

class Aplicacoe extends DataClass implements Insertable<Aplicacoe> {
  final int id;
  final int plotId;
  final String productName;
  final String applicationDate;
  final double? dosage;
  final String? dosageUnit;
  final String? applicationMethod;
  final String? weatherCondition;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Aplicacoe(
      {required this.id,
      required this.plotId,
      required this.productName,
      required this.applicationDate,
      this.dosage,
      this.dosageUnit,
      this.applicationMethod,
      this.weatherCondition,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['product_name'] = Variable<String>(productName);
    map['application_date'] = Variable<String>(applicationDate);
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<double>(dosage);
    }
    if (!nullToAbsent || dosageUnit != null) {
      map['dosage_unit'] = Variable<String>(dosageUnit);
    }
    if (!nullToAbsent || applicationMethod != null) {
      map['application_method'] = Variable<String>(applicationMethod);
    }
    if (!nullToAbsent || weatherCondition != null) {
      map['weather_condition'] = Variable<String>(weatherCondition);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AplicacoesCompanion toCompanion(bool nullToAbsent) {
    return AplicacoesCompanion(
      id: Value(id),
      plotId: Value(plotId),
      productName: Value(productName),
      applicationDate: Value(applicationDate),
      dosage:
          dosage == null && nullToAbsent ? const Value.absent() : Value(dosage),
      dosageUnit: dosageUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(dosageUnit),
      applicationMethod: applicationMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(applicationMethod),
      weatherCondition: weatherCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(weatherCondition),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Aplicacoe.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Aplicacoe(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      productName: serializer.fromJson<String>(json['productName']),
      applicationDate: serializer.fromJson<String>(json['applicationDate']),
      dosage: serializer.fromJson<double?>(json['dosage']),
      dosageUnit: serializer.fromJson<String?>(json['dosageUnit']),
      applicationMethod:
          serializer.fromJson<String?>(json['applicationMethod']),
      weatherCondition: serializer.fromJson<String?>(json['weatherCondition']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'productName': serializer.toJson<String>(productName),
      'applicationDate': serializer.toJson<String>(applicationDate),
      'dosage': serializer.toJson<double?>(dosage),
      'dosageUnit': serializer.toJson<String?>(dosageUnit),
      'applicationMethod': serializer.toJson<String?>(applicationMethod),
      'weatherCondition': serializer.toJson<String?>(weatherCondition),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Aplicacoe copyWith(
          {int? id,
          int? plotId,
          String? productName,
          String? applicationDate,
          Value<double?> dosage = const Value.absent(),
          Value<String?> dosageUnit = const Value.absent(),
          Value<String?> applicationMethod = const Value.absent(),
          Value<String?> weatherCondition = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Aplicacoe(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        productName: productName ?? this.productName,
        applicationDate: applicationDate ?? this.applicationDate,
        dosage: dosage.present ? dosage.value : this.dosage,
        dosageUnit: dosageUnit.present ? dosageUnit.value : this.dosageUnit,
        applicationMethod: applicationMethod.present
            ? applicationMethod.value
            : this.applicationMethod,
        weatherCondition: weatherCondition.present
            ? weatherCondition.value
            : this.weatherCondition,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Aplicacoe copyWithCompanion(AplicacoesCompanion data) {
    return Aplicacoe(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      applicationDate: data.applicationDate.present
          ? data.applicationDate.value
          : this.applicationDate,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      dosageUnit:
          data.dosageUnit.present ? data.dosageUnit.value : this.dosageUnit,
      applicationMethod: data.applicationMethod.present
          ? data.applicationMethod.value
          : this.applicationMethod,
      weatherCondition: data.weatherCondition.present
          ? data.weatherCondition.value
          : this.weatherCondition,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Aplicacoe(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('productName: $productName, ')
          ..write('applicationDate: $applicationDate, ')
          ..write('dosage: $dosage, ')
          ..write('dosageUnit: $dosageUnit, ')
          ..write('applicationMethod: $applicationMethod, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plotId,
      productName,
      applicationDate,
      dosage,
      dosageUnit,
      applicationMethod,
      weatherCondition,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Aplicacoe &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.productName == this.productName &&
          other.applicationDate == this.applicationDate &&
          other.dosage == this.dosage &&
          other.dosageUnit == this.dosageUnit &&
          other.applicationMethod == this.applicationMethod &&
          other.weatherCondition == this.weatherCondition &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AplicacoesCompanion extends UpdateCompanion<Aplicacoe> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<String> productName;
  final Value<String> applicationDate;
  final Value<double?> dosage;
  final Value<String?> dosageUnit;
  final Value<String?> applicationMethod;
  final Value<String?> weatherCondition;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AplicacoesCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.productName = const Value.absent(),
    this.applicationDate = const Value.absent(),
    this.dosage = const Value.absent(),
    this.dosageUnit = const Value.absent(),
    this.applicationMethod = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AplicacoesCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required String productName,
    required String applicationDate,
    this.dosage = const Value.absent(),
    this.dosageUnit = const Value.absent(),
    this.applicationMethod = const Value.absent(),
    this.weatherCondition = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : plotId = Value(plotId),
        productName = Value(productName),
        applicationDate = Value(applicationDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Aplicacoe> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? productName,
    Expression<String>? applicationDate,
    Expression<double>? dosage,
    Expression<String>? dosageUnit,
    Expression<String>? applicationMethod,
    Expression<String>? weatherCondition,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (productName != null) 'product_name': productName,
      if (applicationDate != null) 'application_date': applicationDate,
      if (dosage != null) 'dosage': dosage,
      if (dosageUnit != null) 'dosage_unit': dosageUnit,
      if (applicationMethod != null) 'application_method': applicationMethod,
      if (weatherCondition != null) 'weather_condition': weatherCondition,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AplicacoesCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<String>? productName,
      Value<String>? applicationDate,
      Value<double?>? dosage,
      Value<String?>? dosageUnit,
      Value<String?>? applicationMethod,
      Value<String?>? weatherCondition,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return AplicacoesCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      productName: productName ?? this.productName,
      applicationDate: applicationDate ?? this.applicationDate,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      weatherCondition: weatherCondition ?? this.weatherCondition,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (applicationDate.present) {
      map['application_date'] = Variable<String>(applicationDate.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<double>(dosage.value);
    }
    if (dosageUnit.present) {
      map['dosage_unit'] = Variable<String>(dosageUnit.value);
    }
    if (applicationMethod.present) {
      map['application_method'] = Variable<String>(applicationMethod.value);
    }
    if (weatherCondition.present) {
      map['weather_condition'] = Variable<String>(weatherCondition.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AplicacoesCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('productName: $productName, ')
          ..write('applicationDate: $applicationDate, ')
          ..write('dosage: $dosage, ')
          ..write('dosageUnit: $dosageUnit, ')
          ..write('applicationMethod: $applicationMethod, ')
          ..write('weatherCondition: $weatherCondition, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionsTable extends Prescriptions
    with TableInfo<$PrescriptionsTable, Prescription> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _prescriptionDateMeta =
      const VerificationMeta('prescriptionDate');
  @override
  late final GeneratedColumn<String> prescriptionDate = GeneratedColumn<String>(
      'prescription_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prescriptionTypeMeta =
      const VerificationMeta('prescriptionType');
  @override
  late final GeneratedColumn<String> prescriptionType = GeneratedColumn<String>(
      'prescription_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        prescriptionDate,
        prescriptionType,
        status,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescriptions';
  @override
  VerificationContext validateIntegrity(Insertable<Prescription> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('prescription_date')) {
      context.handle(
          _prescriptionDateMeta,
          prescriptionDate.isAcceptableOrUnknown(
              data['prescription_date']!, _prescriptionDateMeta));
    } else if (isInserting) {
      context.missing(_prescriptionDateMeta);
    }
    if (data.containsKey('prescription_type')) {
      context.handle(
          _prescriptionTypeMeta,
          prescriptionType.isAcceptableOrUnknown(
              data['prescription_type']!, _prescriptionTypeMeta));
    } else if (isInserting) {
      context.missing(_prescriptionTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Prescription map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Prescription(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      prescriptionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}prescription_date'])!,
      prescriptionType: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}prescription_type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PrescriptionsTable createAlias(String alias) {
    return $PrescriptionsTable(attachedDatabase, alias);
  }
}

class Prescription extends DataClass implements Insertable<Prescription> {
  final int id;
  final int plotId;
  final String prescriptionDate;
  final String prescriptionType;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Prescription(
      {required this.id,
      required this.plotId,
      required this.prescriptionDate,
      required this.prescriptionType,
      required this.status,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['prescription_date'] = Variable<String>(prescriptionDate);
    map['prescription_type'] = Variable<String>(prescriptionType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrescriptionsCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      prescriptionDate: Value(prescriptionDate),
      prescriptionType: Value(prescriptionType),
      status: Value(status),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Prescription.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Prescription(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      prescriptionDate: serializer.fromJson<String>(json['prescriptionDate']),
      prescriptionType: serializer.fromJson<String>(json['prescriptionType']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'prescriptionDate': serializer.toJson<String>(prescriptionDate),
      'prescriptionType': serializer.toJson<String>(prescriptionType),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Prescription copyWith(
          {int? id,
          int? plotId,
          String? prescriptionDate,
          String? prescriptionType,
          String? status,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      Prescription(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        prescriptionDate: prescriptionDate ?? this.prescriptionDate,
        prescriptionType: prescriptionType ?? this.prescriptionType,
        status: status ?? this.status,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Prescription copyWithCompanion(PrescriptionsCompanion data) {
    return Prescription(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      prescriptionDate: data.prescriptionDate.present
          ? data.prescriptionDate.value
          : this.prescriptionDate,
      prescriptionType: data.prescriptionType.present
          ? data.prescriptionType.value
          : this.prescriptionType,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Prescription(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('prescriptionDate: $prescriptionDate, ')
          ..write('prescriptionType: $prescriptionType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, plotId, prescriptionDate,
      prescriptionType, status, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Prescription &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.prescriptionDate == this.prescriptionDate &&
          other.prescriptionType == this.prescriptionType &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PrescriptionsCompanion extends UpdateCompanion<Prescription> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<String> prescriptionDate;
  final Value<String> prescriptionType;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const PrescriptionsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.prescriptionDate = const Value.absent(),
    this.prescriptionType = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  PrescriptionsCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required String prescriptionDate,
    required String prescriptionType,
    required String status,
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : plotId = Value(plotId),
        prescriptionDate = Value(prescriptionDate),
        prescriptionType = Value(prescriptionType),
        status = Value(status),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Prescription> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? prescriptionDate,
    Expression<String>? prescriptionType,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (prescriptionDate != null) 'prescription_date': prescriptionDate,
      if (prescriptionType != null) 'prescription_type': prescriptionType,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  PrescriptionsCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<String>? prescriptionDate,
      Value<String>? prescriptionType,
      Value<String>? status,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return PrescriptionsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      prescriptionDate: prescriptionDate ?? this.prescriptionDate,
      prescriptionType: prescriptionType ?? this.prescriptionType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (prescriptionDate.present) {
      map['prescription_date'] = Variable<String>(prescriptionDate.value);
    }
    if (prescriptionType.present) {
      map['prescription_type'] = Variable<String>(prescriptionType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('prescriptionDate: $prescriptionDate, ')
          ..write('prescriptionType: $prescriptionType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PrescriptionItemsTable extends PrescriptionItems
    with TableInfo<$PrescriptionItemsTable, PrescriptionItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrescriptionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _prescriptionIdMeta =
      const VerificationMeta('prescriptionId');
  @override
  late final GeneratedColumn<int> prescriptionId = GeneratedColumn<int>(
      'prescription_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<double> dosage = GeneratedColumn<double>(
      'dosage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _dosageUnitMeta =
      const VerificationMeta('dosageUnit');
  @override
  late final GeneratedColumn<String> dosageUnit = GeneratedColumn<String>(
      'dosage_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _applicationMethodMeta =
      const VerificationMeta('applicationMethod');
  @override
  late final GeneratedColumn<String> applicationMethod =
      GeneratedColumn<String>('application_method', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        prescriptionId,
        productName,
        dosage,
        dosageUnit,
        applicationMethod,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prescription_items';
  @override
  VerificationContext validateIntegrity(Insertable<PrescriptionItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('prescription_id')) {
      context.handle(
          _prescriptionIdMeta,
          prescriptionId.isAcceptableOrUnknown(
              data['prescription_id']!, _prescriptionIdMeta));
    } else if (isInserting) {
      context.missing(_prescriptionIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(_dosageMeta,
          dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta));
    }
    if (data.containsKey('dosage_unit')) {
      context.handle(
          _dosageUnitMeta,
          dosageUnit.isAcceptableOrUnknown(
              data['dosage_unit']!, _dosageUnitMeta));
    }
    if (data.containsKey('application_method')) {
      context.handle(
          _applicationMethodMeta,
          applicationMethod.isAcceptableOrUnknown(
              data['application_method']!, _applicationMethodMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrescriptionItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrescriptionItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      prescriptionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}prescription_id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      dosage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}dosage']),
      dosageUnit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}dosage_unit']),
      applicationMethod: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}application_method']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PrescriptionItemsTable createAlias(String alias) {
    return $PrescriptionItemsTable(attachedDatabase, alias);
  }
}

class PrescriptionItem extends DataClass
    implements Insertable<PrescriptionItem> {
  final int id;
  final int prescriptionId;
  final String productName;
  final double? dosage;
  final String? dosageUnit;
  final String? applicationMethod;
  final String? notes;
  final DateTime createdAt;
  const PrescriptionItem(
      {required this.id,
      required this.prescriptionId,
      required this.productName,
      this.dosage,
      this.dosageUnit,
      this.applicationMethod,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['prescription_id'] = Variable<int>(prescriptionId);
    map['product_name'] = Variable<String>(productName);
    if (!nullToAbsent || dosage != null) {
      map['dosage'] = Variable<double>(dosage);
    }
    if (!nullToAbsent || dosageUnit != null) {
      map['dosage_unit'] = Variable<String>(dosageUnit);
    }
    if (!nullToAbsent || applicationMethod != null) {
      map['application_method'] = Variable<String>(applicationMethod);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PrescriptionItemsCompanion toCompanion(bool nullToAbsent) {
    return PrescriptionItemsCompanion(
      id: Value(id),
      prescriptionId: Value(prescriptionId),
      productName: Value(productName),
      dosage:
          dosage == null && nullToAbsent ? const Value.absent() : Value(dosage),
      dosageUnit: dosageUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(dosageUnit),
      applicationMethod: applicationMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(applicationMethod),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PrescriptionItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrescriptionItem(
      id: serializer.fromJson<int>(json['id']),
      prescriptionId: serializer.fromJson<int>(json['prescriptionId']),
      productName: serializer.fromJson<String>(json['productName']),
      dosage: serializer.fromJson<double?>(json['dosage']),
      dosageUnit: serializer.fromJson<String?>(json['dosageUnit']),
      applicationMethod:
          serializer.fromJson<String?>(json['applicationMethod']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'prescriptionId': serializer.toJson<int>(prescriptionId),
      'productName': serializer.toJson<String>(productName),
      'dosage': serializer.toJson<double?>(dosage),
      'dosageUnit': serializer.toJson<String?>(dosageUnit),
      'applicationMethod': serializer.toJson<String?>(applicationMethod),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PrescriptionItem copyWith(
          {int? id,
          int? prescriptionId,
          String? productName,
          Value<double?> dosage = const Value.absent(),
          Value<String?> dosageUnit = const Value.absent(),
          Value<String?> applicationMethod = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      PrescriptionItem(
        id: id ?? this.id,
        prescriptionId: prescriptionId ?? this.prescriptionId,
        productName: productName ?? this.productName,
        dosage: dosage.present ? dosage.value : this.dosage,
        dosageUnit: dosageUnit.present ? dosageUnit.value : this.dosageUnit,
        applicationMethod: applicationMethod.present
            ? applicationMethod.value
            : this.applicationMethod,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  PrescriptionItem copyWithCompanion(PrescriptionItemsCompanion data) {
    return PrescriptionItem(
      id: data.id.present ? data.id.value : this.id,
      prescriptionId: data.prescriptionId.present
          ? data.prescriptionId.value
          : this.prescriptionId,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      dosageUnit:
          data.dosageUnit.present ? data.dosageUnit.value : this.dosageUnit,
      applicationMethod: data.applicationMethod.present
          ? data.applicationMethod.value
          : this.applicationMethod,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionItem(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('productName: $productName, ')
          ..write('dosage: $dosage, ')
          ..write('dosageUnit: $dosageUnit, ')
          ..write('applicationMethod: $applicationMethod, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, prescriptionId, productName, dosage,
      dosageUnit, applicationMethod, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrescriptionItem &&
          other.id == this.id &&
          other.prescriptionId == this.prescriptionId &&
          other.productName == this.productName &&
          other.dosage == this.dosage &&
          other.dosageUnit == this.dosageUnit &&
          other.applicationMethod == this.applicationMethod &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PrescriptionItemsCompanion extends UpdateCompanion<PrescriptionItem> {
  final Value<int> id;
  final Value<int> prescriptionId;
  final Value<String> productName;
  final Value<double?> dosage;
  final Value<String?> dosageUnit;
  final Value<String?> applicationMethod;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const PrescriptionItemsCompanion({
    this.id = const Value.absent(),
    this.prescriptionId = const Value.absent(),
    this.productName = const Value.absent(),
    this.dosage = const Value.absent(),
    this.dosageUnit = const Value.absent(),
    this.applicationMethod = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PrescriptionItemsCompanion.insert({
    this.id = const Value.absent(),
    required int prescriptionId,
    required String productName,
    this.dosage = const Value.absent(),
    this.dosageUnit = const Value.absent(),
    this.applicationMethod = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : prescriptionId = Value(prescriptionId),
        productName = Value(productName),
        createdAt = Value(createdAt);
  static Insertable<PrescriptionItem> custom({
    Expression<int>? id,
    Expression<int>? prescriptionId,
    Expression<String>? productName,
    Expression<double>? dosage,
    Expression<String>? dosageUnit,
    Expression<String>? applicationMethod,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (prescriptionId != null) 'prescription_id': prescriptionId,
      if (productName != null) 'product_name': productName,
      if (dosage != null) 'dosage': dosage,
      if (dosageUnit != null) 'dosage_unit': dosageUnit,
      if (applicationMethod != null) 'application_method': applicationMethod,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PrescriptionItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? prescriptionId,
      Value<String>? productName,
      Value<double?>? dosage,
      Value<String?>? dosageUnit,
      Value<String?>? applicationMethod,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return PrescriptionItemsCompanion(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      productName: productName ?? this.productName,
      dosage: dosage ?? this.dosage,
      dosageUnit: dosageUnit ?? this.dosageUnit,
      applicationMethod: applicationMethod ?? this.applicationMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (prescriptionId.present) {
      map['prescription_id'] = Variable<int>(prescriptionId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<double>(dosage.value);
    }
    if (dosageUnit.present) {
      map['dosage_unit'] = Variable<String>(dosageUnit.value);
    }
    if (applicationMethod.present) {
      map['application_method'] = Variable<String>(applicationMethod.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrescriptionItemsCompanion(')
          ..write('id: $id, ')
          ..write('prescriptionId: $prescriptionId, ')
          ..write('productName: $productName, ')
          ..write('dosage: $dosage, ')
          ..write('dosageUnit: $dosageUnit, ')
          ..write('applicationMethod: $applicationMethod, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $CalibracaoFertilizantesTable extends CalibracaoFertilizantes
    with TableInfo<$CalibracaoFertilizantesTable, CalibracaoFertilizante> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalibracaoFertilizantesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _fertilizerNameMeta =
      const VerificationMeta('fertilizerName');
  @override
  late final GeneratedColumn<String> fertilizerName = GeneratedColumn<String>(
      'fertilizer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _calibrationDateMeta =
      const VerificationMeta('calibrationDate');
  @override
  late final GeneratedColumn<String> calibrationDate = GeneratedColumn<String>(
      'calibration_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetDosageMeta =
      const VerificationMeta('targetDosage');
  @override
  late final GeneratedColumn<double> targetDosage = GeneratedColumn<double>(
      'target_dosage', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _actualDosageMeta =
      const VerificationMeta('actualDosage');
  @override
  late final GeneratedColumn<double> actualDosage = GeneratedColumn<double>(
      'actual_dosage', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _calibrationFactorMeta =
      const VerificationMeta('calibrationFactor');
  @override
  late final GeneratedColumn<double> calibrationFactor =
      GeneratedColumn<double>('calibration_factor', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        fertilizerName,
        calibrationDate,
        targetDosage,
        actualDosage,
        calibrationFactor,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calibracao_fertilizantes';
  @override
  VerificationContext validateIntegrity(
      Insertable<CalibracaoFertilizante> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('fertilizer_name')) {
      context.handle(
          _fertilizerNameMeta,
          fertilizerName.isAcceptableOrUnknown(
              data['fertilizer_name']!, _fertilizerNameMeta));
    } else if (isInserting) {
      context.missing(_fertilizerNameMeta);
    }
    if (data.containsKey('calibration_date')) {
      context.handle(
          _calibrationDateMeta,
          calibrationDate.isAcceptableOrUnknown(
              data['calibration_date']!, _calibrationDateMeta));
    } else if (isInserting) {
      context.missing(_calibrationDateMeta);
    }
    if (data.containsKey('target_dosage')) {
      context.handle(
          _targetDosageMeta,
          targetDosage.isAcceptableOrUnknown(
              data['target_dosage']!, _targetDosageMeta));
    } else if (isInserting) {
      context.missing(_targetDosageMeta);
    }
    if (data.containsKey('actual_dosage')) {
      context.handle(
          _actualDosageMeta,
          actualDosage.isAcceptableOrUnknown(
              data['actual_dosage']!, _actualDosageMeta));
    }
    if (data.containsKey('calibration_factor')) {
      context.handle(
          _calibrationFactorMeta,
          calibrationFactor.isAcceptableOrUnknown(
              data['calibration_factor']!, _calibrationFactorMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalibracaoFertilizante map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalibracaoFertilizante(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      fertilizerName: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}fertilizer_name'])!,
      calibrationDate: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}calibration_date'])!,
      targetDosage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}target_dosage'])!,
      actualDosage: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_dosage']),
      calibrationFactor: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}calibration_factor']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CalibracaoFertilizantesTable createAlias(String alias) {
    return $CalibracaoFertilizantesTable(attachedDatabase, alias);
  }
}

class CalibracaoFertilizante extends DataClass
    implements Insertable<CalibracaoFertilizante> {
  final int id;
  final int plotId;
  final String fertilizerName;
  final String calibrationDate;
  final double targetDosage;
  final double? actualDosage;
  final double? calibrationFactor;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const CalibracaoFertilizante(
      {required this.id,
      required this.plotId,
      required this.fertilizerName,
      required this.calibrationDate,
      required this.targetDosage,
      this.actualDosage,
      this.calibrationFactor,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['fertilizer_name'] = Variable<String>(fertilizerName);
    map['calibration_date'] = Variable<String>(calibrationDate);
    map['target_dosage'] = Variable<double>(targetDosage);
    if (!nullToAbsent || actualDosage != null) {
      map['actual_dosage'] = Variable<double>(actualDosage);
    }
    if (!nullToAbsent || calibrationFactor != null) {
      map['calibration_factor'] = Variable<double>(calibrationFactor);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CalibracaoFertilizantesCompanion toCompanion(bool nullToAbsent) {
    return CalibracaoFertilizantesCompanion(
      id: Value(id),
      plotId: Value(plotId),
      fertilizerName: Value(fertilizerName),
      calibrationDate: Value(calibrationDate),
      targetDosage: Value(targetDosage),
      actualDosage: actualDosage == null && nullToAbsent
          ? const Value.absent()
          : Value(actualDosage),
      calibrationFactor: calibrationFactor == null && nullToAbsent
          ? const Value.absent()
          : Value(calibrationFactor),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CalibracaoFertilizante.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalibracaoFertilizante(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      fertilizerName: serializer.fromJson<String>(json['fertilizerName']),
      calibrationDate: serializer.fromJson<String>(json['calibrationDate']),
      targetDosage: serializer.fromJson<double>(json['targetDosage']),
      actualDosage: serializer.fromJson<double?>(json['actualDosage']),
      calibrationFactor:
          serializer.fromJson<double?>(json['calibrationFactor']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'fertilizerName': serializer.toJson<String>(fertilizerName),
      'calibrationDate': serializer.toJson<String>(calibrationDate),
      'targetDosage': serializer.toJson<double>(targetDosage),
      'actualDosage': serializer.toJson<double?>(actualDosage),
      'calibrationFactor': serializer.toJson<double?>(calibrationFactor),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CalibracaoFertilizante copyWith(
          {int? id,
          int? plotId,
          String? fertilizerName,
          String? calibrationDate,
          double? targetDosage,
          Value<double?> actualDosage = const Value.absent(),
          Value<double?> calibrationFactor = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      CalibracaoFertilizante(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        fertilizerName: fertilizerName ?? this.fertilizerName,
        calibrationDate: calibrationDate ?? this.calibrationDate,
        targetDosage: targetDosage ?? this.targetDosage,
        actualDosage:
            actualDosage.present ? actualDosage.value : this.actualDosage,
        calibrationFactor: calibrationFactor.present
            ? calibrationFactor.value
            : this.calibrationFactor,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CalibracaoFertilizante copyWithCompanion(
      CalibracaoFertilizantesCompanion data) {
    return CalibracaoFertilizante(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      fertilizerName: data.fertilizerName.present
          ? data.fertilizerName.value
          : this.fertilizerName,
      calibrationDate: data.calibrationDate.present
          ? data.calibrationDate.value
          : this.calibrationDate,
      targetDosage: data.targetDosage.present
          ? data.targetDosage.value
          : this.targetDosage,
      actualDosage: data.actualDosage.present
          ? data.actualDosage.value
          : this.actualDosage,
      calibrationFactor: data.calibrationFactor.present
          ? data.calibrationFactor.value
          : this.calibrationFactor,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalibracaoFertilizante(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('fertilizerName: $fertilizerName, ')
          ..write('calibrationDate: $calibrationDate, ')
          ..write('targetDosage: $targetDosage, ')
          ..write('actualDosage: $actualDosage, ')
          ..write('calibrationFactor: $calibrationFactor, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plotId,
      fertilizerName,
      calibrationDate,
      targetDosage,
      actualDosage,
      calibrationFactor,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalibracaoFertilizante &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.fertilizerName == this.fertilizerName &&
          other.calibrationDate == this.calibrationDate &&
          other.targetDosage == this.targetDosage &&
          other.actualDosage == this.actualDosage &&
          other.calibrationFactor == this.calibrationFactor &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CalibracaoFertilizantesCompanion
    extends UpdateCompanion<CalibracaoFertilizante> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<String> fertilizerName;
  final Value<String> calibrationDate;
  final Value<double> targetDosage;
  final Value<double?> actualDosage;
  final Value<double?> calibrationFactor;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CalibracaoFertilizantesCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.fertilizerName = const Value.absent(),
    this.calibrationDate = const Value.absent(),
    this.targetDosage = const Value.absent(),
    this.actualDosage = const Value.absent(),
    this.calibrationFactor = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CalibracaoFertilizantesCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required String fertilizerName,
    required String calibrationDate,
    required double targetDosage,
    this.actualDosage = const Value.absent(),
    this.calibrationFactor = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : plotId = Value(plotId),
        fertilizerName = Value(fertilizerName),
        calibrationDate = Value(calibrationDate),
        targetDosage = Value(targetDosage),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<CalibracaoFertilizante> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? fertilizerName,
    Expression<String>? calibrationDate,
    Expression<double>? targetDosage,
    Expression<double>? actualDosage,
    Expression<double>? calibrationFactor,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (fertilizerName != null) 'fertilizer_name': fertilizerName,
      if (calibrationDate != null) 'calibration_date': calibrationDate,
      if (targetDosage != null) 'target_dosage': targetDosage,
      if (actualDosage != null) 'actual_dosage': actualDosage,
      if (calibrationFactor != null) 'calibration_factor': calibrationFactor,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CalibracaoFertilizantesCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<String>? fertilizerName,
      Value<String>? calibrationDate,
      Value<double>? targetDosage,
      Value<double?>? actualDosage,
      Value<double?>? calibrationFactor,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return CalibracaoFertilizantesCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      fertilizerName: fertilizerName ?? this.fertilizerName,
      calibrationDate: calibrationDate ?? this.calibrationDate,
      targetDosage: targetDosage ?? this.targetDosage,
      actualDosage: actualDosage ?? this.actualDosage,
      calibrationFactor: calibrationFactor ?? this.calibrationFactor,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (fertilizerName.present) {
      map['fertilizer_name'] = Variable<String>(fertilizerName.value);
    }
    if (calibrationDate.present) {
      map['calibration_date'] = Variable<String>(calibrationDate.value);
    }
    if (targetDosage.present) {
      map['target_dosage'] = Variable<double>(targetDosage.value);
    }
    if (actualDosage.present) {
      map['actual_dosage'] = Variable<double>(actualDosage.value);
    }
    if (calibrationFactor.present) {
      map['calibration_factor'] = Variable<double>(calibrationFactor.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalibracaoFertilizantesCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('fertilizerName: $fertilizerName, ')
          ..write('calibrationDate: $calibrationDate, ')
          ..write('targetDosage: $targetDosage, ')
          ..write('actualDosage: $actualDosage, ')
          ..write('calibrationFactor: $calibrationFactor, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $EstoqueTable extends Estoque with TableInfo<$EstoqueTable, EstoqueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstoqueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productTypeMeta =
      const VerificationMeta('productType');
  @override
  late final GeneratedColumn<String> productType = GeneratedColumn<String>(
      'product_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentQuantityMeta =
      const VerificationMeta('currentQuantity');
  @override
  late final GeneratedColumn<double> currentQuantity = GeneratedColumn<double>(
      'current_quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
      'unit', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _minQuantityMeta =
      const VerificationMeta('minQuantity');
  @override
  late final GeneratedColumn<double> minQuantity = GeneratedColumn<double>(
      'min_quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _maxQuantityMeta =
      const VerificationMeta('maxQuantity');
  @override
  late final GeneratedColumn<double> maxQuantity = GeneratedColumn<double>(
      'max_quantity', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        productName,
        productType,
        currentQuantity,
        unit,
        minQuantity,
        maxQuantity,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estoque';
  @override
  VerificationContext validateIntegrity(Insertable<EstoqueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('product_type')) {
      context.handle(
          _productTypeMeta,
          productType.isAcceptableOrUnknown(
              data['product_type']!, _productTypeMeta));
    } else if (isInserting) {
      context.missing(_productTypeMeta);
    }
    if (data.containsKey('current_quantity')) {
      context.handle(
          _currentQuantityMeta,
          currentQuantity.isAcceptableOrUnknown(
              data['current_quantity']!, _currentQuantityMeta));
    } else if (isInserting) {
      context.missing(_currentQuantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
          _unitMeta, unit.isAcceptableOrUnknown(data['unit']!, _unitMeta));
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('min_quantity')) {
      context.handle(
          _minQuantityMeta,
          minQuantity.isAcceptableOrUnknown(
              data['min_quantity']!, _minQuantityMeta));
    }
    if (data.containsKey('max_quantity')) {
      context.handle(
          _maxQuantityMeta,
          maxQuantity.isAcceptableOrUnknown(
              data['max_quantity']!, _maxQuantityMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EstoqueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstoqueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      productType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_type'])!,
      currentQuantity: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}current_quantity'])!,
      unit: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}unit'])!,
      minQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}min_quantity']),
      maxQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}max_quantity']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EstoqueTable createAlias(String alias) {
    return $EstoqueTable(attachedDatabase, alias);
  }
}

class EstoqueData extends DataClass implements Insertable<EstoqueData> {
  final int id;
  final String productName;
  final String productType;
  final double currentQuantity;
  final String unit;
  final double? minQuantity;
  final double? maxQuantity;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EstoqueData(
      {required this.id,
      required this.productName,
      required this.productType,
      required this.currentQuantity,
      required this.unit,
      this.minQuantity,
      this.maxQuantity,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['product_name'] = Variable<String>(productName);
    map['product_type'] = Variable<String>(productType);
    map['current_quantity'] = Variable<double>(currentQuantity);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || minQuantity != null) {
      map['min_quantity'] = Variable<double>(minQuantity);
    }
    if (!nullToAbsent || maxQuantity != null) {
      map['max_quantity'] = Variable<double>(maxQuantity);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EstoqueCompanion toCompanion(bool nullToAbsent) {
    return EstoqueCompanion(
      id: Value(id),
      productName: Value(productName),
      productType: Value(productType),
      currentQuantity: Value(currentQuantity),
      unit: Value(unit),
      minQuantity: minQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(minQuantity),
      maxQuantity: maxQuantity == null && nullToAbsent
          ? const Value.absent()
          : Value(maxQuantity),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EstoqueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstoqueData(
      id: serializer.fromJson<int>(json['id']),
      productName: serializer.fromJson<String>(json['productName']),
      productType: serializer.fromJson<String>(json['productType']),
      currentQuantity: serializer.fromJson<double>(json['currentQuantity']),
      unit: serializer.fromJson<String>(json['unit']),
      minQuantity: serializer.fromJson<double?>(json['minQuantity']),
      maxQuantity: serializer.fromJson<double?>(json['maxQuantity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'productName': serializer.toJson<String>(productName),
      'productType': serializer.toJson<String>(productType),
      'currentQuantity': serializer.toJson<double>(currentQuantity),
      'unit': serializer.toJson<String>(unit),
      'minQuantity': serializer.toJson<double?>(minQuantity),
      'maxQuantity': serializer.toJson<double?>(maxQuantity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EstoqueData copyWith(
          {int? id,
          String? productName,
          String? productType,
          double? currentQuantity,
          String? unit,
          Value<double?> minQuantity = const Value.absent(),
          Value<double?> maxQuantity = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      EstoqueData(
        id: id ?? this.id,
        productName: productName ?? this.productName,
        productType: productType ?? this.productType,
        currentQuantity: currentQuantity ?? this.currentQuantity,
        unit: unit ?? this.unit,
        minQuantity: minQuantity.present ? minQuantity.value : this.minQuantity,
        maxQuantity: maxQuantity.present ? maxQuantity.value : this.maxQuantity,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EstoqueData copyWithCompanion(EstoqueCompanion data) {
    return EstoqueData(
      id: data.id.present ? data.id.value : this.id,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      productType:
          data.productType.present ? data.productType.value : this.productType,
      currentQuantity: data.currentQuantity.present
          ? data.currentQuantity.value
          : this.currentQuantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      minQuantity:
          data.minQuantity.present ? data.minQuantity.value : this.minQuantity,
      maxQuantity:
          data.maxQuantity.present ? data.maxQuantity.value : this.maxQuantity,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstoqueData(')
          ..write('id: $id, ')
          ..write('productName: $productName, ')
          ..write('productType: $productType, ')
          ..write('currentQuantity: $currentQuantity, ')
          ..write('unit: $unit, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('maxQuantity: $maxQuantity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productName, productType, currentQuantity,
      unit, minQuantity, maxQuantity, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstoqueData &&
          other.id == this.id &&
          other.productName == this.productName &&
          other.productType == this.productType &&
          other.currentQuantity == this.currentQuantity &&
          other.unit == this.unit &&
          other.minQuantity == this.minQuantity &&
          other.maxQuantity == this.maxQuantity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EstoqueCompanion extends UpdateCompanion<EstoqueData> {
  final Value<int> id;
  final Value<String> productName;
  final Value<String> productType;
  final Value<double> currentQuantity;
  final Value<String> unit;
  final Value<double?> minQuantity;
  final Value<double?> maxQuantity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const EstoqueCompanion({
    this.id = const Value.absent(),
    this.productName = const Value.absent(),
    this.productType = const Value.absent(),
    this.currentQuantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.minQuantity = const Value.absent(),
    this.maxQuantity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  EstoqueCompanion.insert({
    this.id = const Value.absent(),
    required String productName,
    required String productType,
    required double currentQuantity,
    required String unit,
    this.minQuantity = const Value.absent(),
    this.maxQuantity = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : productName = Value(productName),
        productType = Value(productType),
        currentQuantity = Value(currentQuantity),
        unit = Value(unit),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<EstoqueData> custom({
    Expression<int>? id,
    Expression<String>? productName,
    Expression<String>? productType,
    Expression<double>? currentQuantity,
    Expression<String>? unit,
    Expression<double>? minQuantity,
    Expression<double>? maxQuantity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productName != null) 'product_name': productName,
      if (productType != null) 'product_type': productType,
      if (currentQuantity != null) 'current_quantity': currentQuantity,
      if (unit != null) 'unit': unit,
      if (minQuantity != null) 'min_quantity': minQuantity,
      if (maxQuantity != null) 'max_quantity': maxQuantity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  EstoqueCompanion copyWith(
      {Value<int>? id,
      Value<String>? productName,
      Value<String>? productType,
      Value<double>? currentQuantity,
      Value<String>? unit,
      Value<double?>? minQuantity,
      Value<double?>? maxQuantity,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return EstoqueCompanion(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      productType: productType ?? this.productType,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      unit: unit ?? this.unit,
      minQuantity: minQuantity ?? this.minQuantity,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (productType.present) {
      map['product_type'] = Variable<String>(productType.value);
    }
    if (currentQuantity.present) {
      map['current_quantity'] = Variable<double>(currentQuantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (minQuantity.present) {
      map['min_quantity'] = Variable<double>(minQuantity.value);
    }
    if (maxQuantity.present) {
      map['max_quantity'] = Variable<double>(maxQuantity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstoqueCompanion(')
          ..write('id: $id, ')
          ..write('productName: $productName, ')
          ..write('productType: $productType, ')
          ..write('currentQuantity: $currentQuantity, ')
          ..write('unit: $unit, ')
          ..write('minQuantity: $minQuantity, ')
          ..write('maxQuantity: $maxQuantity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _stockIdMeta =
      const VerificationMeta('stockId');
  @override
  late final GeneratedColumn<int> stockId = GeneratedColumn<int>(
      'stock_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitCostMeta =
      const VerificationMeta('unitCost');
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
      'unit_cost', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _supplierMeta =
      const VerificationMeta('supplier');
  @override
  late final GeneratedColumn<String> supplier = GeneratedColumn<String>(
      'supplier', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _batchNumberMeta =
      const VerificationMeta('batchNumber');
  @override
  late final GeneratedColumn<String> batchNumber = GeneratedColumn<String>(
      'batch_number', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _expiryDateMeta =
      const VerificationMeta('expiryDate');
  @override
  late final GeneratedColumn<String> expiryDate = GeneratedColumn<String>(
      'expiry_date', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        stockId,
        quantity,
        unitCost,
        supplier,
        batchNumber,
        expiryDate,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stock_id')) {
      context.handle(_stockIdMeta,
          stockId.isAcceptableOrUnknown(data['stock_id']!, _stockIdMeta));
    } else if (isInserting) {
      context.missing(_stockIdMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(_unitCostMeta,
          unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta));
    }
    if (data.containsKey('supplier')) {
      context.handle(_supplierMeta,
          supplier.isAcceptableOrUnknown(data['supplier']!, _supplierMeta));
    }
    if (data.containsKey('batch_number')) {
      context.handle(
          _batchNumberMeta,
          batchNumber.isAcceptableOrUnknown(
              data['batch_number']!, _batchNumberMeta));
    }
    if (data.containsKey('expiry_date')) {
      context.handle(
          _expiryDateMeta,
          expiryDate.isAcceptableOrUnknown(
              data['expiry_date']!, _expiryDateMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      stockId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_id'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_cost']),
      supplier: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}supplier']),
      batchNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}batch_number']),
      expiryDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}expiry_date']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final int id;
  final int stockId;
  final double quantity;
  final double? unitCost;
  final String? supplier;
  final String? batchNumber;
  final String? expiryDate;
  final String? notes;
  final DateTime createdAt;
  const InventoryItem(
      {required this.id,
      required this.stockId,
      required this.quantity,
      this.unitCost,
      this.supplier,
      this.batchNumber,
      this.expiryDate,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stock_id'] = Variable<int>(stockId);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unitCost != null) {
      map['unit_cost'] = Variable<double>(unitCost);
    }
    if (!nullToAbsent || supplier != null) {
      map['supplier'] = Variable<String>(supplier);
    }
    if (!nullToAbsent || batchNumber != null) {
      map['batch_number'] = Variable<String>(batchNumber);
    }
    if (!nullToAbsent || expiryDate != null) {
      map['expiry_date'] = Variable<String>(expiryDate);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      stockId: Value(stockId),
      quantity: Value(quantity),
      unitCost: unitCost == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCost),
      supplier: supplier == null && nullToAbsent
          ? const Value.absent()
          : Value(supplier),
      batchNumber: batchNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(batchNumber),
      expiryDate: expiryDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expiryDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<int>(json['id']),
      stockId: serializer.fromJson<int>(json['stockId']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double?>(json['unitCost']),
      supplier: serializer.fromJson<String?>(json['supplier']),
      batchNumber: serializer.fromJson<String?>(json['batchNumber']),
      expiryDate: serializer.fromJson<String?>(json['expiryDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stockId': serializer.toJson<int>(stockId),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double?>(unitCost),
      'supplier': serializer.toJson<String?>(supplier),
      'batchNumber': serializer.toJson<String?>(batchNumber),
      'expiryDate': serializer.toJson<String?>(expiryDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InventoryItem copyWith(
          {int? id,
          int? stockId,
          double? quantity,
          Value<double?> unitCost = const Value.absent(),
          Value<String?> supplier = const Value.absent(),
          Value<String?> batchNumber = const Value.absent(),
          Value<String?> expiryDate = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      InventoryItem(
        id: id ?? this.id,
        stockId: stockId ?? this.stockId,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost.present ? unitCost.value : this.unitCost,
        supplier: supplier.present ? supplier.value : this.supplier,
        batchNumber: batchNumber.present ? batchNumber.value : this.batchNumber,
        expiryDate: expiryDate.present ? expiryDate.value : this.expiryDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      stockId: data.stockId.present ? data.stockId.value : this.stockId,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      supplier: data.supplier.present ? data.supplier.value : this.supplier,
      batchNumber:
          data.batchNumber.present ? data.batchNumber.value : this.batchNumber,
      expiryDate:
          data.expiryDate.present ? data.expiryDate.value : this.expiryDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('stockId: $stockId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('supplier: $supplier, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stockId, quantity, unitCost, supplier,
      batchNumber, expiryDate, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.stockId == this.stockId &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost &&
          other.supplier == this.supplier &&
          other.batchNumber == this.batchNumber &&
          other.expiryDate == this.expiryDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<int> id;
  final Value<int> stockId;
  final Value<double> quantity;
  final Value<double?> unitCost;
  final Value<String?> supplier;
  final Value<String?> batchNumber;
  final Value<String?> expiryDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.stockId = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.supplier = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    this.id = const Value.absent(),
    required int stockId,
    required double quantity,
    this.unitCost = const Value.absent(),
    this.supplier = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.expiryDate = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : stockId = Value(stockId),
        quantity = Value(quantity),
        createdAt = Value(createdAt);
  static Insertable<InventoryItem> custom({
    Expression<int>? id,
    Expression<int>? stockId,
    Expression<double>? quantity,
    Expression<double>? unitCost,
    Expression<String>? supplier,
    Expression<String>? batchNumber,
    Expression<String>? expiryDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stockId != null) 'stock_id': stockId,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (supplier != null) 'supplier': supplier,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (expiryDate != null) 'expiry_date': expiryDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InventoryItemsCompanion copyWith(
      {Value<int>? id,
      Value<int>? stockId,
      Value<double>? quantity,
      Value<double?>? unitCost,
      Value<String?>? supplier,
      Value<String?>? batchNumber,
      Value<String?>? expiryDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      supplier: supplier ?? this.supplier,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stockId.present) {
      map['stock_id'] = Variable<int>(stockId.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (supplier.present) {
      map['supplier'] = Variable<String>(supplier.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<String>(batchNumber.value);
    }
    if (expiryDate.present) {
      map['expiry_date'] = Variable<String>(expiryDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('stockId: $stockId, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('supplier: $supplier, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('expiryDate: $expiryDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InventoryMovementsTable extends InventoryMovements
    with TableInfo<$InventoryMovementsTable, InventoryMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _stockIdMeta =
      const VerificationMeta('stockId');
  @override
  late final GeneratedColumn<int> stockId = GeneratedColumn<int>(
      'stock_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _movementTypeMeta =
      const VerificationMeta('movementType');
  @override
  late final GeneratedColumn<String> movementType = GeneratedColumn<String>(
      'movement_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitCostMeta =
      const VerificationMeta('unitCost');
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
      'unit_cost', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _referenceMeta =
      const VerificationMeta('reference');
  @override
  late final GeneratedColumn<String> reference = GeneratedColumn<String>(
      'reference', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        stockId,
        movementType,
        quantity,
        unitCost,
        reference,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_movements';
  @override
  VerificationContext validateIntegrity(Insertable<InventoryMovement> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('stock_id')) {
      context.handle(_stockIdMeta,
          stockId.isAcceptableOrUnknown(data['stock_id']!, _stockIdMeta));
    } else if (isInserting) {
      context.missing(_stockIdMeta);
    }
    if (data.containsKey('movement_type')) {
      context.handle(
          _movementTypeMeta,
          movementType.isAcceptableOrUnknown(
              data['movement_type']!, _movementTypeMeta));
    } else if (isInserting) {
      context.missing(_movementTypeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(_unitCostMeta,
          unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta));
    }
    if (data.containsKey('reference')) {
      context.handle(_referenceMeta,
          reference.isAcceptableOrUnknown(data['reference']!, _referenceMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryMovement(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      stockId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}stock_id'])!,
      movementType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}movement_type'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_cost']),
      reference: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reference']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $InventoryMovementsTable createAlias(String alias) {
    return $InventoryMovementsTable(attachedDatabase, alias);
  }
}

class InventoryMovement extends DataClass
    implements Insertable<InventoryMovement> {
  final int id;
  final int stockId;
  final String movementType;
  final double quantity;
  final double? unitCost;
  final String? reference;
  final String? notes;
  final DateTime createdAt;
  const InventoryMovement(
      {required this.id,
      required this.stockId,
      required this.movementType,
      required this.quantity,
      this.unitCost,
      this.reference,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['stock_id'] = Variable<int>(stockId);
    map['movement_type'] = Variable<String>(movementType);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || unitCost != null) {
      map['unit_cost'] = Variable<double>(unitCost);
    }
    if (!nullToAbsent || reference != null) {
      map['reference'] = Variable<String>(reference);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  InventoryMovementsCompanion toCompanion(bool nullToAbsent) {
    return InventoryMovementsCompanion(
      id: Value(id),
      stockId: Value(stockId),
      movementType: Value(movementType),
      quantity: Value(quantity),
      unitCost: unitCost == null && nullToAbsent
          ? const Value.absent()
          : Value(unitCost),
      reference: reference == null && nullToAbsent
          ? const Value.absent()
          : Value(reference),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory InventoryMovement.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryMovement(
      id: serializer.fromJson<int>(json['id']),
      stockId: serializer.fromJson<int>(json['stockId']),
      movementType: serializer.fromJson<String>(json['movementType']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double?>(json['unitCost']),
      reference: serializer.fromJson<String?>(json['reference']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'stockId': serializer.toJson<int>(stockId),
      'movementType': serializer.toJson<String>(movementType),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double?>(unitCost),
      'reference': serializer.toJson<String?>(reference),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  InventoryMovement copyWith(
          {int? id,
          int? stockId,
          String? movementType,
          double? quantity,
          Value<double?> unitCost = const Value.absent(),
          Value<String?> reference = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      InventoryMovement(
        id: id ?? this.id,
        stockId: stockId ?? this.stockId,
        movementType: movementType ?? this.movementType,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost.present ? unitCost.value : this.unitCost,
        reference: reference.present ? reference.value : this.reference,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  InventoryMovement copyWithCompanion(InventoryMovementsCompanion data) {
    return InventoryMovement(
      id: data.id.present ? data.id.value : this.id,
      stockId: data.stockId.present ? data.stockId.value : this.stockId,
      movementType: data.movementType.present
          ? data.movementType.value
          : this.movementType,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
      reference: data.reference.present ? data.reference.value : this.reference,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovement(')
          ..write('id: $id, ')
          ..write('stockId: $stockId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, stockId, movementType, quantity, unitCost,
      reference, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryMovement &&
          other.id == this.id &&
          other.stockId == this.stockId &&
          other.movementType == this.movementType &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost &&
          other.reference == this.reference &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class InventoryMovementsCompanion extends UpdateCompanion<InventoryMovement> {
  final Value<int> id;
  final Value<int> stockId;
  final Value<String> movementType;
  final Value<double> quantity;
  final Value<double?> unitCost;
  final Value<String?> reference;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const InventoryMovementsCompanion({
    this.id = const Value.absent(),
    this.stockId = const Value.absent(),
    this.movementType = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  InventoryMovementsCompanion.insert({
    this.id = const Value.absent(),
    required int stockId,
    required String movementType,
    required double quantity,
    this.unitCost = const Value.absent(),
    this.reference = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : stockId = Value(stockId),
        movementType = Value(movementType),
        quantity = Value(quantity),
        createdAt = Value(createdAt);
  static Insertable<InventoryMovement> custom({
    Expression<int>? id,
    Expression<int>? stockId,
    Expression<String>? movementType,
    Expression<double>? quantity,
    Expression<double>? unitCost,
    Expression<String>? reference,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (stockId != null) 'stock_id': stockId,
      if (movementType != null) 'movement_type': movementType,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (reference != null) 'reference': reference,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  InventoryMovementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? stockId,
      Value<String>? movementType,
      Value<double>? quantity,
      Value<double?>? unitCost,
      Value<String?>? reference,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return InventoryMovementsCompanion(
      id: id ?? this.id,
      stockId: stockId ?? this.stockId,
      movementType: movementType ?? this.movementType,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      reference: reference ?? this.reference,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (stockId.present) {
      map['stock_id'] = Variable<int>(stockId.value);
    }
    if (movementType.present) {
      map['movement_type'] = Variable<String>(movementType.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (reference.present) {
      map['reference'] = Variable<String>(reference.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryMovementsCompanion(')
          ..write('id: $id, ')
          ..write('stockId: $stockId, ')
          ..write('movementType: $movementType, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('reference: $reference, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $SoilAnalysisTable extends SoilAnalysis
    with TableInfo<$SoilAnalysisTable, SoilAnalysi> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoilAnalysisTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _analysisDateMeta =
      const VerificationMeta('analysisDate');
  @override
  late final GeneratedColumn<String> analysisDate = GeneratedColumn<String>(
      'analysis_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phLevelMeta =
      const VerificationMeta('phLevel');
  @override
  late final GeneratedColumn<double> phLevel = GeneratedColumn<double>(
      'ph_level', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _organicMatterMeta =
      const VerificationMeta('organicMatter');
  @override
  late final GeneratedColumn<double> organicMatter = GeneratedColumn<double>(
      'organic_matter', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _phosphorusMeta =
      const VerificationMeta('phosphorus');
  @override
  late final GeneratedColumn<double> phosphorus = GeneratedColumn<double>(
      'phosphorus', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _potassiumMeta =
      const VerificationMeta('potassium');
  @override
  late final GeneratedColumn<double> potassium = GeneratedColumn<double>(
      'potassium', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _calciumMeta =
      const VerificationMeta('calcium');
  @override
  late final GeneratedColumn<double> calcium = GeneratedColumn<double>(
      'calcium', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _magnesiumMeta =
      const VerificationMeta('magnesium');
  @override
  late final GeneratedColumn<double> magnesium = GeneratedColumn<double>(
      'magnesium', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _sulfurMeta = const VerificationMeta('sulfur');
  @override
  late final GeneratedColumn<double> sulfur = GeneratedColumn<double>(
      'sulfur', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _boronMeta = const VerificationMeta('boron');
  @override
  late final GeneratedColumn<double> boron = GeneratedColumn<double>(
      'boron', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _copperMeta = const VerificationMeta('copper');
  @override
  late final GeneratedColumn<double> copper = GeneratedColumn<double>(
      'copper', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _ironMeta = const VerificationMeta('iron');
  @override
  late final GeneratedColumn<double> iron = GeneratedColumn<double>(
      'iron', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _manganeseMeta =
      const VerificationMeta('manganese');
  @override
  late final GeneratedColumn<double> manganese = GeneratedColumn<double>(
      'manganese', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _zincMeta = const VerificationMeta('zinc');
  @override
  late final GeneratedColumn<double> zinc = GeneratedColumn<double>(
      'zinc', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        analysisDate,
        phLevel,
        organicMatter,
        phosphorus,
        potassium,
        calcium,
        magnesium,
        sulfur,
        boron,
        copper,
        iron,
        manganese,
        zinc,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soil_analysis';
  @override
  VerificationContext validateIntegrity(Insertable<SoilAnalysi> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('analysis_date')) {
      context.handle(
          _analysisDateMeta,
          analysisDate.isAcceptableOrUnknown(
              data['analysis_date']!, _analysisDateMeta));
    } else if (isInserting) {
      context.missing(_analysisDateMeta);
    }
    if (data.containsKey('ph_level')) {
      context.handle(_phLevelMeta,
          phLevel.isAcceptableOrUnknown(data['ph_level']!, _phLevelMeta));
    }
    if (data.containsKey('organic_matter')) {
      context.handle(
          _organicMatterMeta,
          organicMatter.isAcceptableOrUnknown(
              data['organic_matter']!, _organicMatterMeta));
    }
    if (data.containsKey('phosphorus')) {
      context.handle(
          _phosphorusMeta,
          phosphorus.isAcceptableOrUnknown(
              data['phosphorus']!, _phosphorusMeta));
    }
    if (data.containsKey('potassium')) {
      context.handle(_potassiumMeta,
          potassium.isAcceptableOrUnknown(data['potassium']!, _potassiumMeta));
    }
    if (data.containsKey('calcium')) {
      context.handle(_calciumMeta,
          calcium.isAcceptableOrUnknown(data['calcium']!, _calciumMeta));
    }
    if (data.containsKey('magnesium')) {
      context.handle(_magnesiumMeta,
          magnesium.isAcceptableOrUnknown(data['magnesium']!, _magnesiumMeta));
    }
    if (data.containsKey('sulfur')) {
      context.handle(_sulfurMeta,
          sulfur.isAcceptableOrUnknown(data['sulfur']!, _sulfurMeta));
    }
    if (data.containsKey('boron')) {
      context.handle(
          _boronMeta, boron.isAcceptableOrUnknown(data['boron']!, _boronMeta));
    }
    if (data.containsKey('copper')) {
      context.handle(_copperMeta,
          copper.isAcceptableOrUnknown(data['copper']!, _copperMeta));
    }
    if (data.containsKey('iron')) {
      context.handle(
          _ironMeta, iron.isAcceptableOrUnknown(data['iron']!, _ironMeta));
    }
    if (data.containsKey('manganese')) {
      context.handle(_manganeseMeta,
          manganese.isAcceptableOrUnknown(data['manganese']!, _manganeseMeta));
    }
    if (data.containsKey('zinc')) {
      context.handle(
          _zincMeta, zinc.isAcceptableOrUnknown(data['zinc']!, _zincMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SoilAnalysi map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoilAnalysi(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      analysisDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}analysis_date'])!,
      phLevel: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}ph_level']),
      organicMatter: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}organic_matter']),
      phosphorus: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}phosphorus']),
      potassium: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}potassium']),
      calcium: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}calcium']),
      magnesium: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}magnesium']),
      sulfur: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sulfur']),
      boron: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}boron']),
      copper: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}copper']),
      iron: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}iron']),
      manganese: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}manganese']),
      zinc: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}zinc']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SoilAnalysisTable createAlias(String alias) {
    return $SoilAnalysisTable(attachedDatabase, alias);
  }
}

class SoilAnalysi extends DataClass implements Insertable<SoilAnalysi> {
  final int id;
  final int plotId;
  final String analysisDate;
  final double? phLevel;
  final double? organicMatter;
  final double? phosphorus;
  final double? potassium;
  final double? calcium;
  final double? magnesium;
  final double? sulfur;
  final double? boron;
  final double? copper;
  final double? iron;
  final double? manganese;
  final double? zinc;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const SoilAnalysi(
      {required this.id,
      required this.plotId,
      required this.analysisDate,
      this.phLevel,
      this.organicMatter,
      this.phosphorus,
      this.potassium,
      this.calcium,
      this.magnesium,
      this.sulfur,
      this.boron,
      this.copper,
      this.iron,
      this.manganese,
      this.zinc,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['analysis_date'] = Variable<String>(analysisDate);
    if (!nullToAbsent || phLevel != null) {
      map['ph_level'] = Variable<double>(phLevel);
    }
    if (!nullToAbsent || organicMatter != null) {
      map['organic_matter'] = Variable<double>(organicMatter);
    }
    if (!nullToAbsent || phosphorus != null) {
      map['phosphorus'] = Variable<double>(phosphorus);
    }
    if (!nullToAbsent || potassium != null) {
      map['potassium'] = Variable<double>(potassium);
    }
    if (!nullToAbsent || calcium != null) {
      map['calcium'] = Variable<double>(calcium);
    }
    if (!nullToAbsent || magnesium != null) {
      map['magnesium'] = Variable<double>(magnesium);
    }
    if (!nullToAbsent || sulfur != null) {
      map['sulfur'] = Variable<double>(sulfur);
    }
    if (!nullToAbsent || boron != null) {
      map['boron'] = Variable<double>(boron);
    }
    if (!nullToAbsent || copper != null) {
      map['copper'] = Variable<double>(copper);
    }
    if (!nullToAbsent || iron != null) {
      map['iron'] = Variable<double>(iron);
    }
    if (!nullToAbsent || manganese != null) {
      map['manganese'] = Variable<double>(manganese);
    }
    if (!nullToAbsent || zinc != null) {
      map['zinc'] = Variable<double>(zinc);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SoilAnalysisCompanion toCompanion(bool nullToAbsent) {
    return SoilAnalysisCompanion(
      id: Value(id),
      plotId: Value(plotId),
      analysisDate: Value(analysisDate),
      phLevel: phLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(phLevel),
      organicMatter: organicMatter == null && nullToAbsent
          ? const Value.absent()
          : Value(organicMatter),
      phosphorus: phosphorus == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorus),
      potassium: potassium == null && nullToAbsent
          ? const Value.absent()
          : Value(potassium),
      calcium: calcium == null && nullToAbsent
          ? const Value.absent()
          : Value(calcium),
      magnesium: magnesium == null && nullToAbsent
          ? const Value.absent()
          : Value(magnesium),
      sulfur:
          sulfur == null && nullToAbsent ? const Value.absent() : Value(sulfur),
      boron:
          boron == null && nullToAbsent ? const Value.absent() : Value(boron),
      copper:
          copper == null && nullToAbsent ? const Value.absent() : Value(copper),
      iron: iron == null && nullToAbsent ? const Value.absent() : Value(iron),
      manganese: manganese == null && nullToAbsent
          ? const Value.absent()
          : Value(manganese),
      zinc: zinc == null && nullToAbsent ? const Value.absent() : Value(zinc),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SoilAnalysi.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoilAnalysi(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      analysisDate: serializer.fromJson<String>(json['analysisDate']),
      phLevel: serializer.fromJson<double?>(json['phLevel']),
      organicMatter: serializer.fromJson<double?>(json['organicMatter']),
      phosphorus: serializer.fromJson<double?>(json['phosphorus']),
      potassium: serializer.fromJson<double?>(json['potassium']),
      calcium: serializer.fromJson<double?>(json['calcium']),
      magnesium: serializer.fromJson<double?>(json['magnesium']),
      sulfur: serializer.fromJson<double?>(json['sulfur']),
      boron: serializer.fromJson<double?>(json['boron']),
      copper: serializer.fromJson<double?>(json['copper']),
      iron: serializer.fromJson<double?>(json['iron']),
      manganese: serializer.fromJson<double?>(json['manganese']),
      zinc: serializer.fromJson<double?>(json['zinc']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'analysisDate': serializer.toJson<String>(analysisDate),
      'phLevel': serializer.toJson<double?>(phLevel),
      'organicMatter': serializer.toJson<double?>(organicMatter),
      'phosphorus': serializer.toJson<double?>(phosphorus),
      'potassium': serializer.toJson<double?>(potassium),
      'calcium': serializer.toJson<double?>(calcium),
      'magnesium': serializer.toJson<double?>(magnesium),
      'sulfur': serializer.toJson<double?>(sulfur),
      'boron': serializer.toJson<double?>(boron),
      'copper': serializer.toJson<double?>(copper),
      'iron': serializer.toJson<double?>(iron),
      'manganese': serializer.toJson<double?>(manganese),
      'zinc': serializer.toJson<double?>(zinc),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SoilAnalysi copyWith(
          {int? id,
          int? plotId,
          String? analysisDate,
          Value<double?> phLevel = const Value.absent(),
          Value<double?> organicMatter = const Value.absent(),
          Value<double?> phosphorus = const Value.absent(),
          Value<double?> potassium = const Value.absent(),
          Value<double?> calcium = const Value.absent(),
          Value<double?> magnesium = const Value.absent(),
          Value<double?> sulfur = const Value.absent(),
          Value<double?> boron = const Value.absent(),
          Value<double?> copper = const Value.absent(),
          Value<double?> iron = const Value.absent(),
          Value<double?> manganese = const Value.absent(),
          Value<double?> zinc = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      SoilAnalysi(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        analysisDate: analysisDate ?? this.analysisDate,
        phLevel: phLevel.present ? phLevel.value : this.phLevel,
        organicMatter:
            organicMatter.present ? organicMatter.value : this.organicMatter,
        phosphorus: phosphorus.present ? phosphorus.value : this.phosphorus,
        potassium: potassium.present ? potassium.value : this.potassium,
        calcium: calcium.present ? calcium.value : this.calcium,
        magnesium: magnesium.present ? magnesium.value : this.magnesium,
        sulfur: sulfur.present ? sulfur.value : this.sulfur,
        boron: boron.present ? boron.value : this.boron,
        copper: copper.present ? copper.value : this.copper,
        iron: iron.present ? iron.value : this.iron,
        manganese: manganese.present ? manganese.value : this.manganese,
        zinc: zinc.present ? zinc.value : this.zinc,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SoilAnalysi copyWithCompanion(SoilAnalysisCompanion data) {
    return SoilAnalysi(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      analysisDate: data.analysisDate.present
          ? data.analysisDate.value
          : this.analysisDate,
      phLevel: data.phLevel.present ? data.phLevel.value : this.phLevel,
      organicMatter: data.organicMatter.present
          ? data.organicMatter.value
          : this.organicMatter,
      phosphorus:
          data.phosphorus.present ? data.phosphorus.value : this.phosphorus,
      potassium: data.potassium.present ? data.potassium.value : this.potassium,
      calcium: data.calcium.present ? data.calcium.value : this.calcium,
      magnesium: data.magnesium.present ? data.magnesium.value : this.magnesium,
      sulfur: data.sulfur.present ? data.sulfur.value : this.sulfur,
      boron: data.boron.present ? data.boron.value : this.boron,
      copper: data.copper.present ? data.copper.value : this.copper,
      iron: data.iron.present ? data.iron.value : this.iron,
      manganese: data.manganese.present ? data.manganese.value : this.manganese,
      zinc: data.zinc.present ? data.zinc.value : this.zinc,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoilAnalysi(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('analysisDate: $analysisDate, ')
          ..write('phLevel: $phLevel, ')
          ..write('organicMatter: $organicMatter, ')
          ..write('phosphorus: $phosphorus, ')
          ..write('potassium: $potassium, ')
          ..write('calcium: $calcium, ')
          ..write('magnesium: $magnesium, ')
          ..write('sulfur: $sulfur, ')
          ..write('boron: $boron, ')
          ..write('copper: $copper, ')
          ..write('iron: $iron, ')
          ..write('manganese: $manganese, ')
          ..write('zinc: $zinc, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plotId,
      analysisDate,
      phLevel,
      organicMatter,
      phosphorus,
      potassium,
      calcium,
      magnesium,
      sulfur,
      boron,
      copper,
      iron,
      manganese,
      zinc,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoilAnalysi &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.analysisDate == this.analysisDate &&
          other.phLevel == this.phLevel &&
          other.organicMatter == this.organicMatter &&
          other.phosphorus == this.phosphorus &&
          other.potassium == this.potassium &&
          other.calcium == this.calcium &&
          other.magnesium == this.magnesium &&
          other.sulfur == this.sulfur &&
          other.boron == this.boron &&
          other.copper == this.copper &&
          other.iron == this.iron &&
          other.manganese == this.manganese &&
          other.zinc == this.zinc &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SoilAnalysisCompanion extends UpdateCompanion<SoilAnalysi> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<String> analysisDate;
  final Value<double?> phLevel;
  final Value<double?> organicMatter;
  final Value<double?> phosphorus;
  final Value<double?> potassium;
  final Value<double?> calcium;
  final Value<double?> magnesium;
  final Value<double?> sulfur;
  final Value<double?> boron;
  final Value<double?> copper;
  final Value<double?> iron;
  final Value<double?> manganese;
  final Value<double?> zinc;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const SoilAnalysisCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.analysisDate = const Value.absent(),
    this.phLevel = const Value.absent(),
    this.organicMatter = const Value.absent(),
    this.phosphorus = const Value.absent(),
    this.potassium = const Value.absent(),
    this.calcium = const Value.absent(),
    this.magnesium = const Value.absent(),
    this.sulfur = const Value.absent(),
    this.boron = const Value.absent(),
    this.copper = const Value.absent(),
    this.iron = const Value.absent(),
    this.manganese = const Value.absent(),
    this.zinc = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SoilAnalysisCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required String analysisDate,
    this.phLevel = const Value.absent(),
    this.organicMatter = const Value.absent(),
    this.phosphorus = const Value.absent(),
    this.potassium = const Value.absent(),
    this.calcium = const Value.absent(),
    this.magnesium = const Value.absent(),
    this.sulfur = const Value.absent(),
    this.boron = const Value.absent(),
    this.copper = const Value.absent(),
    this.iron = const Value.absent(),
    this.manganese = const Value.absent(),
    this.zinc = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : plotId = Value(plotId),
        analysisDate = Value(analysisDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<SoilAnalysi> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? analysisDate,
    Expression<double>? phLevel,
    Expression<double>? organicMatter,
    Expression<double>? phosphorus,
    Expression<double>? potassium,
    Expression<double>? calcium,
    Expression<double>? magnesium,
    Expression<double>? sulfur,
    Expression<double>? boron,
    Expression<double>? copper,
    Expression<double>? iron,
    Expression<double>? manganese,
    Expression<double>? zinc,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (analysisDate != null) 'analysis_date': analysisDate,
      if (phLevel != null) 'ph_level': phLevel,
      if (organicMatter != null) 'organic_matter': organicMatter,
      if (phosphorus != null) 'phosphorus': phosphorus,
      if (potassium != null) 'potassium': potassium,
      if (calcium != null) 'calcium': calcium,
      if (magnesium != null) 'magnesium': magnesium,
      if (sulfur != null) 'sulfur': sulfur,
      if (boron != null) 'boron': boron,
      if (copper != null) 'copper': copper,
      if (iron != null) 'iron': iron,
      if (manganese != null) 'manganese': manganese,
      if (zinc != null) 'zinc': zinc,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SoilAnalysisCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<String>? analysisDate,
      Value<double?>? phLevel,
      Value<double?>? organicMatter,
      Value<double?>? phosphorus,
      Value<double?>? potassium,
      Value<double?>? calcium,
      Value<double?>? magnesium,
      Value<double?>? sulfur,
      Value<double?>? boron,
      Value<double?>? copper,
      Value<double?>? iron,
      Value<double?>? manganese,
      Value<double?>? zinc,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return SoilAnalysisCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      analysisDate: analysisDate ?? this.analysisDate,
      phLevel: phLevel ?? this.phLevel,
      organicMatter: organicMatter ?? this.organicMatter,
      phosphorus: phosphorus ?? this.phosphorus,
      potassium: potassium ?? this.potassium,
      calcium: calcium ?? this.calcium,
      magnesium: magnesium ?? this.magnesium,
      sulfur: sulfur ?? this.sulfur,
      boron: boron ?? this.boron,
      copper: copper ?? this.copper,
      iron: iron ?? this.iron,
      manganese: manganese ?? this.manganese,
      zinc: zinc ?? this.zinc,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (analysisDate.present) {
      map['analysis_date'] = Variable<String>(analysisDate.value);
    }
    if (phLevel.present) {
      map['ph_level'] = Variable<double>(phLevel.value);
    }
    if (organicMatter.present) {
      map['organic_matter'] = Variable<double>(organicMatter.value);
    }
    if (phosphorus.present) {
      map['phosphorus'] = Variable<double>(phosphorus.value);
    }
    if (potassium.present) {
      map['potassium'] = Variable<double>(potassium.value);
    }
    if (calcium.present) {
      map['calcium'] = Variable<double>(calcium.value);
    }
    if (magnesium.present) {
      map['magnesium'] = Variable<double>(magnesium.value);
    }
    if (sulfur.present) {
      map['sulfur'] = Variable<double>(sulfur.value);
    }
    if (boron.present) {
      map['boron'] = Variable<double>(boron.value);
    }
    if (copper.present) {
      map['copper'] = Variable<double>(copper.value);
    }
    if (iron.present) {
      map['iron'] = Variable<double>(iron.value);
    }
    if (manganese.present) {
      map['manganese'] = Variable<double>(manganese.value);
    }
    if (zinc.present) {
      map['zinc'] = Variable<double>(zinc.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoilAnalysisCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('analysisDate: $analysisDate, ')
          ..write('phLevel: $phLevel, ')
          ..write('organicMatter: $organicMatter, ')
          ..write('phosphorus: $phosphorus, ')
          ..write('potassium: $potassium, ')
          ..write('calcium: $calcium, ')
          ..write('magnesium: $magnesium, ')
          ..write('sulfur: $sulfur, ')
          ..write('boron: $boron, ')
          ..write('copper: $copper, ')
          ..write('iron: $iron, ')
          ..write('manganese: $manganese, ')
          ..write('zinc: $zinc, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SoilSamplesTable extends SoilSamples
    with TableInfo<$SoilSamplesTable, SoilSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SoilSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _analysisIdMeta =
      const VerificationMeta('analysisId');
  @override
  late final GeneratedColumn<int> analysisId = GeneratedColumn<int>(
      'analysis_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _sampleDepthMeta =
      const VerificationMeta('sampleDepth');
  @override
  late final GeneratedColumn<double> sampleDepth = GeneratedColumn<double>(
      'sample_depth', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _sampleLocationMeta =
      const VerificationMeta('sampleLocation');
  @override
  late final GeneratedColumn<String> sampleLocation = GeneratedColumn<String>(
      'sample_location', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sampleDateMeta =
      const VerificationMeta('sampleDate');
  @override
  late final GeneratedColumn<String> sampleDate = GeneratedColumn<String>(
      'sample_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        analysisId,
        sampleDepth,
        sampleLocation,
        sampleDate,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'soil_samples';
  @override
  VerificationContext validateIntegrity(Insertable<SoilSample> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('analysis_id')) {
      context.handle(
          _analysisIdMeta,
          analysisId.isAcceptableOrUnknown(
              data['analysis_id']!, _analysisIdMeta));
    } else if (isInserting) {
      context.missing(_analysisIdMeta);
    }
    if (data.containsKey('sample_depth')) {
      context.handle(
          _sampleDepthMeta,
          sampleDepth.isAcceptableOrUnknown(
              data['sample_depth']!, _sampleDepthMeta));
    } else if (isInserting) {
      context.missing(_sampleDepthMeta);
    }
    if (data.containsKey('sample_location')) {
      context.handle(
          _sampleLocationMeta,
          sampleLocation.isAcceptableOrUnknown(
              data['sample_location']!, _sampleLocationMeta));
    }
    if (data.containsKey('sample_date')) {
      context.handle(
          _sampleDateMeta,
          sampleDate.isAcceptableOrUnknown(
              data['sample_date']!, _sampleDateMeta));
    } else if (isInserting) {
      context.missing(_sampleDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SoilSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SoilSample(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      analysisId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}analysis_id'])!,
      sampleDepth: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sample_depth'])!,
      sampleLocation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sample_location']),
      sampleDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sample_date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SoilSamplesTable createAlias(String alias) {
    return $SoilSamplesTable(attachedDatabase, alias);
  }
}

class SoilSample extends DataClass implements Insertable<SoilSample> {
  final int id;
  final int analysisId;
  final double sampleDepth;
  final String? sampleLocation;
  final String sampleDate;
  final String? notes;
  final DateTime createdAt;
  const SoilSample(
      {required this.id,
      required this.analysisId,
      required this.sampleDepth,
      this.sampleLocation,
      required this.sampleDate,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['analysis_id'] = Variable<int>(analysisId);
    map['sample_depth'] = Variable<double>(sampleDepth);
    if (!nullToAbsent || sampleLocation != null) {
      map['sample_location'] = Variable<String>(sampleLocation);
    }
    map['sample_date'] = Variable<String>(sampleDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SoilSamplesCompanion toCompanion(bool nullToAbsent) {
    return SoilSamplesCompanion(
      id: Value(id),
      analysisId: Value(analysisId),
      sampleDepth: Value(sampleDepth),
      sampleLocation: sampleLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(sampleLocation),
      sampleDate: Value(sampleDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory SoilSample.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SoilSample(
      id: serializer.fromJson<int>(json['id']),
      analysisId: serializer.fromJson<int>(json['analysisId']),
      sampleDepth: serializer.fromJson<double>(json['sampleDepth']),
      sampleLocation: serializer.fromJson<String?>(json['sampleLocation']),
      sampleDate: serializer.fromJson<String>(json['sampleDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'analysisId': serializer.toJson<int>(analysisId),
      'sampleDepth': serializer.toJson<double>(sampleDepth),
      'sampleLocation': serializer.toJson<String?>(sampleLocation),
      'sampleDate': serializer.toJson<String>(sampleDate),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SoilSample copyWith(
          {int? id,
          int? analysisId,
          double? sampleDepth,
          Value<String?> sampleLocation = const Value.absent(),
          String? sampleDate,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      SoilSample(
        id: id ?? this.id,
        analysisId: analysisId ?? this.analysisId,
        sampleDepth: sampleDepth ?? this.sampleDepth,
        sampleLocation:
            sampleLocation.present ? sampleLocation.value : this.sampleLocation,
        sampleDate: sampleDate ?? this.sampleDate,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  SoilSample copyWithCompanion(SoilSamplesCompanion data) {
    return SoilSample(
      id: data.id.present ? data.id.value : this.id,
      analysisId:
          data.analysisId.present ? data.analysisId.value : this.analysisId,
      sampleDepth:
          data.sampleDepth.present ? data.sampleDepth.value : this.sampleDepth,
      sampleLocation: data.sampleLocation.present
          ? data.sampleLocation.value
          : this.sampleLocation,
      sampleDate:
          data.sampleDate.present ? data.sampleDate.value : this.sampleDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SoilSample(')
          ..write('id: $id, ')
          ..write('analysisId: $analysisId, ')
          ..write('sampleDepth: $sampleDepth, ')
          ..write('sampleLocation: $sampleLocation, ')
          ..write('sampleDate: $sampleDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, analysisId, sampleDepth, sampleLocation,
      sampleDate, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SoilSample &&
          other.id == this.id &&
          other.analysisId == this.analysisId &&
          other.sampleDepth == this.sampleDepth &&
          other.sampleLocation == this.sampleLocation &&
          other.sampleDate == this.sampleDate &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class SoilSamplesCompanion extends UpdateCompanion<SoilSample> {
  final Value<int> id;
  final Value<int> analysisId;
  final Value<double> sampleDepth;
  final Value<String?> sampleLocation;
  final Value<String> sampleDate;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const SoilSamplesCompanion({
    this.id = const Value.absent(),
    this.analysisId = const Value.absent(),
    this.sampleDepth = const Value.absent(),
    this.sampleLocation = const Value.absent(),
    this.sampleDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SoilSamplesCompanion.insert({
    this.id = const Value.absent(),
    required int analysisId,
    required double sampleDepth,
    this.sampleLocation = const Value.absent(),
    required String sampleDate,
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : analysisId = Value(analysisId),
        sampleDepth = Value(sampleDepth),
        sampleDate = Value(sampleDate),
        createdAt = Value(createdAt);
  static Insertable<SoilSample> custom({
    Expression<int>? id,
    Expression<int>? analysisId,
    Expression<double>? sampleDepth,
    Expression<String>? sampleLocation,
    Expression<String>? sampleDate,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (analysisId != null) 'analysis_id': analysisId,
      if (sampleDepth != null) 'sample_depth': sampleDepth,
      if (sampleLocation != null) 'sample_location': sampleLocation,
      if (sampleDate != null) 'sample_date': sampleDate,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SoilSamplesCompanion copyWith(
      {Value<int>? id,
      Value<int>? analysisId,
      Value<double>? sampleDepth,
      Value<String?>? sampleLocation,
      Value<String>? sampleDate,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return SoilSamplesCompanion(
      id: id ?? this.id,
      analysisId: analysisId ?? this.analysisId,
      sampleDepth: sampleDepth ?? this.sampleDepth,
      sampleLocation: sampleLocation ?? this.sampleLocation,
      sampleDate: sampleDate ?? this.sampleDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (analysisId.present) {
      map['analysis_id'] = Variable<int>(analysisId.value);
    }
    if (sampleDepth.present) {
      map['sample_depth'] = Variable<double>(sampleDepth.value);
    }
    if (sampleLocation.present) {
      map['sample_location'] = Variable<String>(sampleLocation.value);
    }
    if (sampleDate.present) {
      map['sample_date'] = Variable<String>(sampleDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SoilSamplesCompanion(')
          ..write('id: $id, ')
          ..write('analysisId: $analysisId, ')
          ..write('sampleDepth: $sampleDepth, ')
          ..write('sampleLocation: $sampleLocation, ')
          ..write('sampleDate: $sampleDate, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $GerminationTestsTable extends GerminationTests
    with TableInfo<$GerminationTestsTable, GerminationTest> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GerminationTestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plotIdMeta = const VerificationMeta('plotId');
  @override
  late final GeneratedColumn<int> plotId = GeneratedColumn<int>(
      'plot_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _testDateMeta =
      const VerificationMeta('testDate');
  @override
  late final GeneratedColumn<String> testDate = GeneratedColumn<String>(
      'test_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seedVarietyMeta =
      const VerificationMeta('seedVariety');
  @override
  late final GeneratedColumn<String> seedVariety = GeneratedColumn<String>(
      'seed_variety', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seedBatchMeta =
      const VerificationMeta('seedBatch');
  @override
  late final GeneratedColumn<String> seedBatch = GeneratedColumn<String>(
      'seed_batch', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _testTypeMeta =
      const VerificationMeta('testType');
  @override
  late final GeneratedColumn<String> testType = GeneratedColumn<String>(
      'test_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _initialSeedCountMeta =
      const VerificationMeta('initialSeedCount');
  @override
  late final GeneratedColumn<int> initialSeedCount = GeneratedColumn<int>(
      'initial_seed_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _finalGerminationCountMeta =
      const VerificationMeta('finalGerminationCount');
  @override
  late final GeneratedColumn<int> finalGerminationCount = GeneratedColumn<int>(
      'final_germination_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _germinationPercentageMeta =
      const VerificationMeta('germinationPercentage');
  @override
  late final GeneratedColumn<double> germinationPercentage =
      GeneratedColumn<double>('germination_percentage', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plotId,
        testDate,
        seedVariety,
        seedBatch,
        testType,
        initialSeedCount,
        finalGerminationCount,
        germinationPercentage,
        notes,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'germination_tests';
  @override
  VerificationContext validateIntegrity(Insertable<GerminationTest> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plot_id')) {
      context.handle(_plotIdMeta,
          plotId.isAcceptableOrUnknown(data['plot_id']!, _plotIdMeta));
    } else if (isInserting) {
      context.missing(_plotIdMeta);
    }
    if (data.containsKey('test_date')) {
      context.handle(_testDateMeta,
          testDate.isAcceptableOrUnknown(data['test_date']!, _testDateMeta));
    } else if (isInserting) {
      context.missing(_testDateMeta);
    }
    if (data.containsKey('seed_variety')) {
      context.handle(
          _seedVarietyMeta,
          seedVariety.isAcceptableOrUnknown(
              data['seed_variety']!, _seedVarietyMeta));
    } else if (isInserting) {
      context.missing(_seedVarietyMeta);
    }
    if (data.containsKey('seed_batch')) {
      context.handle(_seedBatchMeta,
          seedBatch.isAcceptableOrUnknown(data['seed_batch']!, _seedBatchMeta));
    }
    if (data.containsKey('test_type')) {
      context.handle(_testTypeMeta,
          testType.isAcceptableOrUnknown(data['test_type']!, _testTypeMeta));
    } else if (isInserting) {
      context.missing(_testTypeMeta);
    }
    if (data.containsKey('initial_seed_count')) {
      context.handle(
          _initialSeedCountMeta,
          initialSeedCount.isAcceptableOrUnknown(
              data['initial_seed_count']!, _initialSeedCountMeta));
    } else if (isInserting) {
      context.missing(_initialSeedCountMeta);
    }
    if (data.containsKey('final_germination_count')) {
      context.handle(
          _finalGerminationCountMeta,
          finalGerminationCount.isAcceptableOrUnknown(
              data['final_germination_count']!, _finalGerminationCountMeta));
    }
    if (data.containsKey('germination_percentage')) {
      context.handle(
          _germinationPercentageMeta,
          germinationPercentage.isAcceptableOrUnknown(
              data['germination_percentage']!, _germinationPercentageMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GerminationTest map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GerminationTest(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plotId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}plot_id'])!,
      testDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}test_date'])!,
      seedVariety: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seed_variety'])!,
      seedBatch: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seed_batch']),
      testType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}test_type'])!,
      initialSeedCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}initial_seed_count'])!,
      finalGerminationCount: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}final_germination_count']),
      germinationPercentage: attachedDatabase.typeMapping.read(
          DriftSqlType.double,
          data['${effectivePrefix}germination_percentage']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $GerminationTestsTable createAlias(String alias) {
    return $GerminationTestsTable(attachedDatabase, alias);
  }
}

class GerminationTest extends DataClass implements Insertable<GerminationTest> {
  final int id;
  final int plotId;
  final String testDate;
  final String seedVariety;
  final String? seedBatch;
  final String testType;
  final int initialSeedCount;
  final int? finalGerminationCount;
  final double? germinationPercentage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GerminationTest(
      {required this.id,
      required this.plotId,
      required this.testDate,
      required this.seedVariety,
      this.seedBatch,
      required this.testType,
      required this.initialSeedCount,
      this.finalGerminationCount,
      this.germinationPercentage,
      this.notes,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plot_id'] = Variable<int>(plotId);
    map['test_date'] = Variable<String>(testDate);
    map['seed_variety'] = Variable<String>(seedVariety);
    if (!nullToAbsent || seedBatch != null) {
      map['seed_batch'] = Variable<String>(seedBatch);
    }
    map['test_type'] = Variable<String>(testType);
    map['initial_seed_count'] = Variable<int>(initialSeedCount);
    if (!nullToAbsent || finalGerminationCount != null) {
      map['final_germination_count'] = Variable<int>(finalGerminationCount);
    }
    if (!nullToAbsent || germinationPercentage != null) {
      map['germination_percentage'] = Variable<double>(germinationPercentage);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GerminationTestsCompanion toCompanion(bool nullToAbsent) {
    return GerminationTestsCompanion(
      id: Value(id),
      plotId: Value(plotId),
      testDate: Value(testDate),
      seedVariety: Value(seedVariety),
      seedBatch: seedBatch == null && nullToAbsent
          ? const Value.absent()
          : Value(seedBatch),
      testType: Value(testType),
      initialSeedCount: Value(initialSeedCount),
      finalGerminationCount: finalGerminationCount == null && nullToAbsent
          ? const Value.absent()
          : Value(finalGerminationCount),
      germinationPercentage: germinationPercentage == null && nullToAbsent
          ? const Value.absent()
          : Value(germinationPercentage),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GerminationTest.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GerminationTest(
      id: serializer.fromJson<int>(json['id']),
      plotId: serializer.fromJson<int>(json['plotId']),
      testDate: serializer.fromJson<String>(json['testDate']),
      seedVariety: serializer.fromJson<String>(json['seedVariety']),
      seedBatch: serializer.fromJson<String?>(json['seedBatch']),
      testType: serializer.fromJson<String>(json['testType']),
      initialSeedCount: serializer.fromJson<int>(json['initialSeedCount']),
      finalGerminationCount:
          serializer.fromJson<int?>(json['finalGerminationCount']),
      germinationPercentage:
          serializer.fromJson<double?>(json['germinationPercentage']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plotId': serializer.toJson<int>(plotId),
      'testDate': serializer.toJson<String>(testDate),
      'seedVariety': serializer.toJson<String>(seedVariety),
      'seedBatch': serializer.toJson<String?>(seedBatch),
      'testType': serializer.toJson<String>(testType),
      'initialSeedCount': serializer.toJson<int>(initialSeedCount),
      'finalGerminationCount': serializer.toJson<int?>(finalGerminationCount),
      'germinationPercentage':
          serializer.toJson<double?>(germinationPercentage),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GerminationTest copyWith(
          {int? id,
          int? plotId,
          String? testDate,
          String? seedVariety,
          Value<String?> seedBatch = const Value.absent(),
          String? testType,
          int? initialSeedCount,
          Value<int?> finalGerminationCount = const Value.absent(),
          Value<double?> germinationPercentage = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      GerminationTest(
        id: id ?? this.id,
        plotId: plotId ?? this.plotId,
        testDate: testDate ?? this.testDate,
        seedVariety: seedVariety ?? this.seedVariety,
        seedBatch: seedBatch.present ? seedBatch.value : this.seedBatch,
        testType: testType ?? this.testType,
        initialSeedCount: initialSeedCount ?? this.initialSeedCount,
        finalGerminationCount: finalGerminationCount.present
            ? finalGerminationCount.value
            : this.finalGerminationCount,
        germinationPercentage: germinationPercentage.present
            ? germinationPercentage.value
            : this.germinationPercentage,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  GerminationTest copyWithCompanion(GerminationTestsCompanion data) {
    return GerminationTest(
      id: data.id.present ? data.id.value : this.id,
      plotId: data.plotId.present ? data.plotId.value : this.plotId,
      testDate: data.testDate.present ? data.testDate.value : this.testDate,
      seedVariety:
          data.seedVariety.present ? data.seedVariety.value : this.seedVariety,
      seedBatch: data.seedBatch.present ? data.seedBatch.value : this.seedBatch,
      testType: data.testType.present ? data.testType.value : this.testType,
      initialSeedCount: data.initialSeedCount.present
          ? data.initialSeedCount.value
          : this.initialSeedCount,
      finalGerminationCount: data.finalGerminationCount.present
          ? data.finalGerminationCount.value
          : this.finalGerminationCount,
      germinationPercentage: data.germinationPercentage.present
          ? data.germinationPercentage.value
          : this.germinationPercentage,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GerminationTest(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('testDate: $testDate, ')
          ..write('seedVariety: $seedVariety, ')
          ..write('seedBatch: $seedBatch, ')
          ..write('testType: $testType, ')
          ..write('initialSeedCount: $initialSeedCount, ')
          ..write('finalGerminationCount: $finalGerminationCount, ')
          ..write('germinationPercentage: $germinationPercentage, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plotId,
      testDate,
      seedVariety,
      seedBatch,
      testType,
      initialSeedCount,
      finalGerminationCount,
      germinationPercentage,
      notes,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GerminationTest &&
          other.id == this.id &&
          other.plotId == this.plotId &&
          other.testDate == this.testDate &&
          other.seedVariety == this.seedVariety &&
          other.seedBatch == this.seedBatch &&
          other.testType == this.testType &&
          other.initialSeedCount == this.initialSeedCount &&
          other.finalGerminationCount == this.finalGerminationCount &&
          other.germinationPercentage == this.germinationPercentage &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GerminationTestsCompanion extends UpdateCompanion<GerminationTest> {
  final Value<int> id;
  final Value<int> plotId;
  final Value<String> testDate;
  final Value<String> seedVariety;
  final Value<String?> seedBatch;
  final Value<String> testType;
  final Value<int> initialSeedCount;
  final Value<int?> finalGerminationCount;
  final Value<double?> germinationPercentage;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GerminationTestsCompanion({
    this.id = const Value.absent(),
    this.plotId = const Value.absent(),
    this.testDate = const Value.absent(),
    this.seedVariety = const Value.absent(),
    this.seedBatch = const Value.absent(),
    this.testType = const Value.absent(),
    this.initialSeedCount = const Value.absent(),
    this.finalGerminationCount = const Value.absent(),
    this.germinationPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GerminationTestsCompanion.insert({
    this.id = const Value.absent(),
    required int plotId,
    required String testDate,
    required String seedVariety,
    this.seedBatch = const Value.absent(),
    required String testType,
    required int initialSeedCount,
    this.finalGerminationCount = const Value.absent(),
    this.germinationPercentage = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  })  : plotId = Value(plotId),
        testDate = Value(testDate),
        seedVariety = Value(seedVariety),
        testType = Value(testType),
        initialSeedCount = Value(initialSeedCount),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<GerminationTest> custom({
    Expression<int>? id,
    Expression<int>? plotId,
    Expression<String>? testDate,
    Expression<String>? seedVariety,
    Expression<String>? seedBatch,
    Expression<String>? testType,
    Expression<int>? initialSeedCount,
    Expression<int>? finalGerminationCount,
    Expression<double>? germinationPercentage,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plotId != null) 'plot_id': plotId,
      if (testDate != null) 'test_date': testDate,
      if (seedVariety != null) 'seed_variety': seedVariety,
      if (seedBatch != null) 'seed_batch': seedBatch,
      if (testType != null) 'test_type': testType,
      if (initialSeedCount != null) 'initial_seed_count': initialSeedCount,
      if (finalGerminationCount != null)
        'final_germination_count': finalGerminationCount,
      if (germinationPercentage != null)
        'germination_percentage': germinationPercentage,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GerminationTestsCompanion copyWith(
      {Value<int>? id,
      Value<int>? plotId,
      Value<String>? testDate,
      Value<String>? seedVariety,
      Value<String?>? seedBatch,
      Value<String>? testType,
      Value<int>? initialSeedCount,
      Value<int?>? finalGerminationCount,
      Value<double?>? germinationPercentage,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt}) {
    return GerminationTestsCompanion(
      id: id ?? this.id,
      plotId: plotId ?? this.plotId,
      testDate: testDate ?? this.testDate,
      seedVariety: seedVariety ?? this.seedVariety,
      seedBatch: seedBatch ?? this.seedBatch,
      testType: testType ?? this.testType,
      initialSeedCount: initialSeedCount ?? this.initialSeedCount,
      finalGerminationCount:
          finalGerminationCount ?? this.finalGerminationCount,
      germinationPercentage:
          germinationPercentage ?? this.germinationPercentage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plotId.present) {
      map['plot_id'] = Variable<int>(plotId.value);
    }
    if (testDate.present) {
      map['test_date'] = Variable<String>(testDate.value);
    }
    if (seedVariety.present) {
      map['seed_variety'] = Variable<String>(seedVariety.value);
    }
    if (seedBatch.present) {
      map['seed_batch'] = Variable<String>(seedBatch.value);
    }
    if (testType.present) {
      map['test_type'] = Variable<String>(testType.value);
    }
    if (initialSeedCount.present) {
      map['initial_seed_count'] = Variable<int>(initialSeedCount.value);
    }
    if (finalGerminationCount.present) {
      map['final_germination_count'] =
          Variable<int>(finalGerminationCount.value);
    }
    if (germinationPercentage.present) {
      map['germination_percentage'] =
          Variable<double>(germinationPercentage.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GerminationTestsCompanion(')
          ..write('id: $id, ')
          ..write('plotId: $plotId, ')
          ..write('testDate: $testDate, ')
          ..write('seedVariety: $seedVariety, ')
          ..write('seedBatch: $seedBatch, ')
          ..write('testType: $testType, ')
          ..write('initialSeedCount: $initialSeedCount, ')
          ..write('finalGerminationCount: $finalGerminationCount, ')
          ..write('germinationPercentage: $germinationPercentage, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GerminationDailyRecordsTable extends GerminationDailyRecords
    with TableInfo<$GerminationDailyRecordsTable, GerminationDailyRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GerminationDailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _testIdMeta = const VerificationMeta('testId');
  @override
  late final GeneratedColumn<int> testId = GeneratedColumn<int>(
      'test_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _recordDateMeta =
      const VerificationMeta('recordDate');
  @override
  late final GeneratedColumn<String> recordDate = GeneratedColumn<String>(
      'record_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _germinatedCountMeta =
      const VerificationMeta('germinatedCount');
  @override
  late final GeneratedColumn<int> germinatedCount = GeneratedColumn<int>(
      'germinated_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, testId, recordDate, germinatedCount, notes, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'germination_daily_records';
  @override
  VerificationContext validateIntegrity(
      Insertable<GerminationDailyRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('test_id')) {
      context.handle(_testIdMeta,
          testId.isAcceptableOrUnknown(data['test_id']!, _testIdMeta));
    } else if (isInserting) {
      context.missing(_testIdMeta);
    }
    if (data.containsKey('record_date')) {
      context.handle(
          _recordDateMeta,
          recordDate.isAcceptableOrUnknown(
              data['record_date']!, _recordDateMeta));
    } else if (isInserting) {
      context.missing(_recordDateMeta);
    }
    if (data.containsKey('germinated_count')) {
      context.handle(
          _germinatedCountMeta,
          germinatedCount.isAcceptableOrUnknown(
              data['germinated_count']!, _germinatedCountMeta));
    } else if (isInserting) {
      context.missing(_germinatedCountMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GerminationDailyRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GerminationDailyRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      testId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}test_id'])!,
      recordDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}record_date'])!,
      germinatedCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}germinated_count'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $GerminationDailyRecordsTable createAlias(String alias) {
    return $GerminationDailyRecordsTable(attachedDatabase, alias);
  }
}

class GerminationDailyRecord extends DataClass
    implements Insertable<GerminationDailyRecord> {
  final int id;
  final int testId;
  final String recordDate;
  final int germinatedCount;
  final String? notes;
  final DateTime createdAt;
  const GerminationDailyRecord(
      {required this.id,
      required this.testId,
      required this.recordDate,
      required this.germinatedCount,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['test_id'] = Variable<int>(testId);
    map['record_date'] = Variable<String>(recordDate);
    map['germinated_count'] = Variable<int>(germinatedCount);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  GerminationDailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return GerminationDailyRecordsCompanion(
      id: Value(id),
      testId: Value(testId),
      recordDate: Value(recordDate),
      germinatedCount: Value(germinatedCount),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory GerminationDailyRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GerminationDailyRecord(
      id: serializer.fromJson<int>(json['id']),
      testId: serializer.fromJson<int>(json['testId']),
      recordDate: serializer.fromJson<String>(json['recordDate']),
      germinatedCount: serializer.fromJson<int>(json['germinatedCount']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'testId': serializer.toJson<int>(testId),
      'recordDate': serializer.toJson<String>(recordDate),
      'germinatedCount': serializer.toJson<int>(germinatedCount),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  GerminationDailyRecord copyWith(
          {int? id,
          int? testId,
          String? recordDate,
          int? germinatedCount,
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      GerminationDailyRecord(
        id: id ?? this.id,
        testId: testId ?? this.testId,
        recordDate: recordDate ?? this.recordDate,
        germinatedCount: germinatedCount ?? this.germinatedCount,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  GerminationDailyRecord copyWithCompanion(
      GerminationDailyRecordsCompanion data) {
    return GerminationDailyRecord(
      id: data.id.present ? data.id.value : this.id,
      testId: data.testId.present ? data.testId.value : this.testId,
      recordDate:
          data.recordDate.present ? data.recordDate.value : this.recordDate,
      germinatedCount: data.germinatedCount.present
          ? data.germinatedCount.value
          : this.germinatedCount,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GerminationDailyRecord(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('recordDate: $recordDate, ')
          ..write('germinatedCount: $germinatedCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, testId, recordDate, germinatedCount, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GerminationDailyRecord &&
          other.id == this.id &&
          other.testId == this.testId &&
          other.recordDate == this.recordDate &&
          other.germinatedCount == this.germinatedCount &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class GerminationDailyRecordsCompanion
    extends UpdateCompanion<GerminationDailyRecord> {
  final Value<int> id;
  final Value<int> testId;
  final Value<String> recordDate;
  final Value<int> germinatedCount;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const GerminationDailyRecordsCompanion({
    this.id = const Value.absent(),
    this.testId = const Value.absent(),
    this.recordDate = const Value.absent(),
    this.germinatedCount = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  GerminationDailyRecordsCompanion.insert({
    this.id = const Value.absent(),
    required int testId,
    required String recordDate,
    required int germinatedCount,
    this.notes = const Value.absent(),
    required DateTime createdAt,
  })  : testId = Value(testId),
        recordDate = Value(recordDate),
        germinatedCount = Value(germinatedCount),
        createdAt = Value(createdAt);
  static Insertable<GerminationDailyRecord> custom({
    Expression<int>? id,
    Expression<int>? testId,
    Expression<String>? recordDate,
    Expression<int>? germinatedCount,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (testId != null) 'test_id': testId,
      if (recordDate != null) 'record_date': recordDate,
      if (germinatedCount != null) 'germinated_count': germinatedCount,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  GerminationDailyRecordsCompanion copyWith(
      {Value<int>? id,
      Value<int>? testId,
      Value<String>? recordDate,
      Value<int>? germinatedCount,
      Value<String?>? notes,
      Value<DateTime>? createdAt}) {
    return GerminationDailyRecordsCompanion(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      recordDate: recordDate ?? this.recordDate,
      germinatedCount: germinatedCount ?? this.germinatedCount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (testId.present) {
      map['test_id'] = Variable<int>(testId.value);
    }
    if (recordDate.present) {
      map['record_date'] = Variable<String>(recordDate.value);
    }
    if (germinatedCount.present) {
      map['germinated_count'] = Variable<int>(germinatedCount.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GerminationDailyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('recordDate: $recordDate, ')
          ..write('germinatedCount: $germinatedCount, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CulturasTable culturas = $CulturasTable(this);
  late final $VariedadesTable variedades = $VariedadesTable(this);
  late final $OrganismosTable organismos = $OrganismosTable(this);
  late final $CulturaOrganismoTable culturaOrganismo =
      $CulturaOrganismoTable(this);
  late final $FotosTable fotos = $FotosTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $SyncHistoryTable syncHistory = $SyncHistoryTable(this);
  late final $MonitoringTable monitoring = $MonitoringTable(this);
  late final $MonitoringPointsTable monitoringPoints =
      $MonitoringPointsTable(this);
  late final $InfestacoesTable infestacoes = $InfestacoesTable(this);
  late final $PlotsTable plots = $PlotsTable(this);
  late final $PolygonsTable polygons = $PolygonsTable(this);
  late final $AplicacoesTable aplicacoes = $AplicacoesTable(this);
  late final $PrescriptionsTable prescriptions = $PrescriptionsTable(this);
  late final $PrescriptionItemsTable prescriptionItems =
      $PrescriptionItemsTable(this);
  late final $CalibracaoFertilizantesTable calibracaoFertilizantes =
      $CalibracaoFertilizantesTable(this);
  late final $EstoqueTable estoque = $EstoqueTable(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $InventoryMovementsTable inventoryMovements =
      $InventoryMovementsTable(this);
  late final $SoilAnalysisTable soilAnalysis = $SoilAnalysisTable(this);
  late final $SoilSamplesTable soilSamples = $SoilSamplesTable(this);
  late final $GerminationTestsTable germinationTests =
      $GerminationTestsTable(this);
  late final $GerminationDailyRecordsTable germinationDailyRecords =
      $GerminationDailyRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        culturas,
        variedades,
        organismos,
        culturaOrganismo,
        fotos,
        auditLog,
        syncQueue,
        syncHistory,
        monitoring,
        monitoringPoints,
        infestacoes,
        plots,
        polygons,
        aplicacoes,
        prescriptions,
        prescriptionItems,
        calibracaoFertilizantes,
        estoque,
        inventoryItems,
        inventoryMovements,
        soilAnalysis,
        soilSamples,
        germinationTests,
        germinationDailyRecords
      ];
}

typedef $$CulturasTableCreateCompanionBuilder = CulturasCompanion Function({
  Value<int> id,
  required String nome,
  Value<String?> iconePath,
});
typedef $$CulturasTableUpdateCompanionBuilder = CulturasCompanion Function({
  Value<int> id,
  Value<String> nome,
  Value<String?> iconePath,
});

class $$CulturasTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CulturasTable,
    Cultura,
    $$CulturasTableFilterComposer,
    $$CulturasTableOrderingComposer,
    $$CulturasTableCreateCompanionBuilder,
    $$CulturasTableUpdateCompanionBuilder> {
  $$CulturasTableTableManager(_$AppDatabase db, $CulturasTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CulturasTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CulturasTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> iconePath = const Value.absent(),
          }) =>
              CulturasCompanion(
            id: id,
            nome: nome,
            iconePath: iconePath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String nome,
            Value<String?> iconePath = const Value.absent(),
          }) =>
              CulturasCompanion.insert(
            id: id,
            nome: nome,
            iconePath: iconePath,
          ),
        ));
}

class $$CulturasTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CulturasTable> {
  $$CulturasTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nome => $state.composableBuilder(
      column: $state.table.nome,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconePath => $state.composableBuilder(
      column: $state.table.iconePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter variedadesRefs(
      ComposableFilter Function($$VariedadesTableFilterComposer f) f) {
    final $$VariedadesTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.variedades,
        getReferencedColumn: (t) => t.culturaId,
        builder: (joinBuilder, parentComposers) =>
            $$VariedadesTableFilterComposer(ComposerState($state.db,
                $state.db.variedades, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter culturaOrganismoRefs(
      ComposableFilter Function($$CulturaOrganismoTableFilterComposer f) f) {
    final $$CulturaOrganismoTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.culturaOrganismo,
            getReferencedColumn: (t) => t.culturaId,
            builder: (joinBuilder, parentComposers) =>
                $$CulturaOrganismoTableFilterComposer(ComposerState($state.db,
                    $state.db.culturaOrganismo, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$CulturasTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CulturasTable> {
  $$CulturasTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nome => $state.composableBuilder(
      column: $state.table.nome,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconePath => $state.composableBuilder(
      column: $state.table.iconePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$VariedadesTableCreateCompanionBuilder = VariedadesCompanion Function({
  Value<int> id,
  required int culturaId,
  required String nome,
  Value<String?> ciclo,
  Value<String?> observacoes,
});
typedef $$VariedadesTableUpdateCompanionBuilder = VariedadesCompanion Function({
  Value<int> id,
  Value<int> culturaId,
  Value<String> nome,
  Value<String?> ciclo,
  Value<String?> observacoes,
});

class $$VariedadesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VariedadesTable,
    Variedade,
    $$VariedadesTableFilterComposer,
    $$VariedadesTableOrderingComposer,
    $$VariedadesTableCreateCompanionBuilder,
    $$VariedadesTableUpdateCompanionBuilder> {
  $$VariedadesTableTableManager(_$AppDatabase db, $VariedadesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$VariedadesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$VariedadesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> culturaId = const Value.absent(),
            Value<String> nome = const Value.absent(),
            Value<String?> ciclo = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              VariedadesCompanion(
            id: id,
            culturaId: culturaId,
            nome: nome,
            ciclo: ciclo,
            observacoes: observacoes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int culturaId,
            required String nome,
            Value<String?> ciclo = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              VariedadesCompanion.insert(
            id: id,
            culturaId: culturaId,
            nome: nome,
            ciclo: ciclo,
            observacoes: observacoes,
          ),
        ));
}

class $$VariedadesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $VariedadesTable> {
  $$VariedadesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nome => $state.composableBuilder(
      column: $state.table.nome,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ciclo => $state.composableBuilder(
      column: $state.table.ciclo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get observacoes => $state.composableBuilder(
      column: $state.table.observacoes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CulturasTableFilterComposer get culturaId {
    final $$CulturasTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.culturaId,
        referencedTable: $state.db.culturas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CulturasTableFilterComposer(ComposerState(
                $state.db, $state.db.culturas, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$VariedadesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $VariedadesTable> {
  $$VariedadesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nome => $state.composableBuilder(
      column: $state.table.nome,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ciclo => $state.composableBuilder(
      column: $state.table.ciclo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get observacoes => $state.composableBuilder(
      column: $state.table.observacoes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CulturasTableOrderingComposer get culturaId {
    final $$CulturasTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.culturaId,
        referencedTable: $state.db.culturas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CulturasTableOrderingComposer(ComposerState(
                $state.db, $state.db.culturas, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$OrganismosTableCreateCompanionBuilder = OrganismosCompanion Function({
  Value<int> id,
  required String tipo,
  required String nomeComum,
  Value<String?> nomeCientifico,
  Value<String?> categoria,
  Value<String?> iconePath,
  Value<String?> sintomaDescricao,
  Value<String?> danoEconomico,
  Value<String?> partesAfetadas,
  Value<String?> fenologia,
  Value<String?> niveisAcao,
  Value<String?> manejoQuimico,
  Value<String?> manejoBiologico,
  Value<String?> manejoCultural,
  Value<String?> observacoes,
});
typedef $$OrganismosTableUpdateCompanionBuilder = OrganismosCompanion Function({
  Value<int> id,
  Value<String> tipo,
  Value<String> nomeComum,
  Value<String?> nomeCientifico,
  Value<String?> categoria,
  Value<String?> iconePath,
  Value<String?> sintomaDescricao,
  Value<String?> danoEconomico,
  Value<String?> partesAfetadas,
  Value<String?> fenologia,
  Value<String?> niveisAcao,
  Value<String?> manejoQuimico,
  Value<String?> manejoBiologico,
  Value<String?> manejoCultural,
  Value<String?> observacoes,
});

class $$OrganismosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $OrganismosTable,
    Organismo,
    $$OrganismosTableFilterComposer,
    $$OrganismosTableOrderingComposer,
    $$OrganismosTableCreateCompanionBuilder,
    $$OrganismosTableUpdateCompanionBuilder> {
  $$OrganismosTableTableManager(_$AppDatabase db, $OrganismosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$OrganismosTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$OrganismosTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tipo = const Value.absent(),
            Value<String> nomeComum = const Value.absent(),
            Value<String?> nomeCientifico = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            Value<String?> iconePath = const Value.absent(),
            Value<String?> sintomaDescricao = const Value.absent(),
            Value<String?> danoEconomico = const Value.absent(),
            Value<String?> partesAfetadas = const Value.absent(),
            Value<String?> fenologia = const Value.absent(),
            Value<String?> niveisAcao = const Value.absent(),
            Value<String?> manejoQuimico = const Value.absent(),
            Value<String?> manejoBiologico = const Value.absent(),
            Value<String?> manejoCultural = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              OrganismosCompanion(
            id: id,
            tipo: tipo,
            nomeComum: nomeComum,
            nomeCientifico: nomeCientifico,
            categoria: categoria,
            iconePath: iconePath,
            sintomaDescricao: sintomaDescricao,
            danoEconomico: danoEconomico,
            partesAfetadas: partesAfetadas,
            fenologia: fenologia,
            niveisAcao: niveisAcao,
            manejoQuimico: manejoQuimico,
            manejoBiologico: manejoBiologico,
            manejoCultural: manejoCultural,
            observacoes: observacoes,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tipo,
            required String nomeComum,
            Value<String?> nomeCientifico = const Value.absent(),
            Value<String?> categoria = const Value.absent(),
            Value<String?> iconePath = const Value.absent(),
            Value<String?> sintomaDescricao = const Value.absent(),
            Value<String?> danoEconomico = const Value.absent(),
            Value<String?> partesAfetadas = const Value.absent(),
            Value<String?> fenologia = const Value.absent(),
            Value<String?> niveisAcao = const Value.absent(),
            Value<String?> manejoQuimico = const Value.absent(),
            Value<String?> manejoBiologico = const Value.absent(),
            Value<String?> manejoCultural = const Value.absent(),
            Value<String?> observacoes = const Value.absent(),
          }) =>
              OrganismosCompanion.insert(
            id: id,
            tipo: tipo,
            nomeComum: nomeComum,
            nomeCientifico: nomeCientifico,
            categoria: categoria,
            iconePath: iconePath,
            sintomaDescricao: sintomaDescricao,
            danoEconomico: danoEconomico,
            partesAfetadas: partesAfetadas,
            fenologia: fenologia,
            niveisAcao: niveisAcao,
            manejoQuimico: manejoQuimico,
            manejoBiologico: manejoBiologico,
            manejoCultural: manejoCultural,
            observacoes: observacoes,
          ),
        ));
}

class $$OrganismosTableFilterComposer
    extends FilterComposer<_$AppDatabase, $OrganismosTable> {
  $$OrganismosTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tipo => $state.composableBuilder(
      column: $state.table.tipo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nomeComum => $state.composableBuilder(
      column: $state.table.nomeComum,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get nomeCientifico => $state.composableBuilder(
      column: $state.table.nomeCientifico,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get categoria => $state.composableBuilder(
      column: $state.table.categoria,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get iconePath => $state.composableBuilder(
      column: $state.table.iconePath,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sintomaDescricao => $state.composableBuilder(
      column: $state.table.sintomaDescricao,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get danoEconomico => $state.composableBuilder(
      column: $state.table.danoEconomico,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get partesAfetadas => $state.composableBuilder(
      column: $state.table.partesAfetadas,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fenologia => $state.composableBuilder(
      column: $state.table.fenologia,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get niveisAcao => $state.composableBuilder(
      column: $state.table.niveisAcao,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get manejoQuimico => $state.composableBuilder(
      column: $state.table.manejoQuimico,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get manejoBiologico => $state.composableBuilder(
      column: $state.table.manejoBiologico,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get manejoCultural => $state.composableBuilder(
      column: $state.table.manejoCultural,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get observacoes => $state.composableBuilder(
      column: $state.table.observacoes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ComposableFilter culturaOrganismoRefs(
      ComposableFilter Function($$CulturaOrganismoTableFilterComposer f) f) {
    final $$CulturaOrganismoTableFilterComposer composer =
        $state.composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $state.db.culturaOrganismo,
            getReferencedColumn: (t) => t.organismoId,
            builder: (joinBuilder, parentComposers) =>
                $$CulturaOrganismoTableFilterComposer(ComposerState($state.db,
                    $state.db.culturaOrganismo, joinBuilder, parentComposers)));
    return f(composer);
  }

  ComposableFilter fotosRefs(
      ComposableFilter Function($$FotosTableFilterComposer f) f) {
    final $$FotosTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $state.db.fotos,
        getReferencedColumn: (t) => t.organismoId,
        builder: (joinBuilder, parentComposers) => $$FotosTableFilterComposer(
            ComposerState(
                $state.db, $state.db.fotos, joinBuilder, parentComposers)));
    return f(composer);
  }
}

class $$OrganismosTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $OrganismosTable> {
  $$OrganismosTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tipo => $state.composableBuilder(
      column: $state.table.tipo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nomeComum => $state.composableBuilder(
      column: $state.table.nomeComum,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get nomeCientifico => $state.composableBuilder(
      column: $state.table.nomeCientifico,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get categoria => $state.composableBuilder(
      column: $state.table.categoria,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get iconePath => $state.composableBuilder(
      column: $state.table.iconePath,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sintomaDescricao => $state.composableBuilder(
      column: $state.table.sintomaDescricao,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get danoEconomico => $state.composableBuilder(
      column: $state.table.danoEconomico,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get partesAfetadas => $state.composableBuilder(
      column: $state.table.partesAfetadas,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fenologia => $state.composableBuilder(
      column: $state.table.fenologia,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get niveisAcao => $state.composableBuilder(
      column: $state.table.niveisAcao,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get manejoQuimico => $state.composableBuilder(
      column: $state.table.manejoQuimico,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get manejoBiologico => $state.composableBuilder(
      column: $state.table.manejoBiologico,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get manejoCultural => $state.composableBuilder(
      column: $state.table.manejoCultural,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get observacoes => $state.composableBuilder(
      column: $state.table.observacoes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CulturaOrganismoTableCreateCompanionBuilder
    = CulturaOrganismoCompanion Function({
  Value<int> id,
  required int culturaId,
  required int organismoId,
  Value<double?> severidadeMedia,
  Value<String?> observacoesEspecificas,
});
typedef $$CulturaOrganismoTableUpdateCompanionBuilder
    = CulturaOrganismoCompanion Function({
  Value<int> id,
  Value<int> culturaId,
  Value<int> organismoId,
  Value<double?> severidadeMedia,
  Value<String?> observacoesEspecificas,
});

class $$CulturaOrganismoTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CulturaOrganismoTable,
    CulturaOrganismoData,
    $$CulturaOrganismoTableFilterComposer,
    $$CulturaOrganismoTableOrderingComposer,
    $$CulturaOrganismoTableCreateCompanionBuilder,
    $$CulturaOrganismoTableUpdateCompanionBuilder> {
  $$CulturaOrganismoTableTableManager(
      _$AppDatabase db, $CulturaOrganismoTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$CulturaOrganismoTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$CulturaOrganismoTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> culturaId = const Value.absent(),
            Value<int> organismoId = const Value.absent(),
            Value<double?> severidadeMedia = const Value.absent(),
            Value<String?> observacoesEspecificas = const Value.absent(),
          }) =>
              CulturaOrganismoCompanion(
            id: id,
            culturaId: culturaId,
            organismoId: organismoId,
            severidadeMedia: severidadeMedia,
            observacoesEspecificas: observacoesEspecificas,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int culturaId,
            required int organismoId,
            Value<double?> severidadeMedia = const Value.absent(),
            Value<String?> observacoesEspecificas = const Value.absent(),
          }) =>
              CulturaOrganismoCompanion.insert(
            id: id,
            culturaId: culturaId,
            organismoId: organismoId,
            severidadeMedia: severidadeMedia,
            observacoesEspecificas: observacoesEspecificas,
          ),
        ));
}

class $$CulturaOrganismoTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CulturaOrganismoTable> {
  $$CulturaOrganismoTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get severidadeMedia => $state.composableBuilder(
      column: $state.table.severidadeMedia,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get observacoesEspecificas => $state.composableBuilder(
      column: $state.table.observacoesEspecificas,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$CulturasTableFilterComposer get culturaId {
    final $$CulturasTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.culturaId,
        referencedTable: $state.db.culturas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CulturasTableFilterComposer(ComposerState(
                $state.db, $state.db.culturas, joinBuilder, parentComposers)));
    return composer;
  }

  $$OrganismosTableFilterComposer get organismoId {
    final $$OrganismosTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organismoId,
        referencedTable: $state.db.organismos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$OrganismosTableFilterComposer(ComposerState($state.db,
                $state.db.organismos, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$CulturaOrganismoTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CulturaOrganismoTable> {
  $$CulturaOrganismoTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get severidadeMedia => $state.composableBuilder(
      column: $state.table.severidadeMedia,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get observacoesEspecificas =>
      $state.composableBuilder(
          column: $state.table.observacoesEspecificas,
          builder: (column, joinBuilders) =>
              ColumnOrderings(column, joinBuilders: joinBuilders));

  $$CulturasTableOrderingComposer get culturaId {
    final $$CulturasTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.culturaId,
        referencedTable: $state.db.culturas,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$CulturasTableOrderingComposer(ComposerState(
                $state.db, $state.db.culturas, joinBuilder, parentComposers)));
    return composer;
  }

  $$OrganismosTableOrderingComposer get organismoId {
    final $$OrganismosTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organismoId,
        referencedTable: $state.db.organismos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$OrganismosTableOrderingComposer(ComposerState($state.db,
                $state.db.organismos, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$FotosTableCreateCompanionBuilder = FotosCompanion Function({
  Value<int> id,
  required int organismoId,
  required String path,
  Value<bool> isIcon,
});
typedef $$FotosTableUpdateCompanionBuilder = FotosCompanion Function({
  Value<int> id,
  Value<int> organismoId,
  Value<String> path,
  Value<bool> isIcon,
});

class $$FotosTableTableManager extends RootTableManager<
    _$AppDatabase,
    $FotosTable,
    Foto,
    $$FotosTableFilterComposer,
    $$FotosTableOrderingComposer,
    $$FotosTableCreateCompanionBuilder,
    $$FotosTableUpdateCompanionBuilder> {
  $$FotosTableTableManager(_$AppDatabase db, $FotosTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$FotosTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$FotosTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> organismoId = const Value.absent(),
            Value<String> path = const Value.absent(),
            Value<bool> isIcon = const Value.absent(),
          }) =>
              FotosCompanion(
            id: id,
            organismoId: organismoId,
            path: path,
            isIcon: isIcon,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int organismoId,
            required String path,
            Value<bool> isIcon = const Value.absent(),
          }) =>
              FotosCompanion.insert(
            id: id,
            organismoId: organismoId,
            path: path,
            isIcon: isIcon,
          ),
        ));
}

class $$FotosTableFilterComposer
    extends FilterComposer<_$AppDatabase, $FotosTable> {
  $$FotosTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isIcon => $state.composableBuilder(
      column: $state.table.isIcon,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  $$OrganismosTableFilterComposer get organismoId {
    final $$OrganismosTableFilterComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organismoId,
        referencedTable: $state.db.organismos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$OrganismosTableFilterComposer(ComposerState($state.db,
                $state.db.organismos, joinBuilder, parentComposers)));
    return composer;
  }
}

class $$FotosTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $FotosTable> {
  $$FotosTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get path => $state.composableBuilder(
      column: $state.table.path,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isIcon => $state.composableBuilder(
      column: $state.table.isIcon,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  $$OrganismosTableOrderingComposer get organismoId {
    final $$OrganismosTableOrderingComposer composer = $state.composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.organismoId,
        referencedTable: $state.db.organismos,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder, parentComposers) =>
            $$OrganismosTableOrderingComposer(ComposerState($state.db,
                $state.db.organismos, joinBuilder, parentComposers)));
    return composer;
  }
}

typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  required String tableName,
  required int recordId,
  required String action,
  Value<String?> oldValues,
  Value<String?> newValues,
  Value<String?> userId,
  Value<String?> notes,
  required String level,
  required DateTime timestamp,
  Value<String?> deviceInfo,
  Value<String?> ipAddress,
  Value<String?> userAgent,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<String> tableName,
  Value<int> recordId,
  Value<String> action,
  Value<String?> oldValues,
  Value<String?> newValues,
  Value<String?> userId,
  Value<String?> notes,
  Value<String> level,
  Value<DateTime> timestamp,
  Value<String?> deviceInfo,
  Value<String?> ipAddress,
  Value<String?> userAgent,
});

class $$AuditLogTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AuditLogTable,
    AuditLogData,
    $$AuditLogTableFilterComposer,
    $$AuditLogTableOrderingComposer,
    $$AuditLogTableCreateCompanionBuilder,
    $$AuditLogTableUpdateCompanionBuilder> {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AuditLogTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AuditLogTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tableName = const Value.absent(),
            Value<int> recordId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String?> oldValues = const Value.absent(),
            Value<String?> newValues = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String> level = const Value.absent(),
            Value<DateTime> timestamp = const Value.absent(),
            Value<String?> deviceInfo = const Value.absent(),
            Value<String?> ipAddress = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
          }) =>
              AuditLogCompanion(
            id: id,
            tableName: tableName,
            recordId: recordId,
            action: action,
            oldValues: oldValues,
            newValues: newValues,
            userId: userId,
            notes: notes,
            level: level,
            timestamp: timestamp,
            deviceInfo: deviceInfo,
            ipAddress: ipAddress,
            userAgent: userAgent,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tableName,
            required int recordId,
            required String action,
            Value<String?> oldValues = const Value.absent(),
            Value<String?> newValues = const Value.absent(),
            Value<String?> userId = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required String level,
            required DateTime timestamp,
            Value<String?> deviceInfo = const Value.absent(),
            Value<String?> ipAddress = const Value.absent(),
            Value<String?> userAgent = const Value.absent(),
          }) =>
              AuditLogCompanion.insert(
            id: id,
            tableName: tableName,
            recordId: recordId,
            action: action,
            oldValues: oldValues,
            newValues: newValues,
            userId: userId,
            notes: notes,
            level: level,
            timestamp: timestamp,
            deviceInfo: deviceInfo,
            ipAddress: ipAddress,
            userAgent: userAgent,
          ),
        ));
}

class $$AuditLogTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tableName => $state.composableBuilder(
      column: $state.table.tableName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get oldValues => $state.composableBuilder(
      column: $state.table.oldValues,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get newValues => $state.composableBuilder(
      column: $state.table.newValues,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get deviceInfo => $state.composableBuilder(
      column: $state.table.deviceInfo,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get ipAddress => $state.composableBuilder(
      column: $state.table.ipAddress,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userAgent => $state.composableBuilder(
      column: $state.table.userAgent,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AuditLogTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tableName => $state.composableBuilder(
      column: $state.table.tableName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get oldValues => $state.composableBuilder(
      column: $state.table.oldValues,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get newValues => $state.composableBuilder(
      column: $state.table.newValues,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userId => $state.composableBuilder(
      column: $state.table.userId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get level => $state.composableBuilder(
      column: $state.table.level,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get timestamp => $state.composableBuilder(
      column: $state.table.timestamp,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get deviceInfo => $state.composableBuilder(
      column: $state.table.deviceInfo,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get ipAddress => $state.composableBuilder(
      column: $state.table.ipAddress,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userAgent => $state.composableBuilder(
      column: $state.table.userAgent,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String tableName,
  required int recordId,
  required String action,
  required String data,
  Value<int> priority,
  Value<int> retryCount,
  Value<int> maxRetries,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<String> status,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> tableName,
  Value<int> recordId,
  Value<String> action,
  Value<String> data,
  Value<int> priority,
  Value<int> retryCount,
  Value<int> maxRetries,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> status,
});

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncQueueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncQueueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> tableName = const Value.absent(),
            Value<int> recordId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> data = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            tableName: tableName,
            recordId: recordId,
            action: action,
            data: data,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String tableName,
            required int recordId,
            required String action,
            required String data,
            Value<int> priority = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> maxRetries = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<String> status = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            tableName: tableName,
            recordId: recordId,
            action: action,
            data: data,
            priority: priority,
            retryCount: retryCount,
            maxRetries: maxRetries,
            createdAt: createdAt,
            updatedAt: updatedAt,
            status: status,
          ),
        ));
}

class $$SyncQueueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get tableName => $state.composableBuilder(
      column: $state.table.tableName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get maxRetries => $state.composableBuilder(
      column: $state.table.maxRetries,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncQueueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get tableName => $state.composableBuilder(
      column: $state.table.tableName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordId => $state.composableBuilder(
      column: $state.table.recordId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get action => $state.composableBuilder(
      column: $state.table.action,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get priority => $state.composableBuilder(
      column: $state.table.priority,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get retryCount => $state.composableBuilder(
      column: $state.table.retryCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get maxRetries => $state.composableBuilder(
      column: $state.table.maxRetries,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SyncHistoryTableCreateCompanionBuilder = SyncHistoryCompanion
    Function({
  Value<int> id,
  required String syncType,
  required String status,
  Value<int> recordsProcessed,
  Value<int> recordsSuccess,
  Value<int> recordsFailed,
  required DateTime startTime,
  Value<DateTime?> endTime,
  Value<String?> errorMessage,
  required DateTime createdAt,
});
typedef $$SyncHistoryTableUpdateCompanionBuilder = SyncHistoryCompanion
    Function({
  Value<int> id,
  Value<String> syncType,
  Value<String> status,
  Value<int> recordsProcessed,
  Value<int> recordsSuccess,
  Value<int> recordsFailed,
  Value<DateTime> startTime,
  Value<DateTime?> endTime,
  Value<String?> errorMessage,
  Value<DateTime> createdAt,
});

class $$SyncHistoryTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncHistoryTable,
    SyncHistoryData,
    $$SyncHistoryTableFilterComposer,
    $$SyncHistoryTableOrderingComposer,
    $$SyncHistoryTableCreateCompanionBuilder,
    $$SyncHistoryTableUpdateCompanionBuilder> {
  $$SyncHistoryTableTableManager(_$AppDatabase db, $SyncHistoryTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SyncHistoryTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SyncHistoryTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> syncType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> recordsProcessed = const Value.absent(),
            Value<int> recordsSuccess = const Value.absent(),
            Value<int> recordsFailed = const Value.absent(),
            Value<DateTime> startTime = const Value.absent(),
            Value<DateTime?> endTime = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SyncHistoryCompanion(
            id: id,
            syncType: syncType,
            status: status,
            recordsProcessed: recordsProcessed,
            recordsSuccess: recordsSuccess,
            recordsFailed: recordsFailed,
            startTime: startTime,
            endTime: endTime,
            errorMessage: errorMessage,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String syncType,
            required String status,
            Value<int> recordsProcessed = const Value.absent(),
            Value<int> recordsSuccess = const Value.absent(),
            Value<int> recordsFailed = const Value.absent(),
            required DateTime startTime,
            Value<DateTime?> endTime = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            required DateTime createdAt,
          }) =>
              SyncHistoryCompanion.insert(
            id: id,
            syncType: syncType,
            status: status,
            recordsProcessed: recordsProcessed,
            recordsSuccess: recordsSuccess,
            recordsFailed: recordsFailed,
            startTime: startTime,
            endTime: endTime,
            errorMessage: errorMessage,
            createdAt: createdAt,
          ),
        ));
}

class $$SyncHistoryTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get syncType => $state.composableBuilder(
      column: $state.table.syncType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordsProcessed => $state.composableBuilder(
      column: $state.table.recordsProcessed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordsSuccess => $state.composableBuilder(
      column: $state.table.recordsSuccess,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get recordsFailed => $state.composableBuilder(
      column: $state.table.recordsFailed,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SyncHistoryTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get syncType => $state.composableBuilder(
      column: $state.table.syncType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordsProcessed => $state.composableBuilder(
      column: $state.table.recordsProcessed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordsSuccess => $state.composableBuilder(
      column: $state.table.recordsSuccess,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get recordsFailed => $state.composableBuilder(
      column: $state.table.recordsFailed,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get startTime => $state.composableBuilder(
      column: $state.table.startTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get endTime => $state.composableBuilder(
      column: $state.table.endTime,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get errorMessage => $state.composableBuilder(
      column: $state.table.errorMessage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MonitoringTableCreateCompanionBuilder = MonitoringCompanion Function({
  Value<int> id,
  Value<int?> plotId,
  required String date,
  Value<String?> weatherCondition,
  Value<double?> temperature,
  Value<double?> humidity,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$MonitoringTableUpdateCompanionBuilder = MonitoringCompanion Function({
  Value<int> id,
  Value<int?> plotId,
  Value<String> date,
  Value<String?> weatherCondition,
  Value<double?> temperature,
  Value<double?> humidity,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$MonitoringTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonitoringTable,
    MonitoringData,
    $$MonitoringTableFilterComposer,
    $$MonitoringTableOrderingComposer,
    $$MonitoringTableCreateCompanionBuilder,
    $$MonitoringTableUpdateCompanionBuilder> {
  $$MonitoringTableTableManager(_$AppDatabase db, $MonitoringTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MonitoringTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MonitoringTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> plotId = const Value.absent(),
            Value<String> date = const Value.absent(),
            Value<String?> weatherCondition = const Value.absent(),
            Value<double?> temperature = const Value.absent(),
            Value<double?> humidity = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              MonitoringCompanion(
            id: id,
            plotId: plotId,
            date: date,
            weatherCondition: weatherCondition,
            temperature: temperature,
            humidity: humidity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int?> plotId = const Value.absent(),
            required String date,
            Value<String?> weatherCondition = const Value.absent(),
            Value<double?> temperature = const Value.absent(),
            Value<double?> humidity = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              MonitoringCompanion.insert(
            id: id,
            plotId: plotId,
            date: date,
            weatherCondition: weatherCondition,
            temperature: temperature,
            humidity: humidity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$MonitoringTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MonitoringTable> {
  $$MonitoringTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get weatherCondition => $state.composableBuilder(
      column: $state.table.weatherCondition,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get humidity => $state.composableBuilder(
      column: $state.table.humidity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MonitoringTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MonitoringTable> {
  $$MonitoringTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get date => $state.composableBuilder(
      column: $state.table.date,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get weatherCondition => $state.composableBuilder(
      column: $state.table.weatherCondition,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get temperature => $state.composableBuilder(
      column: $state.table.temperature,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get humidity => $state.composableBuilder(
      column: $state.table.humidity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$MonitoringPointsTableCreateCompanionBuilder
    = MonitoringPointsCompanion Function({
  Value<int> id,
  required int monitoringId,
  required double latitude,
  required double longitude,
  Value<int?> organismId,
  Value<int?> severityLevel,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$MonitoringPointsTableUpdateCompanionBuilder
    = MonitoringPointsCompanion Function({
  Value<int> id,
  Value<int> monitoringId,
  Value<double> latitude,
  Value<double> longitude,
  Value<int?> organismId,
  Value<int?> severityLevel,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$MonitoringPointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MonitoringPointsTable,
    MonitoringPoint,
    $$MonitoringPointsTableFilterComposer,
    $$MonitoringPointsTableOrderingComposer,
    $$MonitoringPointsTableCreateCompanionBuilder,
    $$MonitoringPointsTableUpdateCompanionBuilder> {
  $$MonitoringPointsTableTableManager(
      _$AppDatabase db, $MonitoringPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$MonitoringPointsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$MonitoringPointsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> monitoringId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<int?> organismId = const Value.absent(),
            Value<int?> severityLevel = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              MonitoringPointsCompanion(
            id: id,
            monitoringId: monitoringId,
            latitude: latitude,
            longitude: longitude,
            organismId: organismId,
            severityLevel: severityLevel,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int monitoringId,
            required double latitude,
            required double longitude,
            Value<int?> organismId = const Value.absent(),
            Value<int?> severityLevel = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              MonitoringPointsCompanion.insert(
            id: id,
            monitoringId: monitoringId,
            latitude: latitude,
            longitude: longitude,
            organismId: organismId,
            severityLevel: severityLevel,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$MonitoringPointsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $MonitoringPointsTable> {
  $$MonitoringPointsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get monitoringId => $state.composableBuilder(
      column: $state.table.monitoringId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get organismId => $state.composableBuilder(
      column: $state.table.organismId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get severityLevel => $state.composableBuilder(
      column: $state.table.severityLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$MonitoringPointsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $MonitoringPointsTable> {
  $$MonitoringPointsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get monitoringId => $state.composableBuilder(
      column: $state.table.monitoringId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get organismId => $state.composableBuilder(
      column: $state.table.organismId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get severityLevel => $state.composableBuilder(
      column: $state.table.severityLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InfestacoesTableCreateCompanionBuilder = InfestacoesCompanion
    Function({
  Value<int> id,
  required int monitoringPointId,
  required int organismId,
  required int severityLevel,
  Value<double?> affectedArea,
  Value<String?> treatmentApplied,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$InfestacoesTableUpdateCompanionBuilder = InfestacoesCompanion
    Function({
  Value<int> id,
  Value<int> monitoringPointId,
  Value<int> organismId,
  Value<int> severityLevel,
  Value<double?> affectedArea,
  Value<String?> treatmentApplied,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$InfestacoesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InfestacoesTable,
    Infestacoe,
    $$InfestacoesTableFilterComposer,
    $$InfestacoesTableOrderingComposer,
    $$InfestacoesTableCreateCompanionBuilder,
    $$InfestacoesTableUpdateCompanionBuilder> {
  $$InfestacoesTableTableManager(_$AppDatabase db, $InfestacoesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InfestacoesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InfestacoesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> monitoringPointId = const Value.absent(),
            Value<int> organismId = const Value.absent(),
            Value<int> severityLevel = const Value.absent(),
            Value<double?> affectedArea = const Value.absent(),
            Value<String?> treatmentApplied = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InfestacoesCompanion(
            id: id,
            monitoringPointId: monitoringPointId,
            organismId: organismId,
            severityLevel: severityLevel,
            affectedArea: affectedArea,
            treatmentApplied: treatmentApplied,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int monitoringPointId,
            required int organismId,
            required int severityLevel,
            Value<double?> affectedArea = const Value.absent(),
            Value<String?> treatmentApplied = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              InfestacoesCompanion.insert(
            id: id,
            monitoringPointId: monitoringPointId,
            organismId: organismId,
            severityLevel: severityLevel,
            affectedArea: affectedArea,
            treatmentApplied: treatmentApplied,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$InfestacoesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InfestacoesTable> {
  $$InfestacoesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get monitoringPointId => $state.composableBuilder(
      column: $state.table.monitoringPointId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get organismId => $state.composableBuilder(
      column: $state.table.organismId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get severityLevel => $state.composableBuilder(
      column: $state.table.severityLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get affectedArea => $state.composableBuilder(
      column: $state.table.affectedArea,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get treatmentApplied => $state.composableBuilder(
      column: $state.table.treatmentApplied,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InfestacoesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InfestacoesTable> {
  $$InfestacoesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get monitoringPointId => $state.composableBuilder(
      column: $state.table.monitoringPointId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get organismId => $state.composableBuilder(
      column: $state.table.organismId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get severityLevel => $state.composableBuilder(
      column: $state.table.severityLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get affectedArea => $state.composableBuilder(
      column: $state.table.affectedArea,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get treatmentApplied => $state.composableBuilder(
      column: $state.table.treatmentApplied,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PlotsTableCreateCompanionBuilder = PlotsCompanion Function({
  Value<int> id,
  required String name,
  Value<double?> area,
  Value<int?> cultureId,
  Value<int?> varietyId,
  Value<String?> plantingDate,
  Value<String?> harvestDate,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PlotsTableUpdateCompanionBuilder = PlotsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<double?> area,
  Value<int?> cultureId,
  Value<int?> varietyId,
  Value<String?> plantingDate,
  Value<String?> harvestDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PlotsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PlotsTable,
    Plot,
    $$PlotsTableFilterComposer,
    $$PlotsTableOrderingComposer,
    $$PlotsTableCreateCompanionBuilder,
    $$PlotsTableUpdateCompanionBuilder> {
  $$PlotsTableTableManager(_$AppDatabase db, $PlotsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PlotsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PlotsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<double?> area = const Value.absent(),
            Value<int?> cultureId = const Value.absent(),
            Value<int?> varietyId = const Value.absent(),
            Value<String?> plantingDate = const Value.absent(),
            Value<String?> harvestDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PlotsCompanion(
            id: id,
            name: name,
            area: area,
            cultureId: cultureId,
            varietyId: varietyId,
            plantingDate: plantingDate,
            harvestDate: harvestDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<double?> area = const Value.absent(),
            Value<int?> cultureId = const Value.absent(),
            Value<int?> varietyId = const Value.absent(),
            Value<String?> plantingDate = const Value.absent(),
            Value<String?> harvestDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              PlotsCompanion.insert(
            id: id,
            name: name,
            area: area,
            cultureId: cultureId,
            varietyId: varietyId,
            plantingDate: plantingDate,
            harvestDate: harvestDate,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$PlotsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get cultureId => $state.composableBuilder(
      column: $state.table.cultureId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get varietyId => $state.composableBuilder(
      column: $state.table.varietyId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get plantingDate => $state.composableBuilder(
      column: $state.table.plantingDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get harvestDate => $state.composableBuilder(
      column: $state.table.harvestDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PlotsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PlotsTable> {
  $$PlotsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get name => $state.composableBuilder(
      column: $state.table.name,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get area => $state.composableBuilder(
      column: $state.table.area,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get cultureId => $state.composableBuilder(
      column: $state.table.cultureId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get varietyId => $state.composableBuilder(
      column: $state.table.varietyId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get plantingDate => $state.composableBuilder(
      column: $state.table.plantingDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get harvestDate => $state.composableBuilder(
      column: $state.table.harvestDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PolygonsTableCreateCompanionBuilder = PolygonsCompanion Function({
  Value<int> id,
  required int plotId,
  required double latitude,
  required double longitude,
  required int orderIndex,
  required DateTime createdAt,
});
typedef $$PolygonsTableUpdateCompanionBuilder = PolygonsCompanion Function({
  Value<int> id,
  Value<int> plotId,
  Value<double> latitude,
  Value<double> longitude,
  Value<int> orderIndex,
  Value<DateTime> createdAt,
});

class $$PolygonsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PolygonsTable,
    Polygon,
    $$PolygonsTableFilterComposer,
    $$PolygonsTableOrderingComposer,
    $$PolygonsTableCreateCompanionBuilder,
    $$PolygonsTableUpdateCompanionBuilder> {
  $$PolygonsTableTableManager(_$AppDatabase db, $PolygonsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PolygonsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PolygonsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PolygonsCompanion(
            id: id,
            plotId: plotId,
            latitude: latitude,
            longitude: longitude,
            orderIndex: orderIndex,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required double latitude,
            required double longitude,
            required int orderIndex,
            required DateTime createdAt,
          }) =>
              PolygonsCompanion.insert(
            id: id,
            plotId: plotId,
            latitude: latitude,
            longitude: longitude,
            orderIndex: orderIndex,
            createdAt: createdAt,
          ),
        ));
}

class $$PolygonsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PolygonsTable> {
  $$PolygonsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get orderIndex => $state.composableBuilder(
      column: $state.table.orderIndex,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PolygonsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PolygonsTable> {
  $$PolygonsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get latitude => $state.composableBuilder(
      column: $state.table.latitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get longitude => $state.composableBuilder(
      column: $state.table.longitude,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get orderIndex => $state.composableBuilder(
      column: $state.table.orderIndex,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$AplicacoesTableCreateCompanionBuilder = AplicacoesCompanion Function({
  Value<int> id,
  required int plotId,
  required String productName,
  required String applicationDate,
  Value<double?> dosage,
  Value<String?> dosageUnit,
  Value<String?> applicationMethod,
  Value<String?> weatherCondition,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$AplicacoesTableUpdateCompanionBuilder = AplicacoesCompanion Function({
  Value<int> id,
  Value<int> plotId,
  Value<String> productName,
  Value<String> applicationDate,
  Value<double?> dosage,
  Value<String?> dosageUnit,
  Value<String?> applicationMethod,
  Value<String?> weatherCondition,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$AplicacoesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AplicacoesTable,
    Aplicacoe,
    $$AplicacoesTableFilterComposer,
    $$AplicacoesTableOrderingComposer,
    $$AplicacoesTableCreateCompanionBuilder,
    $$AplicacoesTableUpdateCompanionBuilder> {
  $$AplicacoesTableTableManager(_$AppDatabase db, $AplicacoesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$AplicacoesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$AplicacoesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> applicationDate = const Value.absent(),
            Value<double?> dosage = const Value.absent(),
            Value<String?> dosageUnit = const Value.absent(),
            Value<String?> applicationMethod = const Value.absent(),
            Value<String?> weatherCondition = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              AplicacoesCompanion(
            id: id,
            plotId: plotId,
            productName: productName,
            applicationDate: applicationDate,
            dosage: dosage,
            dosageUnit: dosageUnit,
            applicationMethod: applicationMethod,
            weatherCondition: weatherCondition,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required String productName,
            required String applicationDate,
            Value<double?> dosage = const Value.absent(),
            Value<String?> dosageUnit = const Value.absent(),
            Value<String?> applicationMethod = const Value.absent(),
            Value<String?> weatherCondition = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              AplicacoesCompanion.insert(
            id: id,
            plotId: plotId,
            productName: productName,
            applicationDate: applicationDate,
            dosage: dosage,
            dosageUnit: dosageUnit,
            applicationMethod: applicationMethod,
            weatherCondition: weatherCondition,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$AplicacoesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $AplicacoesTable> {
  $$AplicacoesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get applicationDate => $state.composableBuilder(
      column: $state.table.applicationDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dosageUnit => $state.composableBuilder(
      column: $state.table.dosageUnit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get applicationMethod => $state.composableBuilder(
      column: $state.table.applicationMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get weatherCondition => $state.composableBuilder(
      column: $state.table.weatherCondition,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$AplicacoesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $AplicacoesTable> {
  $$AplicacoesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get applicationDate => $state.composableBuilder(
      column: $state.table.applicationDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dosageUnit => $state.composableBuilder(
      column: $state.table.dosageUnit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get applicationMethod => $state.composableBuilder(
      column: $state.table.applicationMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get weatherCondition => $state.composableBuilder(
      column: $state.table.weatherCondition,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PrescriptionsTableCreateCompanionBuilder = PrescriptionsCompanion
    Function({
  Value<int> id,
  required int plotId,
  required String prescriptionDate,
  required String prescriptionType,
  required String status,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$PrescriptionsTableUpdateCompanionBuilder = PrescriptionsCompanion
    Function({
  Value<int> id,
  Value<int> plotId,
  Value<String> prescriptionDate,
  Value<String> prescriptionType,
  Value<String> status,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$PrescriptionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrescriptionsTable,
    Prescription,
    $$PrescriptionsTableFilterComposer,
    $$PrescriptionsTableOrderingComposer,
    $$PrescriptionsTableCreateCompanionBuilder,
    $$PrescriptionsTableUpdateCompanionBuilder> {
  $$PrescriptionsTableTableManager(_$AppDatabase db, $PrescriptionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PrescriptionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PrescriptionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<String> prescriptionDate = const Value.absent(),
            Value<String> prescriptionType = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              PrescriptionsCompanion(
            id: id,
            plotId: plotId,
            prescriptionDate: prescriptionDate,
            prescriptionType: prescriptionType,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required String prescriptionDate,
            required String prescriptionType,
            required String status,
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              PrescriptionsCompanion.insert(
            id: id,
            plotId: plotId,
            prescriptionDate: prescriptionDate,
            prescriptionType: prescriptionType,
            status: status,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$PrescriptionsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PrescriptionsTable> {
  $$PrescriptionsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get prescriptionDate => $state.composableBuilder(
      column: $state.table.prescriptionDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get prescriptionType => $state.composableBuilder(
      column: $state.table.prescriptionType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PrescriptionsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PrescriptionsTable> {
  $$PrescriptionsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get prescriptionDate => $state.composableBuilder(
      column: $state.table.prescriptionDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get prescriptionType => $state.composableBuilder(
      column: $state.table.prescriptionType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get status => $state.composableBuilder(
      column: $state.table.status,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$PrescriptionItemsTableCreateCompanionBuilder
    = PrescriptionItemsCompanion Function({
  Value<int> id,
  required int prescriptionId,
  required String productName,
  Value<double?> dosage,
  Value<String?> dosageUnit,
  Value<String?> applicationMethod,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$PrescriptionItemsTableUpdateCompanionBuilder
    = PrescriptionItemsCompanion Function({
  Value<int> id,
  Value<int> prescriptionId,
  Value<String> productName,
  Value<double?> dosage,
  Value<String?> dosageUnit,
  Value<String?> applicationMethod,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$PrescriptionItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrescriptionItemsTable,
    PrescriptionItem,
    $$PrescriptionItemsTableFilterComposer,
    $$PrescriptionItemsTableOrderingComposer,
    $$PrescriptionItemsTableCreateCompanionBuilder,
    $$PrescriptionItemsTableUpdateCompanionBuilder> {
  $$PrescriptionItemsTableTableManager(
      _$AppDatabase db, $PrescriptionItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PrescriptionItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$PrescriptionItemsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> prescriptionId = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<double?> dosage = const Value.absent(),
            Value<String?> dosageUnit = const Value.absent(),
            Value<String?> applicationMethod = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PrescriptionItemsCompanion(
            id: id,
            prescriptionId: prescriptionId,
            productName: productName,
            dosage: dosage,
            dosageUnit: dosageUnit,
            applicationMethod: applicationMethod,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int prescriptionId,
            required String productName,
            Value<double?> dosage = const Value.absent(),
            Value<String?> dosageUnit = const Value.absent(),
            Value<String?> applicationMethod = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              PrescriptionItemsCompanion.insert(
            id: id,
            prescriptionId: prescriptionId,
            productName: productName,
            dosage: dosage,
            dosageUnit: dosageUnit,
            applicationMethod: applicationMethod,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$PrescriptionItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $PrescriptionItemsTable> {
  $$PrescriptionItemsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get prescriptionId => $state.composableBuilder(
      column: $state.table.prescriptionId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get dosageUnit => $state.composableBuilder(
      column: $state.table.dosageUnit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get applicationMethod => $state.composableBuilder(
      column: $state.table.applicationMethod,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PrescriptionItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $PrescriptionItemsTable> {
  $$PrescriptionItemsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get prescriptionId => $state.composableBuilder(
      column: $state.table.prescriptionId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get dosage => $state.composableBuilder(
      column: $state.table.dosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get dosageUnit => $state.composableBuilder(
      column: $state.table.dosageUnit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get applicationMethod => $state.composableBuilder(
      column: $state.table.applicationMethod,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$CalibracaoFertilizantesTableCreateCompanionBuilder
    = CalibracaoFertilizantesCompanion Function({
  Value<int> id,
  required int plotId,
  required String fertilizerName,
  required String calibrationDate,
  required double targetDosage,
  Value<double?> actualDosage,
  Value<double?> calibrationFactor,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$CalibracaoFertilizantesTableUpdateCompanionBuilder
    = CalibracaoFertilizantesCompanion Function({
  Value<int> id,
  Value<int> plotId,
  Value<String> fertilizerName,
  Value<String> calibrationDate,
  Value<double> targetDosage,
  Value<double?> actualDosage,
  Value<double?> calibrationFactor,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$CalibracaoFertilizantesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CalibracaoFertilizantesTable,
    CalibracaoFertilizante,
    $$CalibracaoFertilizantesTableFilterComposer,
    $$CalibracaoFertilizantesTableOrderingComposer,
    $$CalibracaoFertilizantesTableCreateCompanionBuilder,
    $$CalibracaoFertilizantesTableUpdateCompanionBuilder> {
  $$CalibracaoFertilizantesTableTableManager(
      _$AppDatabase db, $CalibracaoFertilizantesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$CalibracaoFertilizantesTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$CalibracaoFertilizantesTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<String> fertilizerName = const Value.absent(),
            Value<String> calibrationDate = const Value.absent(),
            Value<double> targetDosage = const Value.absent(),
            Value<double?> actualDosage = const Value.absent(),
            Value<double?> calibrationFactor = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              CalibracaoFertilizantesCompanion(
            id: id,
            plotId: plotId,
            fertilizerName: fertilizerName,
            calibrationDate: calibrationDate,
            targetDosage: targetDosage,
            actualDosage: actualDosage,
            calibrationFactor: calibrationFactor,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required String fertilizerName,
            required String calibrationDate,
            required double targetDosage,
            Value<double?> actualDosage = const Value.absent(),
            Value<double?> calibrationFactor = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              CalibracaoFertilizantesCompanion.insert(
            id: id,
            plotId: plotId,
            fertilizerName: fertilizerName,
            calibrationDate: calibrationDate,
            targetDosage: targetDosage,
            actualDosage: actualDosage,
            calibrationFactor: calibrationFactor,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$CalibracaoFertilizantesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $CalibracaoFertilizantesTable> {
  $$CalibracaoFertilizantesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fertilizerName => $state.composableBuilder(
      column: $state.table.fertilizerName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get calibrationDate => $state.composableBuilder(
      column: $state.table.calibrationDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get targetDosage => $state.composableBuilder(
      column: $state.table.targetDosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get actualDosage => $state.composableBuilder(
      column: $state.table.actualDosage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get calibrationFactor => $state.composableBuilder(
      column: $state.table.calibrationFactor,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$CalibracaoFertilizantesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $CalibracaoFertilizantesTable> {
  $$CalibracaoFertilizantesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fertilizerName => $state.composableBuilder(
      column: $state.table.fertilizerName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get calibrationDate => $state.composableBuilder(
      column: $state.table.calibrationDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get targetDosage => $state.composableBuilder(
      column: $state.table.targetDosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get actualDosage => $state.composableBuilder(
      column: $state.table.actualDosage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get calibrationFactor => $state.composableBuilder(
      column: $state.table.calibrationFactor,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$EstoqueTableCreateCompanionBuilder = EstoqueCompanion Function({
  Value<int> id,
  required String productName,
  required String productType,
  required double currentQuantity,
  required String unit,
  Value<double?> minQuantity,
  Value<double?> maxQuantity,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$EstoqueTableUpdateCompanionBuilder = EstoqueCompanion Function({
  Value<int> id,
  Value<String> productName,
  Value<String> productType,
  Value<double> currentQuantity,
  Value<String> unit,
  Value<double?> minQuantity,
  Value<double?> maxQuantity,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$EstoqueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EstoqueTable,
    EstoqueData,
    $$EstoqueTableFilterComposer,
    $$EstoqueTableOrderingComposer,
    $$EstoqueTableCreateCompanionBuilder,
    $$EstoqueTableUpdateCompanionBuilder> {
  $$EstoqueTableTableManager(_$AppDatabase db, $EstoqueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$EstoqueTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$EstoqueTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> productType = const Value.absent(),
            Value<double> currentQuantity = const Value.absent(),
            Value<String> unit = const Value.absent(),
            Value<double?> minQuantity = const Value.absent(),
            Value<double?> maxQuantity = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              EstoqueCompanion(
            id: id,
            productName: productName,
            productType: productType,
            currentQuantity: currentQuantity,
            unit: unit,
            minQuantity: minQuantity,
            maxQuantity: maxQuantity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String productName,
            required String productType,
            required double currentQuantity,
            required String unit,
            Value<double?> minQuantity = const Value.absent(),
            Value<double?> maxQuantity = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              EstoqueCompanion.insert(
            id: id,
            productName: productName,
            productType: productType,
            currentQuantity: currentQuantity,
            unit: unit,
            minQuantity: minQuantity,
            maxQuantity: maxQuantity,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$EstoqueTableFilterComposer
    extends FilterComposer<_$AppDatabase, $EstoqueTable> {
  $$EstoqueTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get productType => $state.composableBuilder(
      column: $state.table.productType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get currentQuantity => $state.composableBuilder(
      column: $state.table.currentQuantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get minQuantity => $state.composableBuilder(
      column: $state.table.minQuantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get maxQuantity => $state.composableBuilder(
      column: $state.table.maxQuantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$EstoqueTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $EstoqueTable> {
  $$EstoqueTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productName => $state.composableBuilder(
      column: $state.table.productName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get productType => $state.composableBuilder(
      column: $state.table.productType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get currentQuantity => $state.composableBuilder(
      column: $state.table.currentQuantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get unit => $state.composableBuilder(
      column: $state.table.unit,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get minQuantity => $state.composableBuilder(
      column: $state.table.minQuantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get maxQuantity => $state.composableBuilder(
      column: $state.table.maxQuantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InventoryItemsTableCreateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  required int stockId,
  required double quantity,
  Value<double?> unitCost,
  Value<String?> supplier,
  Value<String?> batchNumber,
  Value<String?> expiryDate,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$InventoryItemsTableUpdateCompanionBuilder = InventoryItemsCompanion
    Function({
  Value<int> id,
  Value<int> stockId,
  Value<double> quantity,
  Value<double?> unitCost,
  Value<String?> supplier,
  Value<String?> batchNumber,
  Value<String?> expiryDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$InventoryItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryItemsTable,
    InventoryItem,
    $$InventoryItemsTableFilterComposer,
    $$InventoryItemsTableOrderingComposer,
    $$InventoryItemsTableCreateCompanionBuilder,
    $$InventoryItemsTableUpdateCompanionBuilder> {
  $$InventoryItemsTableTableManager(
      _$AppDatabase db, $InventoryItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InventoryItemsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$InventoryItemsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> stockId = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double?> unitCost = const Value.absent(),
            Value<String?> supplier = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> expiryDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InventoryItemsCompanion(
            id: id,
            stockId: stockId,
            quantity: quantity,
            unitCost: unitCost,
            supplier: supplier,
            batchNumber: batchNumber,
            expiryDate: expiryDate,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int stockId,
            required double quantity,
            Value<double?> unitCost = const Value.absent(),
            Value<String?> supplier = const Value.absent(),
            Value<String?> batchNumber = const Value.absent(),
            Value<String?> expiryDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              InventoryItemsCompanion.insert(
            id: id,
            stockId: stockId,
            quantity: quantity,
            unitCost: unitCost,
            supplier: supplier,
            batchNumber: batchNumber,
            expiryDate: expiryDate,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$InventoryItemsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get stockId => $state.composableBuilder(
      column: $state.table.stockId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get unitCost => $state.composableBuilder(
      column: $state.table.unitCost,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get supplier => $state.composableBuilder(
      column: $state.table.supplier,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InventoryItemsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get stockId => $state.composableBuilder(
      column: $state.table.stockId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get unitCost => $state.composableBuilder(
      column: $state.table.unitCost,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get supplier => $state.composableBuilder(
      column: $state.table.supplier,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get batchNumber => $state.composableBuilder(
      column: $state.table.batchNumber,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get expiryDate => $state.composableBuilder(
      column: $state.table.expiryDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$InventoryMovementsTableCreateCompanionBuilder
    = InventoryMovementsCompanion Function({
  Value<int> id,
  required int stockId,
  required String movementType,
  required double quantity,
  Value<double?> unitCost,
  Value<String?> reference,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$InventoryMovementsTableUpdateCompanionBuilder
    = InventoryMovementsCompanion Function({
  Value<int> id,
  Value<int> stockId,
  Value<String> movementType,
  Value<double> quantity,
  Value<double?> unitCost,
  Value<String?> reference,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$InventoryMovementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InventoryMovementsTable,
    InventoryMovement,
    $$InventoryMovementsTableFilterComposer,
    $$InventoryMovementsTableOrderingComposer,
    $$InventoryMovementsTableCreateCompanionBuilder,
    $$InventoryMovementsTableUpdateCompanionBuilder> {
  $$InventoryMovementsTableTableManager(
      _$AppDatabase db, $InventoryMovementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$InventoryMovementsTableFilterComposer(ComposerState(db, table)),
          orderingComposer: $$InventoryMovementsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> stockId = const Value.absent(),
            Value<String> movementType = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double?> unitCost = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              InventoryMovementsCompanion(
            id: id,
            stockId: stockId,
            movementType: movementType,
            quantity: quantity,
            unitCost: unitCost,
            reference: reference,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int stockId,
            required String movementType,
            required double quantity,
            Value<double?> unitCost = const Value.absent(),
            Value<String?> reference = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              InventoryMovementsCompanion.insert(
            id: id,
            stockId: stockId,
            movementType: movementType,
            quantity: quantity,
            unitCost: unitCost,
            reference: reference,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$InventoryMovementsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get stockId => $state.composableBuilder(
      column: $state.table.stockId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get movementType => $state.composableBuilder(
      column: $state.table.movementType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get unitCost => $state.composableBuilder(
      column: $state.table.unitCost,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get reference => $state.composableBuilder(
      column: $state.table.reference,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$InventoryMovementsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $InventoryMovementsTable> {
  $$InventoryMovementsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get stockId => $state.composableBuilder(
      column: $state.table.stockId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get movementType => $state.composableBuilder(
      column: $state.table.movementType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get quantity => $state.composableBuilder(
      column: $state.table.quantity,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get unitCost => $state.composableBuilder(
      column: $state.table.unitCost,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get reference => $state.composableBuilder(
      column: $state.table.reference,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SoilAnalysisTableCreateCompanionBuilder = SoilAnalysisCompanion
    Function({
  Value<int> id,
  required int plotId,
  required String analysisDate,
  Value<double?> phLevel,
  Value<double?> organicMatter,
  Value<double?> phosphorus,
  Value<double?> potassium,
  Value<double?> calcium,
  Value<double?> magnesium,
  Value<double?> sulfur,
  Value<double?> boron,
  Value<double?> copper,
  Value<double?> iron,
  Value<double?> manganese,
  Value<double?> zinc,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$SoilAnalysisTableUpdateCompanionBuilder = SoilAnalysisCompanion
    Function({
  Value<int> id,
  Value<int> plotId,
  Value<String> analysisDate,
  Value<double?> phLevel,
  Value<double?> organicMatter,
  Value<double?> phosphorus,
  Value<double?> potassium,
  Value<double?> calcium,
  Value<double?> magnesium,
  Value<double?> sulfur,
  Value<double?> boron,
  Value<double?> copper,
  Value<double?> iron,
  Value<double?> manganese,
  Value<double?> zinc,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$SoilAnalysisTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SoilAnalysisTable,
    SoilAnalysi,
    $$SoilAnalysisTableFilterComposer,
    $$SoilAnalysisTableOrderingComposer,
    $$SoilAnalysisTableCreateCompanionBuilder,
    $$SoilAnalysisTableUpdateCompanionBuilder> {
  $$SoilAnalysisTableTableManager(_$AppDatabase db, $SoilAnalysisTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SoilAnalysisTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SoilAnalysisTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<String> analysisDate = const Value.absent(),
            Value<double?> phLevel = const Value.absent(),
            Value<double?> organicMatter = const Value.absent(),
            Value<double?> phosphorus = const Value.absent(),
            Value<double?> potassium = const Value.absent(),
            Value<double?> calcium = const Value.absent(),
            Value<double?> magnesium = const Value.absent(),
            Value<double?> sulfur = const Value.absent(),
            Value<double?> boron = const Value.absent(),
            Value<double?> copper = const Value.absent(),
            Value<double?> iron = const Value.absent(),
            Value<double?> manganese = const Value.absent(),
            Value<double?> zinc = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              SoilAnalysisCompanion(
            id: id,
            plotId: plotId,
            analysisDate: analysisDate,
            phLevel: phLevel,
            organicMatter: organicMatter,
            phosphorus: phosphorus,
            potassium: potassium,
            calcium: calcium,
            magnesium: magnesium,
            sulfur: sulfur,
            boron: boron,
            copper: copper,
            iron: iron,
            manganese: manganese,
            zinc: zinc,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required String analysisDate,
            Value<double?> phLevel = const Value.absent(),
            Value<double?> organicMatter = const Value.absent(),
            Value<double?> phosphorus = const Value.absent(),
            Value<double?> potassium = const Value.absent(),
            Value<double?> calcium = const Value.absent(),
            Value<double?> magnesium = const Value.absent(),
            Value<double?> sulfur = const Value.absent(),
            Value<double?> boron = const Value.absent(),
            Value<double?> copper = const Value.absent(),
            Value<double?> iron = const Value.absent(),
            Value<double?> manganese = const Value.absent(),
            Value<double?> zinc = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              SoilAnalysisCompanion.insert(
            id: id,
            plotId: plotId,
            analysisDate: analysisDate,
            phLevel: phLevel,
            organicMatter: organicMatter,
            phosphorus: phosphorus,
            potassium: potassium,
            calcium: calcium,
            magnesium: magnesium,
            sulfur: sulfur,
            boron: boron,
            copper: copper,
            iron: iron,
            manganese: manganese,
            zinc: zinc,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$SoilAnalysisTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SoilAnalysisTable> {
  $$SoilAnalysisTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get analysisDate => $state.composableBuilder(
      column: $state.table.analysisDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get phLevel => $state.composableBuilder(
      column: $state.table.phLevel,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get organicMatter => $state.composableBuilder(
      column: $state.table.organicMatter,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get phosphorus => $state.composableBuilder(
      column: $state.table.phosphorus,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get potassium => $state.composableBuilder(
      column: $state.table.potassium,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get calcium => $state.composableBuilder(
      column: $state.table.calcium,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get magnesium => $state.composableBuilder(
      column: $state.table.magnesium,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get sulfur => $state.composableBuilder(
      column: $state.table.sulfur,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get boron => $state.composableBuilder(
      column: $state.table.boron,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get copper => $state.composableBuilder(
      column: $state.table.copper,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get iron => $state.composableBuilder(
      column: $state.table.iron,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get manganese => $state.composableBuilder(
      column: $state.table.manganese,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get zinc => $state.composableBuilder(
      column: $state.table.zinc,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SoilAnalysisTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SoilAnalysisTable> {
  $$SoilAnalysisTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get analysisDate => $state.composableBuilder(
      column: $state.table.analysisDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get phLevel => $state.composableBuilder(
      column: $state.table.phLevel,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get organicMatter => $state.composableBuilder(
      column: $state.table.organicMatter,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get phosphorus => $state.composableBuilder(
      column: $state.table.phosphorus,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get potassium => $state.composableBuilder(
      column: $state.table.potassium,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get calcium => $state.composableBuilder(
      column: $state.table.calcium,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get magnesium => $state.composableBuilder(
      column: $state.table.magnesium,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get sulfur => $state.composableBuilder(
      column: $state.table.sulfur,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get boron => $state.composableBuilder(
      column: $state.table.boron,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get copper => $state.composableBuilder(
      column: $state.table.copper,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get iron => $state.composableBuilder(
      column: $state.table.iron,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get manganese => $state.composableBuilder(
      column: $state.table.manganese,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get zinc => $state.composableBuilder(
      column: $state.table.zinc,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$SoilSamplesTableCreateCompanionBuilder = SoilSamplesCompanion
    Function({
  Value<int> id,
  required int analysisId,
  required double sampleDepth,
  Value<String?> sampleLocation,
  required String sampleDate,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$SoilSamplesTableUpdateCompanionBuilder = SoilSamplesCompanion
    Function({
  Value<int> id,
  Value<int> analysisId,
  Value<double> sampleDepth,
  Value<String?> sampleLocation,
  Value<String> sampleDate,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$SoilSamplesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SoilSamplesTable,
    SoilSample,
    $$SoilSamplesTableFilterComposer,
    $$SoilSamplesTableOrderingComposer,
    $$SoilSamplesTableCreateCompanionBuilder,
    $$SoilSamplesTableUpdateCompanionBuilder> {
  $$SoilSamplesTableTableManager(_$AppDatabase db, $SoilSamplesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$SoilSamplesTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$SoilSamplesTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> analysisId = const Value.absent(),
            Value<double> sampleDepth = const Value.absent(),
            Value<String?> sampleLocation = const Value.absent(),
            Value<String> sampleDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              SoilSamplesCompanion(
            id: id,
            analysisId: analysisId,
            sampleDepth: sampleDepth,
            sampleLocation: sampleLocation,
            sampleDate: sampleDate,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int analysisId,
            required double sampleDepth,
            Value<String?> sampleLocation = const Value.absent(),
            required String sampleDate,
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              SoilSamplesCompanion.insert(
            id: id,
            analysisId: analysisId,
            sampleDepth: sampleDepth,
            sampleLocation: sampleLocation,
            sampleDate: sampleDate,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$SoilSamplesTableFilterComposer
    extends FilterComposer<_$AppDatabase, $SoilSamplesTable> {
  $$SoilSamplesTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get analysisId => $state.composableBuilder(
      column: $state.table.analysisId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get sampleDepth => $state.composableBuilder(
      column: $state.table.sampleDepth,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sampleLocation => $state.composableBuilder(
      column: $state.table.sampleLocation,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get sampleDate => $state.composableBuilder(
      column: $state.table.sampleDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$SoilSamplesTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $SoilSamplesTable> {
  $$SoilSamplesTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get analysisId => $state.composableBuilder(
      column: $state.table.analysisId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get sampleDepth => $state.composableBuilder(
      column: $state.table.sampleDepth,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sampleLocation => $state.composableBuilder(
      column: $state.table.sampleLocation,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get sampleDate => $state.composableBuilder(
      column: $state.table.sampleDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$GerminationTestsTableCreateCompanionBuilder
    = GerminationTestsCompanion Function({
  Value<int> id,
  required int plotId,
  required String testDate,
  required String seedVariety,
  Value<String?> seedBatch,
  required String testType,
  required int initialSeedCount,
  Value<int?> finalGerminationCount,
  Value<double?> germinationPercentage,
  Value<String?> notes,
  required DateTime createdAt,
  required DateTime updatedAt,
});
typedef $$GerminationTestsTableUpdateCompanionBuilder
    = GerminationTestsCompanion Function({
  Value<int> id,
  Value<int> plotId,
  Value<String> testDate,
  Value<String> seedVariety,
  Value<String?> seedBatch,
  Value<String> testType,
  Value<int> initialSeedCount,
  Value<int?> finalGerminationCount,
  Value<double?> germinationPercentage,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
});

class $$GerminationTestsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GerminationTestsTable,
    GerminationTest,
    $$GerminationTestsTableFilterComposer,
    $$GerminationTestsTableOrderingComposer,
    $$GerminationTestsTableCreateCompanionBuilder,
    $$GerminationTestsTableUpdateCompanionBuilder> {
  $$GerminationTestsTableTableManager(
      _$AppDatabase db, $GerminationTestsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$GerminationTestsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$GerminationTestsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plotId = const Value.absent(),
            Value<String> testDate = const Value.absent(),
            Value<String> seedVariety = const Value.absent(),
            Value<String?> seedBatch = const Value.absent(),
            Value<String> testType = const Value.absent(),
            Value<int> initialSeedCount = const Value.absent(),
            Value<int?> finalGerminationCount = const Value.absent(),
            Value<double?> germinationPercentage = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
          }) =>
              GerminationTestsCompanion(
            id: id,
            plotId: plotId,
            testDate: testDate,
            seedVariety: seedVariety,
            seedBatch: seedBatch,
            testType: testType,
            initialSeedCount: initialSeedCount,
            finalGerminationCount: finalGerminationCount,
            germinationPercentage: germinationPercentage,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plotId,
            required String testDate,
            required String seedVariety,
            Value<String?> seedBatch = const Value.absent(),
            required String testType,
            required int initialSeedCount,
            Value<int?> finalGerminationCount = const Value.absent(),
            Value<double?> germinationPercentage = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
          }) =>
              GerminationTestsCompanion.insert(
            id: id,
            plotId: plotId,
            testDate: testDate,
            seedVariety: seedVariety,
            seedBatch: seedBatch,
            testType: testType,
            initialSeedCount: initialSeedCount,
            finalGerminationCount: finalGerminationCount,
            germinationPercentage: germinationPercentage,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        ));
}

class $$GerminationTestsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $GerminationTestsTable> {
  $$GerminationTestsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get testDate => $state.composableBuilder(
      column: $state.table.testDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get seedVariety => $state.composableBuilder(
      column: $state.table.seedVariety,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get seedBatch => $state.composableBuilder(
      column: $state.table.seedBatch,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get testType => $state.composableBuilder(
      column: $state.table.testType,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get initialSeedCount => $state.composableBuilder(
      column: $state.table.initialSeedCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get finalGerminationCount => $state.composableBuilder(
      column: $state.table.finalGerminationCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<double> get germinationPercentage => $state.composableBuilder(
      column: $state.table.germinationPercentage,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$GerminationTestsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $GerminationTestsTable> {
  $$GerminationTestsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get plotId => $state.composableBuilder(
      column: $state.table.plotId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get testDate => $state.composableBuilder(
      column: $state.table.testDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get seedVariety => $state.composableBuilder(
      column: $state.table.seedVariety,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get seedBatch => $state.composableBuilder(
      column: $state.table.seedBatch,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get testType => $state.composableBuilder(
      column: $state.table.testType,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get initialSeedCount => $state.composableBuilder(
      column: $state.table.initialSeedCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get finalGerminationCount => $state.composableBuilder(
      column: $state.table.finalGerminationCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<double> get germinationPercentage => $state.composableBuilder(
      column: $state.table.germinationPercentage,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

typedef $$GerminationDailyRecordsTableCreateCompanionBuilder
    = GerminationDailyRecordsCompanion Function({
  Value<int> id,
  required int testId,
  required String recordDate,
  required int germinatedCount,
  Value<String?> notes,
  required DateTime createdAt,
});
typedef $$GerminationDailyRecordsTableUpdateCompanionBuilder
    = GerminationDailyRecordsCompanion Function({
  Value<int> id,
  Value<int> testId,
  Value<String> recordDate,
  Value<int> germinatedCount,
  Value<String?> notes,
  Value<DateTime> createdAt,
});

class $$GerminationDailyRecordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GerminationDailyRecordsTable,
    GerminationDailyRecord,
    $$GerminationDailyRecordsTableFilterComposer,
    $$GerminationDailyRecordsTableOrderingComposer,
    $$GerminationDailyRecordsTableCreateCompanionBuilder,
    $$GerminationDailyRecordsTableUpdateCompanionBuilder> {
  $$GerminationDailyRecordsTableTableManager(
      _$AppDatabase db, $GerminationDailyRecordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$GerminationDailyRecordsTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$GerminationDailyRecordsTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> testId = const Value.absent(),
            Value<String> recordDate = const Value.absent(),
            Value<int> germinatedCount = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              GerminationDailyRecordsCompanion(
            id: id,
            testId: testId,
            recordDate: recordDate,
            germinatedCount: germinatedCount,
            notes: notes,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int testId,
            required String recordDate,
            required int germinatedCount,
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
          }) =>
              GerminationDailyRecordsCompanion.insert(
            id: id,
            testId: testId,
            recordDate: recordDate,
            germinatedCount: germinatedCount,
            notes: notes,
            createdAt: createdAt,
          ),
        ));
}

class $$GerminationDailyRecordsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $GerminationDailyRecordsTable> {
  $$GerminationDailyRecordsTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get testId => $state.composableBuilder(
      column: $state.table.testId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get recordDate => $state.composableBuilder(
      column: $state.table.recordDate,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get germinatedCount => $state.composableBuilder(
      column: $state.table.germinatedCount,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$GerminationDailyRecordsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $GerminationDailyRecordsTable> {
  $$GerminationDailyRecordsTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get testId => $state.composableBuilder(
      column: $state.table.testId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get recordDate => $state.composableBuilder(
      column: $state.table.recordDate,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get germinatedCount => $state.composableBuilder(
      column: $state.table.germinatedCount,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get notes => $state.composableBuilder(
      column: $state.table.notes,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CulturasTableTableManager get culturas =>
      $$CulturasTableTableManager(_db, _db.culturas);
  $$VariedadesTableTableManager get variedades =>
      $$VariedadesTableTableManager(_db, _db.variedades);
  $$OrganismosTableTableManager get organismos =>
      $$OrganismosTableTableManager(_db, _db.organismos);
  $$CulturaOrganismoTableTableManager get culturaOrganismo =>
      $$CulturaOrganismoTableTableManager(_db, _db.culturaOrganismo);
  $$FotosTableTableManager get fotos =>
      $$FotosTableTableManager(_db, _db.fotos);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$SyncHistoryTableTableManager get syncHistory =>
      $$SyncHistoryTableTableManager(_db, _db.syncHistory);
  $$MonitoringTableTableManager get monitoring =>
      $$MonitoringTableTableManager(_db, _db.monitoring);
  $$MonitoringPointsTableTableManager get monitoringPoints =>
      $$MonitoringPointsTableTableManager(_db, _db.monitoringPoints);
  $$InfestacoesTableTableManager get infestacoes =>
      $$InfestacoesTableTableManager(_db, _db.infestacoes);
  $$PlotsTableTableManager get plots =>
      $$PlotsTableTableManager(_db, _db.plots);
  $$PolygonsTableTableManager get polygons =>
      $$PolygonsTableTableManager(_db, _db.polygons);
  $$AplicacoesTableTableManager get aplicacoes =>
      $$AplicacoesTableTableManager(_db, _db.aplicacoes);
  $$PrescriptionsTableTableManager get prescriptions =>
      $$PrescriptionsTableTableManager(_db, _db.prescriptions);
  $$PrescriptionItemsTableTableManager get prescriptionItems =>
      $$PrescriptionItemsTableTableManager(_db, _db.prescriptionItems);
  $$CalibracaoFertilizantesTableTableManager get calibracaoFertilizantes =>
      $$CalibracaoFertilizantesTableTableManager(
          _db, _db.calibracaoFertilizantes);
  $$EstoqueTableTableManager get estoque =>
      $$EstoqueTableTableManager(_db, _db.estoque);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$InventoryMovementsTableTableManager get inventoryMovements =>
      $$InventoryMovementsTableTableManager(_db, _db.inventoryMovements);
  $$SoilAnalysisTableTableManager get soilAnalysis =>
      $$SoilAnalysisTableTableManager(_db, _db.soilAnalysis);
  $$SoilSamplesTableTableManager get soilSamples =>
      $$SoilSamplesTableTableManager(_db, _db.soilSamples);
  $$GerminationTestsTableTableManager get germinationTests =>
      $$GerminationTestsTableTableManager(_db, _db.germinationTests);
  $$GerminationDailyRecordsTableTableManager get germinationDailyRecords =>
      $$GerminationDailyRecordsTableTableManager(
          _db, _db.germinationDailyRecords);
}
