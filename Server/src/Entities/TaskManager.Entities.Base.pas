unit TaskManager.Entities.Base;

interface

uses
  System.SysUtils,
  TaskManager.Attributes;

type
  /// <summary>
  /// Classe base abstrata para todas as entidades do dominio.
  /// Contem campos comuns: Id e CreatedAt.
  /// Demonstra Heranca e Encapsulamento (OOP).
  /// </summary>
  TBaseEntity = class abstract
  private
    FId: Integer;
    FCreatedAt: TDateTime;
  public
    constructor Create; virtual;

    [PrimaryKey]
    [AutoIncrement]
    [Column('Id')]
    property Id: Integer read FId write FId;

    [Column('CreatedAt')]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

implementation

{ TBaseEntity }

constructor TBaseEntity.Create;
begin
  inherited Create;
  FId := 0;
  FCreatedAt := Now;
end;

end.
