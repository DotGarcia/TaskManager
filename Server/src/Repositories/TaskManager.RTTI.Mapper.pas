unit TaskManager.RTTI.Mapper;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
  System.Generics.Collections,
  TaskManager.Attributes, TaskManager.Entities.Base;

type
  /// <summary>
  /// Informacoes de mapeamento de uma coluna extraidas via RTTI.
  /// </summary>
  TColumnMapping = record
    PropertyName: string;
    ColumnName: string;
    IsPrimaryKey: Boolean;
    IsAutoIncrement: Boolean;
    IsReadOnly: Boolean;
    RttiProperty: TRttiProperty;
  end;

  /// <summary>
  /// Mapper RTTI que le atributos customizados das entidades e gera
  /// queries SQL dinamicamente, eliminando SQL manual por entidade.
  /// Utiliza TRttiContext para iterar sobre propriedades e seus atributos.
  /// </summary>
  TRttiMapper = class
  private
    class var FContext: TRttiContext;
  public
    /// Retorna o nome da tabela mapeada via [TableName('...')] na classe
    class function GetTableName(AEntityClass: TClass): string;

    /// Retorna a lista de mapeamentos coluna <-> propriedade via RTTI
    class function GetColumnMappings(AEntityClass: TClass): TArray<TColumnMapping>;

    /// Gera um INSERT INTO dinamico baseado nos atributos RTTI
    class function BuildInsertSQL(AEntityClass: TClass): string;

    /// Gera um UPDATE SET ... WHERE Id = :Id dinamico
    class function BuildUpdateSQL(AEntityClass: TClass): string;

    /// Gera um SELECT * FROM tabela WHERE Id = :Id
    class function BuildSelectByIdSQL(AEntityClass: TClass): string;

    /// Gera um SELECT * FROM tabela (todas as linhas)
    class function BuildSelectAllSQL(AEntityClass: TClass): string;

    /// Gera um DELETE FROM tabela WHERE Id = :Id
    class function BuildDeleteSQL(AEntityClass: TClass): string;

    /// Le o valor de uma propriedade de uma entidade via RTTI
    class function GetPropertyValue(AEntity: TBaseEntity;
      const APropName: string): TValue;

    /// Define o valor de uma propriedade via RTTI
    class procedure SetPropertyValue(AEntity: TBaseEntity;
      const APropName: string; const AValue: TValue);
  end;

implementation

{ TRttiMapper }

class function TRttiMapper.GetTableName(AEntityClass: TClass): string;
var
  LRttiType: TRttiType;
  LAttr: TCustomAttribute;
begin
  Result := AEntityClass.ClassName; // fallback: nome da classe
  LRttiType := FContext.GetType(AEntityClass);
  if Assigned(LRttiType) then
  begin
    for LAttr in LRttiType.GetAttributes do
    begin
      if LAttr is TableNameAttribute then
      begin
        Result := TableNameAttribute(LAttr).Name;
        Exit;
      end;
    end;
  end;
end;

class function TRttiMapper.GetColumnMappings(AEntityClass: TClass): TArray<TColumnMapping>;
var
  LRttiType: TRttiType;
  LProp: TRttiProperty;
  LAttr: TCustomAttribute;
  LMapping: TColumnMapping;
  LList: TList<TColumnMapping>;
begin
  LList := TList<TColumnMapping>.Create;
  try
    LRttiType := FContext.GetType(AEntityClass);
    if Assigned(LRttiType) then
    begin
      for LProp in LRttiType.GetProperties do
      begin
        LMapping := Default(TColumnMapping);
        LMapping.PropertyName := LProp.Name;
        LMapping.RttiProperty := LProp;

        // Verificar atributos de cada propriedade
        for LAttr in LProp.GetAttributes do
        begin
          if LAttr is ColumnAttribute then
            LMapping.ColumnName := ColumnAttribute(LAttr).Name
          else if LAttr is PrimaryKeyAttribute then
            LMapping.IsPrimaryKey := True
          else if LAttr is AutoIncrementAttribute then
            LMapping.IsAutoIncrement := True
          else if LAttr is ReadOnlyFieldAttribute then
            LMapping.IsReadOnly := True;
        end;

        // So incluir propriedades que tem [Column] mapeado
        if LMapping.ColumnName <> '' then
          LList.Add(LMapping);
      end;
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TRttiMapper.BuildInsertSQL(AEntityClass: TClass): string;
var
  LTable: string;
  LMappings: TArray<TColumnMapping>;
  LColumns, LParams: string;
  LMapping: TColumnMapping;
