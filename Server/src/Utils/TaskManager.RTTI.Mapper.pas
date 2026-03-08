unit TaskManager.RTTI.Mapper;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo,
  System.Generics.Collections,
  TaskManager.Attributes;

type
  /// <summary>
  /// Informação de mapeamento de uma coluna extraída via RTTI.
  /// </summary>
  TColumnMapping = record
    PropertyName: string;
    ColumnName: string;
    IsPrimaryKey: Boolean;
    IsAutoIncrement: Boolean;
    IsReadOnly: Boolean;
    PropertyType: TRttiType;
  end;

  /// <summary>
  /// Utiliza RTTI para automatizar o mapeamento objeto-relacional.
  /// Lê atributos customizados ([TableName], [Column], [PrimaryKey], etc.)
  /// e gera queries SQL dinamicamente.
  /// </summary>
  TRttiMapper = class
  private
    class var FContext: TRttiContext;
  public
    class function GetTableName<T: class>: string;
    class function GetColumns<T: class>: TArray<TColumnMapping>;
    class function GetPrimaryKeyColumn<T: class>: TColumnMapping;

    /// Gera INSERT com parâmetros nomeados (:param)
    class function GenerateInsertSQL<T: class>: string;

    /// Gera UPDATE com parâmetros nomeados
    class function GenerateUpdateSQL<T: class>: string;

    /// Gera SELECT * FROM tabela WHERE PK = :Id
    class function GenerateSelectByIdSQL<T: class>: string;

    /// Gera SELECT * FROM tabela
    class function GenerateSelectAllSQL<T: class>: string;

    /// Gera DELETE FROM tabela WHERE PK = :Id
    class function GenerateDeleteSQL<T: class>: string;

    /// Gera SELECT * FROM tabela WHERE coluna = :valor
    class function GenerateSelectWhereSQL<T: class>(const AColumnName: string): string;

    /// Extrai o valor de uma propriedade de um objeto via RTTI
    class function GetPropertyValue(AObject: TObject; const APropName: string): TValue;

    /// Define o valor de uma propriedade de um objeto via RTTI
    class procedure SetPropertyValue(AObject: TObject; const APropName: string; AValue: TValue);
  end;

implementation

{ TRttiMapper }

class function TRttiMapper.GetTableName<T>: string;
var
  LType: TRttiType;
  LAttr: TCustomAttribute;
begin
  Result := '';
  LType := FContext.GetType(TypeInfo(T));
  if LType = nil then
    raise Exception.Create('Tipo não encontrado no RTTI');

  for LAttr in LType.GetAttributes do
  begin
    if LAttr is TableNameAttribute then
    begin
      Result := TableNameAttribute(LAttr).Name;
      Exit;
    end;
  end;

  // Fallback: nome da classe sem o prefixo 'T'
  Result := LType.Name;
  if (Length(Result) > 1) and (Result[1] = 'T') then
    Result := Copy(Result, 2, Length(Result) - 1);
end;

class function TRttiMapper.GetColumns<T>: TArray<TColumnMapping>;
var
  LType: TRttiType;
  LProp: TRttiProperty;
  LAttr: TCustomAttribute;
  LMapping: TColumnMapping;
  LList: TList<TColumnMapping>;
begin
  LList := TList<TColumnMapping>.Create;
  try
    LType := FContext.GetType(TypeInfo(T));
    if LType = nil then
      raise Exception.Create('Tipo não encontrado no RTTI');

    // Percorre todas as propriedades, incluindo as herdadas
    for LProp in LType.GetProperties do
    begin
      LMapping.PropertyName := LProp.Name;
      LMapping.ColumnName := '';
      LMapping.IsPrimaryKey := False;
      LMapping.IsAutoIncrement := False;
      LMapping.IsReadOnly := False;
      LMapping.PropertyType := LProp.PropertyType;

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

      // Somente inclui propriedades que possuem [Column]
      if LMapping.ColumnName <> '' then
        LList.Add(LMapping);
    end;

    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

class function TRttiMapper.GetPrimaryKeyColumn<T>: TColumnMapping;
var
  LColumns: TArray<TColumnMapping>;
  LCol: TColumnMapping;
