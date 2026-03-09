unit TaskManager.Attributes;

interface

uses
  System.SysUtils;

type
  /// <summary>
  /// Atributo para mapear o nome da tabela no banco de dados.
  /// Uso: [TableName('nome_tabela')]
  /// </summary>
  TableNameAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  /// <summary>
  /// Atributo para mapear o nome da coluna no banco de dados.
  /// Uso: [Column('nome_coluna')]
  /// </summary>
  ColumnAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  /// <summary>
  /// Atributo para identificar a chave primaria da entidade.
  /// Uso: [PrimaryKey]
  /// </summary>
  PrimaryKeyAttribute = class(TCustomAttribute);

  /// <summary>
  /// Atributo para marcar campos auto-incremento (IDENTITY).
  /// Uso: [AutoIncrement]
  /// </summary>
  AutoIncrementAttribute = class(TCustomAttribute);

  /// <summary>
  /// Atributo para marcar campos que nao devem ser incluidos no INSERT/UPDATE.
  /// Uso: [ReadOnly]
  /// </summary>
  ReadOnlyFieldAttribute = class(TCustomAttribute);

implementation

{ TableNameAttribute }

constructor TableNameAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

{ ColumnAttribute }

constructor ColumnAttribute.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
