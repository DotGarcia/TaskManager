unit TaskManager.Services.TaskService;

interface

uses
  System.SysUtils, System.Generics.Collections,
  TaskManager.Entities,
  TaskManager.Repositories.Interfaces,
  TaskManager.Services.Interfaces;

type
  /// <summary>
  /// Exceção de acesso negado (403 Forbidden).
  /// Lançada quando um usuário tenta acessar tarefa de outro usuário.
  /// </summary>
  EForbiddenException = class(Exception);

  /// <summary>
  /// Exceção de recurso não encontrado (404 Not Found).
  /// </summary>
  ENotFoundException = class(Exception);

  /// <summary>
  /// Implementação do serviço de tarefas.
  /// Garante isolamento entre usuários — nenhum usuário acessa tarefas de outro.
  /// </summary>
  TTaskService = class(TInterfacedObject, ITaskService)
  private
    FTaskRepository: ITaskRepository;

    /// Valida que a tarefa pertence ao usuário e retorna a tarefa.
    function ValidateOwnership(ATaskId, AUserId: Integer): TTask;
  public
    constructor Create(ATaskRepository: ITaskRepository);

    function GetAllTasks(AUserId: Integer): TObjectList<TTask>;
    function GetTaskById(ATaskId, AUserId: Integer): TTask;
    function CreateTask(ATask: TTask): TTask;
    function UpdateTaskStatus(ATaskId, AUserId, ANewStatus: Integer): Boolean;
    function DeleteTask(ATaskId, AUserId: Integer): Boolean;
    function GetStats(AUserId: Integer): TTaskStats;
  end;

implementation

{ TTaskService }

constructor TTaskService.Create(ATaskRepository: ITaskRepository);
begin
  inherited Create;
  FTaskRepository := ATaskRepository;
end;

function TTaskService.ValidateOwnership(ATaskId, AUserId: Integer): TTask;
begin
  Result := FTaskRepository.FindById(ATaskId);
  if Result = nil then
    raise ENotFoundException.Create('Tarefa não encontrada');

  if Result.UserId <> AUserId then
    raise EForbiddenException.Create('Acesso negado: tarefa pertence a outro usuário');
end;

function TTaskService.GetAllTasks(AUserId: Integer): TObjectList<TTask>;
begin
  Result := FTaskRepository.FindByUserId(AUserId);
end;

function TTaskService.GetTaskById(ATaskId, AUserId: Integer): TTask;
begin
  Result := ValidateOwnership(ATaskId, AUserId);
end;

function TTaskService.CreateTask(ATask: TTask): TTask;
begin
  // Validações
  if ATask.Title.Trim.IsEmpty then
    raise EArgumentException.Create('Título é obrigatório');
  if ATask.UserId <= 0 then
    raise EArgumentException.Create('UserId inválido');
  if not (ATask.Priority in [1..5]) then
    ATask.Priority := 3; // Padrão: Média

  // Garante status inicial como Pendente
  ATask.Status := Ord(tsPending);
  Result := FTaskRepository.Insert(ATask);
end;

function TTaskService.UpdateTaskStatus(ATaskId, AUserId, ANewStatus: Integer): Boolean;
var
  LTask: TTask;
begin
  LTask := ValidateOwnership(ATaskId, AUserId);

  // Valida status
  if not (ANewStatus in [Ord(tsPending)..Ord(tsCompleted)]) then
    raise EArgumentException.Create('Status inválido. Use 0=Pendente, 1=Em Andamento, 2=Concluída');

  LTask.SetStatusEnum(TTaskStatus(ANewStatus));
  Result := FTaskRepository.Update(LTask);
end;

function TTaskService.DeleteTask(ATaskId, AUserId: Integer): Boolean;
begin
  // ValidateOwnership garante que a tarefa existe e pertence ao usuário
  ValidateOwnership(ATaskId, AUserId);
  Result := FTaskRepository.Delete(ATaskId);
end;

function TTaskService.GetStats(AUserId: Integer): TTaskStats;
begin
  Result.TotalTasks := FTaskRepository.CountByUserId(AUserId);
  Result.AvgPendingPriority := FTaskRepository.AvgPriorityPendingByUserId(AUserId);
  Result.CompletedLast7Days := FTaskRepository.CountCompletedLast7DaysByUserId(AUserId);
end;

end.
