unit TaskManager.Client.ApiService;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  System.Generics.Collections,
  REST.Client, REST.Types, REST.Json;

type
  TTaskDTO = record
    Id: Integer;
    Title: string;
    Description: string;
    Priority: Integer;
    PriorityLabel: string;
    Status: Integer;
    StatusLabel: string;
    CreatedAt: string;
    UpdatedAt: string;
    CompletedAt: string;
  end;

  TStatsDTO = record
    TotalTasks: Integer;
    AveragePendingPriority: Double;
    CompletedLast7Days: Integer;
  end;

  /// <summary>
  /// Servico cliente usando REST.Client nativo do Delphi.
  /// CORRECAO: Substituido System.Net.HttpClient por TRESTClient/TRESTRequest.
  /// Token JWT gerenciado em memoria e enviado via AddHeader com poDoNotEncode.
  /// </summary>
  TApiService = class
  private
    FBaseUrl: string;
    FToken: string;
    FRESTClient: TRESTClient;

    function DoRequest(AMethod: TRESTRequestMethod;
      const AResource: string;
      ABody: TJSONObject = nil): TRESTResponse;
    procedure CheckUnauthorized(AResponse: TRESTResponse);
  public
    constructor Create(const ABaseUrl: string = 'http://localhost:9000');
    destructor Destroy; override;

    function Register(const AName, AEmail, APassword: string): string;
    function Login(const AEmail, APassword: string): Boolean;
    procedure Logout;
    function IsAuthenticated: Boolean;

    function GetTasks: TArray<TTaskDTO>;
    function CreateTask(const ATitle, ADescription: string;
      APriority: Integer): TTaskDTO;
    function UpdateTaskStatus(ATaskId, ANewStatus: Integer): TTaskDTO;
    procedure DeleteTask(ATaskId: Integer);
    function GetStats: TStatsDTO;

    property Token: string read FToken;
    property BaseUrl: string read FBaseUrl write FBaseUrl;
    var OnUnauthorized: TProc;
  end;

implementation

{ TApiService }

constructor TApiService.Create(const ABaseUrl: string);
begin
  inherited Create;
  FBaseUrl := ABaseUrl;
  FToken := '';
  FRESTClient := TRESTClient.Create(FBaseUrl);
  FRESTClient.ContentType := 'application/json';
  FRESTClient.Accept := 'application/json';
end;

destructor TApiService.Destroy;
begin
  FRESTClient.Free;
  inherited;
end;

function TApiService.DoRequest(AMethod: TRESTRequestMethod;
  const AResource: string; ABody: TJSONObject): TRESTResponse;
var
  LRequest: TRESTRequest;
  LResponse: TRESTResponse;
begin
  LRequest := TRESTRequest.Create(nil);
  LResponse := TRESTResponse.Create(nil);
  try
    LRequest.Client := FRESTClient;
    LRequest.Response := LResponse;
    LRequest.Method := AMethod;
    LRequest.Resource := AResource;

    // Token JWT via header Authorization
    if not FToken.IsEmpty then
    begin
      LRequest.Params.AddHeader('Authorization', 'Bearer ' + FToken);
      LRequest.Params.ParameterByName('Authorization').Options :=
        [poDoNotEncode];
    end;

    if Assigned(ABody) then
      LRequest.AddBody(ABody.ToJSON, ctAPPLICATION_JSON);

    LRequest.Execute;

    // Transferir ownership do Response
    LRequest.Response := nil;
    Result := LResponse;
    LResponse := nil;
  finally
    LRequest.Free;
    LResponse.Free;
  end;
end;

procedure TApiService.CheckUnauthorized(AResponse: TRESTResponse);
begin
  if AResponse.StatusCode = 401 then
  begin
    FToken := '';
    if Assigned(OnUnauthorized) then
      OnUnauthorized();
    raise Exception.Create('Sessao expirada. Faca login novamente.');
  end;
end;

function TApiService.Register(const AName, AEmail, APassword: string): string;
var
  LBody: TJSONObject;
  LResponse: TRESTResponse;
  LJson: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('name', AName);
    LBody.AddPair('email', AEmail);
    LBody.AddPair('password', APassword);
    LResponse := DoRequest(rmPOST, '/api/users/register', LBody);
  finally
    LBody.Free;
  end;

  try
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    try
      if LResponse.StatusCode = 201 then
        Result := LJson.GetValue<string>('message')
      else
        raise Exception.Create(LJson.GetValue<string>('error', 'Erro desconhecido'));
    finally
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

function TApiService.Login(const AEmail, APassword: string): Boolean;
var
  LBody: TJSONObject;
  LResponse: TRESTResponse;
  LJson: TJSONObject;
  LTokenValue: string;
