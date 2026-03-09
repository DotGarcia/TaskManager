unit TaskManager.Controllers.Task;

interface

uses
  System.SysUtils, System.JSON, System.DateUtils,
  System.Generics.Collections,
  Horse,
  TaskManager.Entities.Task,
  TaskManager.Services.Interfaces,
  TaskManager.Services.Task,
  TaskManager.Middleware.Auth;  // TJWTAuthHelper

type
  /// <summary>
  /// Controller de Tarefas (Camada C do MVC).
  /// Todos os endpoints exigem autenticacao JWT.
  /// </summary>
  TTaskController = class
  private
    FService: ITaskService;
    function GetUserId(Req: THorseRequest): Integer;
    function TaskToJSON(ATask: TTask): TJSONObject;
  public
    constructor Create(AService: ITaskService);
    procedure GetAll(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure CreateTask(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure UpdateStatus(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure DeleteTask(Req: THorseRequest; Res: THorseResponse; Next: TProc);
    procedure GetStats(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TTaskController }

constructor TTaskController.Create(AService: ITaskService);
begin
  inherited Create;
  FService := AService;
end;

function TTaskController.GetUserId(Req: THorseRequest): Integer;
begin
  // CORRECAO: Decodifica JWT direto do Authorization header
  Result := TJWTAuthHelper.GetUserIdFromRequest(Req);
end;

function TTaskController.TaskToJSON(ATask: TTask): TJSONObject;
var
  LStatusStr, LPriorityStr: string;
begin
  case ATask.GetStatusEnum of
    tsPending:    LStatusStr := 'Pendente';
    tsInProgress: LStatusStr := 'Em Andamento';
    tsCompleted:  LStatusStr := 'Concluida';
  else
    LStatusStr := 'Desconhecido';
  end;

  case ATask.GetPriorityEnum of
    tpLow:      LPriorityStr := 'Baixa';
    tpMedium:   LPriorityStr := 'Media';
    tpHigh:     LPriorityStr := 'Alta';
    tpCritical: LPriorityStr := 'Critica';
  else
    LPriorityStr := 'Desconhecida';
  end;

  Result := TJSONObject.Create;
  Result.AddPair('id', TJSONNumber.Create(ATask.Id));
  Result.AddPair('userId', TJSONNumber.Create(ATask.UserId));
  Result.AddPair('title', ATask.Title);
  Result.AddPair('description', ATask.Description);
  Result.AddPair('priority', TJSONNumber.Create(ATask.Priority));
  Result.AddPair('priorityLabel', LPriorityStr);
  Result.AddPair('status', TJSONNumber.Create(ATask.Status));
  Result.AddPair('statusLabel', LStatusStr);
  Result.AddPair('createdAt', DateToISO8601(ATask.CreatedAt, False));

  if ATask.UpdatedAt > 0 then
    Result.AddPair('updatedAt', DateToISO8601(ATask.UpdatedAt, False))
  else
    Result.AddPair('updatedAt', TJSONNull.Create);

  if ATask.CompletedAt > 0 then
    Result.AddPair('completedAt', DateToISO8601(ATask.CompletedAt, False))
  else
    Result.AddPair('completedAt', TJSONNull.Create);
end;

procedure TTaskController.GetAll(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LUserId: Integer;
  LTasks: TObjectList<TTask>;
  LArray: TJSONArray;
  LTask: TTask;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserId(Req);
    LTasks := FService.GetAllTasks(LUserId);
    try
      LArray := TJSONArray.Create;
      for LTask in LTasks do
        LArray.AddElement(TaskToJSON(LTask));

      LResponse := TJSONObject.Create;
      LResponse.AddPair('count', TJSONNumber.Create(LTasks.Count));
      LResponse.AddPair('tasks', LArray);
      Res.Send<TJSONObject>(LResponse).Status(200);
    finally
      LTasks.Free;
    end;
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(500);
    end;
  end;
end;

procedure TTaskController.CreateTask(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LUserId: Integer;
  LBody: TJSONObject;
  LTask: TTask;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserId(Req);
    LBody := Req.Body<TJSONObject>;

    LTask := FService.CreateTask(LUserId,
      LBody.GetValue<string>('title', ''),
      LBody.GetValue<string>('description', ''),
      LBody.GetValue<Integer>('priority', 1));

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Tarefa criada com sucesso');
    LResponse.AddPair('task', TaskToJSON(LTask));
    Res.Send<TJSONObject>(LResponse).Status(201);
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(400);
    end;
  end;
end;

procedure TTaskController.UpdateStatus(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LUserId, LTaskId, LNewStatus: Integer;
  LBody: TJSONObject;
  LTask: TTask;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserId(Req);
    LTaskId := Req.Params['id'].ToInteger;
    LBody := Req.Body<TJSONObject>;
    LNewStatus := LBody.GetValue<Integer>('status', -1);

    LTask := FService.UpdateTaskStatus(LUserId, LTaskId, LNewStatus);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Status atualizado com sucesso');
    LResponse.AddPair('task', TaskToJSON(LTask));
    Res.Send<TJSONObject>(LResponse).Status(200);
  except
    on E: EForbiddenException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      LResponse.AddPair('code', 'FORBIDDEN');
      Res.Send<TJSONObject>(LResponse).Status(403);
    end;
    on E: ENotFoundException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(404);
    end;
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(400);
    end;
  end;
end;

procedure TTaskController.DeleteTask(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LUserId, LTaskId: Integer;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserId(Req);
    LTaskId := Req.Params['id'].ToInteger;
    FService.DeleteTask(LUserId, LTaskId);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Tarefa removida com sucesso');
    Res.Send<TJSONObject>(LResponse).Status(200);
  except
    on E: EForbiddenException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      LResponse.AddPair('code', 'FORBIDDEN');
      Res.Send<TJSONObject>(LResponse).Status(403);
    end;
    on E: ENotFoundException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(404);
    end;
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(400);
    end;
  end;
end;

procedure TTaskController.GetStats(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LUserId: Integer;
  LStats: TTaskStats;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserId(Req);
    LStats := FService.GetStats(LUserId);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('totalTasks', TJSONNumber.Create(LStats.TotalTasks));
    LResponse.AddPair('averagePendingPriority',
      TJSONNumber.Create(LStats.AveragePendingPriority));
    LResponse.AddPair('completedLast7Days',
      TJSONNumber.Create(LStats.CompletedLast7Days));
    Res.Send<TJSONObject>(LResponse).Status(200);
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(500);
    end;
  end;
end;

end.
