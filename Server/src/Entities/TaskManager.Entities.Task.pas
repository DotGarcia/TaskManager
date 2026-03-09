unit TaskManager.Entities.Task;

interface

uses
  System.SysUtils,
  TaskManager.Attributes,
  TaskManager.Entities.Base;

type
  /// <summary>
  /// Status possiveis de uma tarefa.
  /// </summary>
  TTaskStatus = (tsPending = 0, tsInProgress = 1, tsCompleted = 2);

  /// <summary>
  /// Niveis de prioridade de uma tarefa.
  /// </summary>
  TTaskPriority = (tpLow = 1, tpMedium = 2, tpHigh = 3, tpCritical = 4);

  /// <summary>
  /// Entidade de Tarefa. Herda de TBaseEntity (Id, CreatedAt).
  /// Mapeada para a tabela [Tasks] via atributo RTTI.
  /// Cada tarefa pertence a um usuario (UserId).
  /// </summary>
  [TableName('Tasks')]
  TTask = class(TBaseEntity)
  private
    FUserId: Integer;
    FTitle: string;
    FDescription: string;
    FPriority: Integer;
    FStatus: Integer;
    FUpdatedAt: TDateTime;
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

    [Column('UpdatedAt')]
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;

    [Column('CompletedAt')]
    property CompletedAt: TDateTime read FCompletedAt write FCompletedAt;

    // Helpers para conversao de enums
    function GetStatusEnum: TTaskStatus;
    procedure SetStatusEnum(AStatus: TTaskStatus);
    function GetPriorityEnum: TTaskPriority;
    procedure SetPriorityEnum(APriority: TTaskPriority);
  end;

implementation

{ TTask }

constructor TTask.Create;
begin
  inherited Create;
  FUserId := 0;
  FTitle := '';
  FDescription := '';
  FPriority := Ord(tpLow);
  FStatus := Ord(tsPending);
  FUpdatedAt := 0;
  FCompletedAt := 0;
end;

function TTask.GetStatusEnum: TTaskStatus;
begin
  Result := TTaskStatus(FStatus);
end;

procedure TTask.SetStatusEnum(AStatus: TTaskStatus);
begin
  FStatus := Ord(AStatus);
end;

function TTask.GetPriorityEnum: TTaskPriority;
begin
  Result := TTaskPriority(FPriority);
end;

procedure TTask.SetPriorityEnum(APriority: TTaskPriority);
begin
  FPriority := Ord(APriority);
end;

end.
