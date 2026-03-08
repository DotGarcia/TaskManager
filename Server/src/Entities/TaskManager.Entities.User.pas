unit TaskManager.Entities.User;

interface

uses
  System.SysUtils,
  TaskManager.Attributes,
  TaskManager.Entities.Base;

type
  /// <summary>
  /// Entidade de Usuario. Herda de TBaseEntity (Id, CreatedAt).
  /// Mapeada para a tabela [Users] via atributo RTTI.
  /// </summary>
  [TableName('Users')]
  TUser = class(TBaseEntity)
  private
    FName: string;
    FEmail: string;
    FPasswordHash: string;
    FSalt: string;
  public
    constructor Create; override;

    [Column('Name')]
    property Name: string read FName write FName;

    [Column('Email')]
    property Email: string read FEmail write FEmail;

    [Column('PasswordHash')]
    property PasswordHash: string read FPasswordHash write FPasswordHash;

    [Column('Salt')]
    property Salt: string read FSalt write FSalt;
  end;

implementation

{ TUser }

constructor TUser.Create;
begin
  inherited Create;
  FName := '';
  FEmail := '';
  FPasswordHash := '';
  FSalt := '';
end;

end.