begin
  LTable := GetTableName(AEntityClass);
  LMappings := GetColumnMappings(AEntityClass);

  LColumns := '';
  LParams := '';

  for LMapping in LMappings do
  begin
    // Pula campos auto-increment e read-only no INSERT
    if LMapping.IsAutoIncrement or LMapping.IsReadOnly then
      Continue;

    if LColumns <> '' then
    begin
      LColumns := LColumns + ', ';
      LParams := LParams + ', ';
    end;
    LColumns := LColumns + '[' + LMapping.ColumnName + ']';
    LParams := LParams + ':' + LMapping.PropertyName;
  end;

  Result := Format('INSERT INTO [%s] (%s) VALUES (%s)', [LTable, LColumns, LParams]);
end;

class function TRttiMapper.BuildUpdateSQL(AEntityClass: TClass): string;
var
  LTable: string;
  LMappings: TArray<TColumnMapping>;
  LSets, LPkColumn: string;
  LMapping: TColumnMapping;
begin
  LTable := GetTableName(AEntityClass);
  LMappings := GetColumnMappings(AEntityClass);

  LSets := '';
  LPkColumn := 'Id'; // fallback

  for LMapping in LMappings do
  begin
    if LMapping.IsPrimaryKey then
    begin
      LPkColumn := LMapping.ColumnName;
      Continue; // PK nao entra no SET
    end;

    if LMapping.IsAutoIncrement or LMapping.IsReadOnly then
      Continue;

    if LSets <> '' then
      LSets := LSets + ', ';
    LSets := LSets + '[' + LMapping.ColumnName + '] = :' + LMapping.PropertyName;
  end;

  Result := Format('UPDATE [%s] SET %s WHERE [%s] = :Id', [LTable, LSets, LPkColumn]);
end;

class function TRttiMapper.BuildSelectByIdSQL(AEntityClass: TClass): string;
var
  LTable, LPkColumn: string;
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LTable := GetTableName(AEntityClass);
  LMappings := GetColumnMappings(AEntityClass);

  LPkColumn := 'Id';
  for LMapping in LMappings do
  begin
    if LMapping.IsPrimaryKey then
    begin
      LPkColumn := LMapping.ColumnName;
      Break;
    end;
  end;

  Result := Format('SELECT * FROM [%s] WHERE [%s] = :Id', [LTable, LPkColumn]);
end;

class function TRttiMapper.BuildSelectAllSQL(AEntityClass: TClass): string;
begin
  Result := Format('SELECT * FROM [%s]', [GetTableName(AEntityClass)]);
end;

class function TRttiMapper.BuildDeleteSQL(AEntityClass: TClass): string;
var
  LTable, LPkColumn: string;
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LTable := GetTableName(AEntityClass);
  LMappings := GetColumnMappings(AEntityClass);

  LPkColumn := 'Id';
  for LMapping in LMappings do
  begin
    if LMapping.IsPrimaryKey then
    begin
      LPkColumn := LMapping.ColumnName;
      Break;
    end;
  end;

  Result := Format('DELETE FROM [%s] WHERE [%s] = :Id', [LTable, LPkColumn]);
end;

class function TRttiMapper.GetPropertyValue(AEntity: TBaseEntity;
  const APropName: string): TValue;
var
  LRttiType: TRttiType;
  LProp: TRttiProperty;
begin
  LRttiType := FContext.GetType(AEntity.ClassType);
  LProp := LRttiType.GetProperty(APropName);
  if Assigned(LProp) then
    Result := LProp.GetValue(AEntity)
  else
    Result := TValue.Empty;
end;

class procedure TRttiMapper.SetPropertyValue(AEntity: TBaseEntity;
  const APropName: string; const AValue: TValue);
var
  LRttiType: TRttiType;
  LProp: TRttiProperty;
begin
  LRttiType := FContext.GetType(AEntity.ClassType);
  LProp := LRttiType.GetProperty(APropName);
  if Assigned(LProp) and LProp.IsWritable then
    LProp.SetValue(AEntity, AValue);
end;

end.
