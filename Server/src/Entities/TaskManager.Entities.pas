unit TaskManager.Entities;

interface

uses
  System.SysUtils,
  System.DateUtils,
  TaskManager.Attributes;

type
  /// <summary>
  /// Classe-base abstrata contendo campos comuns a todas as entidades.
  /// TUser e TTask herdam desta classe (requisito de Herança OOP).
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
    [ReadOnlyField]
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

  /// <summary>
  /// Status possíveis de uma tarefa.
  /// </summary>
  TTaskStatus = (tsPending = 0, tsInProgress = 1, tsCompleted = 2);

  /// <summary>
  /// Entidade de Usuário com encapsulamento adequado.
  /// </summary>
  [TableName('Users')]
  TUser = class(TBaseEntity)
  private
    FName: string;
    FEmail: string;
    FPassword: string;
    FSalt: string;
  public
    constructor Create; override;

    [Column('Name')]
    property Name: string read FName write FName;

    [Column('Email')]
    property Email: string read FEmail write FEmail;

    [Column('Password')]
    property Password: string read FPassword write FPassword;

    [Column('Salt')]
    property Salt: string read FSalt write FSalt;
  end;

  /// <summary>
  /// Entidade de Tarefa com encapsulamento adequado.
  /// </summary>
  [TableName('Tasks')]
  TTask = class(TBaseEntity)
  private
    FUserId: Integer;
    FTitle: string;
    FDescription: string;
    FPriority: Integer;
    FStatus: Integer;
    FDueDate: TDateTime;
    FCompletedAt: TDateTime;
  public
    constructor Create; override;

    [Column('UserId')]
    property UserId: Integer read FUserId write FUserId;

    [Column('Title')]
    property Title: string read FTitle write FTitle;

    [Column('Description')]
    property Description: string read FDescription write FDescription;

    [Column('Priority')]
    property Priority: Integer read FPriority write FPriority;

    [Column('Status')]
    property Status: Integer read FStatus write FStatus;

    [Column('DueDate')]
    property DueDate: TDateTime read FDueDate write FDueDate;

    [Column('CompletedAt')]
    property CompletedAt: TDateTime read FCompletedAt write FCompletedAt;

    function GetStatusEnum: TTaskStatus;
    procedure SetStatusEnum(AStatus: TTaskStatus);
  end;

implementation

{ TBaseEntity }

constructor TBaseEntity.Create;
begin
  inherited Create;
  FId := 0;
  FCreatedAt := Now;
end;

{ TUser }

constructor TUser.Create;
begin
  inherited Create;
  FName := '';
  FEmail := '';
  FPassword := '';
  FSalt := '';
end;

{ TTask }

constructor TTask.Create;
begin
  inherited Create;
  FUserId := 0;
  FTitle := '';
  FDescription := '';
  FPriority := 3; // Média
  FStatus := Ord(tsPending);
  FDueDate := 0;
  FCompletedAt := 0;
end;

function TTask.GetStatusEnum: TTaskStatus;
begin
  Result := TTaskStatus(FStatus);
end;

procedure TTask.SetStatusEnum(AStatus: TTaskStatus);
begin
  FStatus := Ord(AStatus);
  if AStatus = tsCompleted then
    FCompletedAt := Now;
end;

end.