begin
  LColumns := GetColumns<T>;
  for LCol in LColumns do
  begin
    if LCol.IsPrimaryKey then
    begin
      Result := LCol;
      Exit;
    end;
  end;
  raise Exception.Create('Nenhuma chave primária definida para ' + GetTableName<T>);
end;

class function TRttiMapper.GenerateInsertSQL<T>: string;
var
  LTableName: string;
  LColumns: TArray<TColumnMapping>;
  LCol: TColumnMapping;
  LCols, LParams: string;
begin
  LTableName := GetTableName<T>;
  LColumns := GetColumns<T>;
  LCols := '';
  LParams := '';

  for LCol in LColumns do
  begin
    // Ignora campos auto-incremento e read-only no INSERT
    if LCol.IsAutoIncrement or LCol.IsReadOnly then
      Continue;

    if LCols <> '' then
    begin
      LCols := LCols + ', ';
      LParams := LParams + ', ';
    end;

    LCols := LCols + LCol.ColumnName;
    LParams := LParams + ':' + LCol.PropertyName;
  end;

  Result := Format('INSERT INTO %s (%s) VALUES (%s)', [LTableName, LCols, LParams]);
end;

class function TRttiMapper.GenerateUpdateSQL<T>: string;
var
  LTableName: string;
  LColumns: TArray<TColumnMapping>;
  LCol, LPK: TColumnMapping;
  LSets: string;
begin
  LTableName := GetTableName<T>;
  LColumns := GetColumns<T>;
  LPK := GetPrimaryKeyColumn<T>;
  LSets := '';

  for LCol in LColumns do
  begin
    if LCol.IsPrimaryKey or LCol.IsAutoIncrement or LCol.IsReadOnly then
      Continue;

    if LSets <> '' then
      LSets := LSets + ', ';

    LSets := LSets + LCol.ColumnName + ' = :' + LCol.PropertyName;
  end;

  Result := Format('UPDATE %s SET %s WHERE %s = :%s',
    [LTableName, LSets, LPK.ColumnName, LPK.PropertyName]);
end;

class function TRttiMapper.GenerateSelectByIdSQL<T>: string;
var
  LTableName: string;
  LPK: TColumnMapping;
begin
  LTableName := GetTableName<T>;
  LPK := GetPrimaryKeyColumn<T>;
  Result := Format('SELECT * FROM %s WHERE %s = :%s',
    [LTableName, LPK.ColumnName, LPK.PropertyName]);
end;

class function TRttiMapper.GenerateSelectAllSQL<T>: string;
begin
  Result := Format('SELECT * FROM %s', [GetTableName<T>]);
end;

class function TRttiMapper.GenerateDeleteSQL<T>: string;
var
  LTableName: string;
  LPK: TColumnMapping;
begin
  LTableName := GetTableName<T>;
  LPK := GetPrimaryKeyColumn<T>;
  Result := Format('DELETE FROM %s WHERE %s = :%s',
    [LTableName, LPK.ColumnName, LPK.PropertyName]);
end;

class function TRttiMapper.GenerateSelectWhereSQL<T>(const AColumnName: string): string;
begin
  Result := Format('SELECT * FROM %s WHERE %s = :%s',
    [GetTableName<T>, AColumnName, AColumnName]);
end;

class function TRttiMapper.GetPropertyValue(AObject: TObject; const APropName: string): TValue;
var
  LType: TRttiType;
  LProp: TRttiProperty;
begin
  LType := FContext.GetType(AObject.ClassType);
  LProp := LType.GetProperty(APropName);
  if LProp = nil then
    raise Exception.CreateFmt('Propriedade "%s" não encontrada em %s',
      [APropName, AObject.ClassName]);
  Result := LProp.GetValue(AObject);
end;

class procedure TRttiMapper.SetPropertyValue(AObject: TObject; const APropName: string;
  AValue: TValue);
var
  LType: TRttiType;
  LProp: TRttiProperty;
begin
  LType := FContext.GetType(AObject.ClassType);
  LProp := LType.GetProperty(APropName);
  if LProp = nil then
    raise Exception.CreateFmt('Propriedade "%s" não encontrada em %s',
      [APropName, AObject.ClassName]);
  LProp.SetValue(AObject, AValue);
end;

end.