begin
  Result := False;
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('email', AEmail);
    LBody.AddPair('password', APassword);
    LResponse := DoRequest(rmPOST, '/api/users/login', LBody);
  finally
    LBody.Free;
  end;

  try
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    try
      if LResponse.StatusCode = 200 then
      begin
        LTokenValue := LJson.GetValue<string>('token');
        // Limpar possiveis CRLF residuais
        LTokenValue := LTokenValue.Trim
          .Replace(#13, '', [rfReplaceAll])
          .Replace(#10, '', [rfReplaceAll])
          .Replace(' ', '', [rfReplaceAll]);
        FToken := LTokenValue;
        Result := True;
      end
      else
        raise Exception.Create(LJson.GetValue<string>('error', 'Credenciais invalidas'));
    finally
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TApiService.Logout;
begin
  FToken := '';
end;

function TApiService.IsAuthenticated: Boolean;
begin
  Result := not FToken.IsEmpty;
end;

function TApiService.GetTasks: TArray<TTaskDTO>;
var
  LResponse: TRESTResponse;
  LJson: TJSONObject;
  LArray: TJSONArray;
  LItem: TJSONValue;
  LTaskObj: TJSONObject;
  LList: TList<TTaskDTO>;
  LTask: TTaskDTO;
begin
  LResponse := DoRequest(rmGET, '/api/tasks');
  try
    CheckUnauthorized(LResponse);
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    LList := TList<TTaskDTO>.Create;
    try
      LArray := LJson.GetValue<TJSONArray>('tasks');
      for LItem in LArray do
      begin
        LTaskObj := LItem as TJSONObject;
        LTask.Id := LTaskObj.GetValue<Integer>('id');
        LTask.Title := LTaskObj.GetValue<string>('title');
        LTask.Description := LTaskObj.GetValue<string>('description', '');
        LTask.Priority := LTaskObj.GetValue<Integer>('priority');
        LTask.PriorityLabel := LTaskObj.GetValue<string>('priorityLabel');
        LTask.Status := LTaskObj.GetValue<Integer>('status');
        LTask.StatusLabel := LTaskObj.GetValue<string>('statusLabel');
        LTask.CreatedAt := LTaskObj.GetValue<string>('createdAt', '');
        LList.Add(LTask);
      end;
      Result := LList.ToArray;
    finally
      LList.Free;
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

function TApiService.CreateTask(const ATitle, ADescription: string;
  APriority: Integer): TTaskDTO;
var
  LBody: TJSONObject;
  LResponse: TRESTResponse;
  LJson, LTaskObj: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('title', ATitle);
    LBody.AddPair('description', ADescription);
    LBody.AddPair('priority', TJSONNumber.Create(APriority));
    LResponse := DoRequest(rmPOST, '/api/tasks', LBody);
  finally
    LBody.Free;
  end;

  try
    CheckUnauthorized(LResponse);
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    try
      if LResponse.StatusCode = 201 then
      begin
        LTaskObj := LJson.GetValue<TJSONObject>('task');
        Result.Id := LTaskObj.GetValue<Integer>('id');
        Result.Title := LTaskObj.GetValue<string>('title');
        Result.StatusLabel := LTaskObj.GetValue<string>('statusLabel');
        Result.PriorityLabel := LTaskObj.GetValue<string>('priorityLabel');
      end
      else
        raise Exception.Create(LJson.GetValue<string>('error', 'Erro ao criar tarefa'));
    finally
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

function TApiService.UpdateTaskStatus(ATaskId, ANewStatus: Integer): TTaskDTO;
var
  LBody: TJSONObject;
  LResponse: TRESTResponse;
  LJson, LTaskObj: TJSONObject;
begin
  LBody := TJSONObject.Create;
  try
    LBody.AddPair('status', TJSONNumber.Create(ANewStatus));
    LResponse := DoRequest(rmPUT,
      Format('/api/tasks/%d/status', [ATaskId]), LBody);
  finally
    LBody.Free;
  end;

  try
    CheckUnauthorized(LResponse);
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    try
      if LResponse.StatusCode = 200 then
      begin
        LTaskObj := LJson.GetValue<TJSONObject>('task');
        Result.Id := LTaskObj.GetValue<Integer>('id');
        Result.StatusLabel := LTaskObj.GetValue<string>('statusLabel');
      end
      else if LResponse.StatusCode = 403 then
        raise Exception.Create('Acesso negado: esta tarefa pertence a outro usuario')
      else
        raise Exception.Create(LJson.GetValue<string>('error', 'Erro ao atualizar'));
    finally
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TApiService.DeleteTask(ATaskId: Integer);
var
  LResponse: TRESTResponse;
  LJson: TJSONObject;
begin
  LResponse := DoRequest(rmDELETE, Format('/api/tasks/%d', [ATaskId]));
  try
    CheckUnauthorized(LResponse);
    if not (LResponse.StatusCode in [200, 204]) then
    begin
      LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
      try
        if LResponse.StatusCode = 403 then
          raise Exception.Create('Acesso negado: esta tarefa pertence a outro usuario')
        else
          raise Exception.Create(LJson.GetValue<string>('error', 'Erro ao remover'));
      finally
        LJson.Free;
      end;
    end;
  finally
    LResponse.Free;
  end;
end;

function TApiService.GetStats: TStatsDTO;
var
  LResponse: TRESTResponse;
  LJson: TJSONObject;
begin
  LResponse := DoRequest(rmGET, '/api/tasks/stats');
  try
    CheckUnauthorized(LResponse);
    LJson := TJSONObject.ParseJSONValue(LResponse.Content) as TJSONObject;
    try
      Result.TotalTasks := LJson.GetValue<Integer>('totalTasks');
      Result.AveragePendingPriority := LJson.GetValue<Double>('averagePendingPriority');
      Result.CompletedLast7Days := LJson.GetValue<Integer>('completedLast7Days');
    finally
      LJson.Free;
    end;
  finally
    LResponse.Free;
  end;
end;

end.
