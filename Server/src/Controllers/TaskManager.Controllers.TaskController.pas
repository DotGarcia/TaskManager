unit TaskManager.Controllers.TaskController;

interface

uses
  System.SysUtils, System.JSON, System.Generics.Collections,
  Horse,
  TaskManager.Entities,
  TaskManager.Services.Interfaces,
  TaskManager.Services.TaskService;

type
  /// <summary>
  /// Controller de Tarefas — endpoints protegidos por JWT.
  /// GET    /api/tasks         — Lista tarefas do usuário autenticado
  /// POST   /api/tasks         — Cria nova tarefa
  /// PUT    /api/tasks/:id     — Atualiza status da tarefa
  /// DELETE /api/tasks/:id     — Remove tarefa
  /// GET    /api/tasks/stats   — Estatísticas (Desafio SQL)
  /// </summary>
  TTaskController = class
  private
    FTaskService: ITaskService;

    /// Extrai o UserId do header injetado pelo middleware JWT
    function GetUserIdFromRequest(Req: THorseRequest): Integer;
  public
    constructor Create(ATaskService: ITaskService);

    procedure ListTasks(Req: THorseRequest; Res: THorseResponse);
    procedure CreateTask(Req: THorseRequest; Res: THorseResponse);
    procedure UpdateTaskStatus(Req: THorseRequest; Res: THorseResponse);
    procedure DeleteTask(Req: THorseRequest; Res: THorseResponse);
    procedure GetStats(Req: THorseRequest; Res: THorseResponse);

    procedure RegisterRoutes(AApp: THorse);
  end;

implementation

{ TTaskController }

constructor TTaskController.Create(ATaskService: ITaskService);
begin
  inherited Create;
  FTaskService := ATaskService;
end;

function TTaskController.GetUserIdFromRequest(Req: THorseRequest): Integer;
var
  LUserIdStr: string;
begin
  LUserIdStr := Req.Headers['X-User-Id'];
  if LUserIdStr.IsEmpty then
    raise Exception.Create('UserId não encontrado no request');
  Result := StrToInt(LUserIdStr);
end;

procedure TTaskController.ListTasks(Req: THorseRequest; Res: THorseResponse);
var
  LUserId: Integer;
  LTasks: TObjectList<TTask>;
  LArray: TJSONArray;
  LTask: TTask;
  LTaskJSON: TJSONObject;
begin
  try
    LUserId := GetUserIdFromRequest(Req);
    LTasks := FTaskService.GetAllTasks(LUserId);
    try
      LArray := TJSONArray.Create;
      for LTask in LTasks do
      begin
        LTaskJSON := TJSONObject.Create;
        LTaskJSON.AddPair('id', TJSONNumber.Create(LTask.Id));
        LTaskJSON.AddPair('title', LTask.Title);
        LTaskJSON.AddPair('description', LTask.Description);
        LTaskJSON.AddPair('priority', TJSONNumber.Create(LTask.Priority));
        LTaskJSON.AddPair('status', TJSONNumber.Create(LTask.Status));
        LTaskJSON.AddPair('createdAt', DateTimeToStr(LTask.CreatedAt));

        if LTask.DueDate > 0 then
          LTaskJSON.AddPair('dueDate', DateTimeToStr(LTask.DueDate))
        else
          LTaskJSON.AddPair('dueDate', TJSONNull.Create);

        if LTask.CompletedAt > 0 then
          LTaskJSON.AddPair('completedAt', DateTimeToStr(LTask.CompletedAt))
        else
          LTaskJSON.AddPair('completedAt', TJSONNull.Create);

        LArray.AddElement(LTaskJSON);
      end;

      Res.Send<TJSONArray>(LArray).Status(THTTPStatus.OK);
    finally
      LTasks.Free;
    end;
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TTaskController.CreateTask(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LTask: TTask;
  LResponse: TJSONObject;
begin
  try
    LBody := Req.Body<TJSONObject>;
    LTask := TTask.Create;
    try
      LTask.UserId := GetUserIdFromRequest(Req);
      LTask.Title := LBody.GetValue<string>('title', '');
      LTask.Description := LBody.GetValue<string>('description', '');
      LTask.Priority := LBody.GetValue<Integer>('priority', 3);

      LTask := FTaskService.CreateTask(LTask);

      LResponse := TJSONObject.Create;
      LResponse.AddPair('id', TJSONNumber.Create(LTask.Id));
      LResponse.AddPair('title', LTask.Title);
      LResponse.AddPair('priority', TJSONNumber.Create(LTask.Priority));
      LResponse.AddPair('status', TJSONNumber.Create(LTask.Status));
      LResponse.AddPair('message', 'Tarefa criada com sucesso');

      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.Created);
    except
      // O objeto LTask pode já ter sido inserido no repositório,
      // por isso não liberamos aqui em caso de sucesso
      raise;
    end;
  except
    on E: EArgumentException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.BadRequest);
    end;
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TTaskController.UpdateTaskStatus(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LTaskId, LUserId, LNewStatus: Integer;
  LResponse: TJSONObject;
begin
  try
    LTaskId := Req.Params['id'].ToInteger;
    LUserId := GetUserIdFromRequest(Req);
    LBody := Req.Body<TJSONObject>;
    LNewStatus := LBody.GetValue<Integer>('status', -1);

    FTaskService.UpdateTaskStatus(LTaskId, LUserId, LNewStatus);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Status atualizado com sucesso');
    Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.OK);
  except
    on E: EForbiddenException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.Forbidden);
    end;
    on E: ENotFoundException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.NotFound);
    end;
    on E: EArgumentException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.BadRequest);
    end;
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TTaskController.DeleteTask(Req: THorseRequest; Res: THorseResponse);
var
  LTaskId, LUserId: Integer;
  LResponse: TJSONObject;
begin
  try
    LTaskId := Req.Params['id'].ToInteger;
    LUserId := GetUserIdFromRequest(Req);

    FTaskService.DeleteTask(LTaskId, LUserId);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Tarefa removida com sucesso');
    Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.OK);
  except
    on E: EForbiddenException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.Forbidden);
    end;
    on E: ENotFoundException do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.NotFound);
    end;
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TTaskController.GetStats(Req: THorseRequest; Res: THorseResponse);
var
  LUserId: Integer;
  LStats: TTaskStats;
  LResponse: TJSONObject;
begin
  try
    LUserId := GetUserIdFromRequest(Req);
    LStats := FTaskService.GetStats(LUserId);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('totalTasks', TJSONNumber.Create(LStats.TotalTasks));
    LResponse.AddPair('avgPendingPriority', TJSONNumber.Create(LStats.AvgPendingPriority));
    LResponse.AddPair('completedLast7Days', TJSONNumber.Create(LStats.CompletedLast7Days));

    Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.OK);
  except
    on E: Exception do
    begin
      Res.Send<TJSONObject>(
        TJSONObject.Create.AddPair('error', E.Message)
      ).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TTaskController.RegisterRoutes(AApp: THorse);
begin
  // Rotas protegidas — o middleware JWT já é aplicado globalmente
  // para rotas /api/tasks/*
  AApp.Get('/api/tasks', Self.ListTasks);
  AApp.Get('/api/tasks/stats', Self.GetStats);
  AApp.Post('/api/tasks', Self.CreateTask);
  AApp.Put('/api/tasks/:id', Self.UpdateTaskStatus);
  AApp.Delete('/api/tasks/:id', Self.DeleteTask);
end;

end.
