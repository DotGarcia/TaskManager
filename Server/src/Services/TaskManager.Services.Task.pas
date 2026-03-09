unit TaskManager.Services.Task;

interface

uses
  System.SysUtils, System.DateUtils, System.Generics.Collections,
  TaskManager.Entities.Base, TaskManager.Entities.Task,
  TaskManager.Repositories.Interfaces,
  TaskManager.Services.Interfaces;

type
  EForbiddenException = class(Exception);
  ENotFoundException = class(Exception);

  TTaskService = class(TInterfacedObject, ITaskService)
  private
    FRepository: ITaskRepository;
    procedure ValidateOwnership(ATask: TBaseEntity; AUserId: Integer);
  public
    constructor Create(ARepository: ITaskRepository);

    function GetAllTasks(AUserId: Integer): TObjectList<TTask>;
    function CreateTask(AUserId: Integer; const ATitle, ADescription: string;
      APriority: Integer): TTask;
    function UpdateTaskStatus(AUserId, ATaskId, ANewStatus: Integer): TTask;
    procedure DeleteTask(AUserId, ATaskId: Integer);
    function GetStats(AUserId: Integer): TTaskStats;
  end;

implementation

{ TTaskService }

constructor TTaskService.Create(ARepository: ITaskRepository);
begin
  inherited Create;
  FRepository := ARepository;
end;

procedure TTaskService.ValidateOwnership(ATask: TBaseEntity; AUserId: Integer);
begin
  if not Assigned(ATask) then
    raise ENotFoundException.Create('Tarefa nao encontrada');

  if (ATask as TTask).UserId <> AUserId then
    raise EForbiddenException.Create('Acesso negado: tarefa pertence a outro usuario');
end;

function TTaskService.GetAllTasks(AUserId: Integer): TObjectList<TTask>;
var
  LEntities: TObjectList<TBaseEntity>;
  LEntity: TBaseEntity;
  LResult: TObjectList<TTask>;
begin
  LEntities := FRepository.FindByUserId(AUserId);
  try
    LResult := TObjectList<TTask>.Create(False);
    try
      for LEntity in LEntities do
        LResult.Add(LEntity as TTask);
    except
      LResult.Free;
      raise;
    end;
  finally
    LEntities.OwnsObjects := False;
    LEntities.Free;
  end;

  Result := LResult;
end;

function TTaskService.CreateTask(AUserId: Integer;
  const ATitle, ADescription: string; APriority: Integer): TTask;
var
  LTask: TTask;
begin
  if ATitle.Trim.IsEmpty then
    raise Exception.Create('Titulo e obrigatorio');
  if not (APriority in [1..4]) then
    raise Exception.Create('Prioridade deve ser entre 1 (Baixa) e 4 (Critica)');

  LTask := TTask.Create;
  try
    LTask.UserId := AUserId;
    LTask.Title := ATitle.Trim;
    LTask.Description := ADescription.Trim;
    LTask.Priority := APriority;
    LTask.Status := Ord(tsPending);
    LTask.CreatedAt := Now;

    FRepository.Insert(LTask);
    Result := LTask;
  except
    LTask.Free;
    raise;
  end;
end;

function TTaskService.UpdateTaskStatus(AUserId, ATaskId,
  ANewStatus: Integer): TTask;
var
  LEntity: TBaseEntity;
  LTask: TTask;
begin
  if not (ANewStatus in [0..2]) then
    raise Exception.Create('Status invalido. Use: 0=Pendente, 1=EmAndamento, 2=Concluida');

  LEntity := FRepository.FindById(ATaskId);
  ValidateOwnership(LEntity, AUserId);

  LTask := LEntity as TTask;
  LTask.Status := ANewStatus;
  LTask.UpdatedAt := Now;

  if ANewStatus = Ord(tsCompleted) then
    LTask.CompletedAt := Now;

  FRepository.Update(LTask);
  Result := LTask;
end;

procedure TTaskService.DeleteTask(AUserId, ATaskId: Integer);
var
  LEntity: TBaseEntity;
begin
  LEntity := FRepository.FindById(ATaskId);
  ValidateOwnership(LEntity, AUserId);

  FRepository.Delete(ATaskId);
end;

function TTaskService.GetStats(AUserId: Integer): TTaskStats;
begin
  Result.TotalTasks := FRepository.GetTotalTaskCount(AUserId);
  Result.AveragePendingPriority := FRepository.GetAveragePendingPriority(AUserId);
  Result.CompletedLast7Days := FRepository.GetCompletedLast7Days(AUserId);
end;

end.
