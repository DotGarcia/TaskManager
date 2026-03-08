unit TaskManager.Repositories.SQLServer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.Rtti,
  System.DateUtils, Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param,
  TaskManager.Entities.Base, TaskManager.Entities.User, TaskManager.Entities.Task,
  TaskManager.Repositories.Interfaces, TaskManager.RTTI.Mapper,
  TaskManager.Attributes;

type
  /// <summary>
  /// Repositorio SQL Server para Usuarios.
  /// Utiliza RTTI Mapper para construir queries dinamicamente.
  /// Demonstra Polimorfismo: mesma interface, implementacao com banco real.
  /// </summary>
  TSQLServerUserRepository = class(TInterfacedObject, IUserRepository)
  private
    FConnection: TFDConnection;
    procedure MapQueryToUser(AQuery: TFDQuery; AUser: TUser);
    procedure SetUserParams(AQuery: TFDQuery; AUser: TUser);
  public
    constructor Create(AConnection: TFDConnection);

    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByEmail(const AEmail: string): TBaseEntity;
  end;

  /// <summary>
  /// Repositorio SQL Server para Tarefas.
  /// As queries SQL do desafio (estatisticas) sao executadas diretamente no banco.
  /// </summary>
  TSQLServerTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FConnection: TFDConnection;
    procedure MapQueryToTask(AQuery: TFDQuery; ATask: TTask);
    procedure SetTaskParams(AQuery: TFDQuery; ATask: TTask);
  public
    constructor Create(AConnection: TFDConnection);

    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByUserId(AUserId: Integer): TObjectList<TBaseEntity>;

    // Desafio SQL - Queries executadas no SQL Server
    function GetTotalTaskCount(AUserId: Integer): Integer;
    function GetAveragePendingPriority(AUserId: Integer): Double;
    function GetCompletedLast7Days(AUserId: Integer): Integer;
  end;

implementation

{ TSQLServerUserRepository }

constructor TSQLServerUserRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

procedure TSQLServerUserRepository.MapQueryToUser(AQuery: TFDQuery; AUser: TUser);
begin
  AUser.Id := AQuery.FieldByName('Id').AsInteger;
  AUser.Name := AQuery.FieldByName('Name').AsString;
  AUser.Email := AQuery.FieldByName('Email').AsString;
  AUser.PasswordHash := AQuery.FieldByName('PasswordHash').AsString;
  AUser.Salt := AQuery.FieldByName('Salt').AsString;
  AUser.CreatedAt := AQuery.FieldByName('CreatedAt').AsDateTime;
end;

procedure TSQLServerUserRepository.SetUserParams(AQuery: TFDQuery; AUser: TUser);
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LMappings := TRttiMapper.GetColumnMappings(TUser);
  for LMapping in LMappings do
  begin
    if LMapping.IsAutoIncrement or LMapping.IsReadOnly then
      Continue;
    if AQuery.Params.FindParam(LMapping.PropertyName) <> nil then
    begin
      AQuery.Params.ParamByName(LMapping.PropertyName).Value :=
        TRttiMapper.GetPropertyValue(AUser, LMapping.PropertyName).AsVariant;
    end;
  end;
end;

function TSQLServerUserRepository.FindById(AId: Integer): TBaseEntity;
var
  LQuery: TFDQuery;
  LUser: TUser;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildSelectByIdSQL(TUser);
    LQuery.ParamByName('Id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.Eof then
    begin
      LUser := TUser.Create;
      MapQueryToUser(LQuery, LUser);
      Result := LUser;
    end;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerUserRepository.FindAll: TObjectList<TBaseEntity>;
var
  LQuery: TFDQuery;
  LUser: TUser;
  LList: TObjectList<TBaseEntity>;
begin
  LList := TObjectList<TBaseEntity>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildSelectAllSQL(TUser);
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LUser := TUser.Create;
      MapQueryToUser(LQuery, LUser);
      LList.Add(LUser);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
  Result := LList;
end;

function TSQLServerUserRepository.Insert(AEntity: TBaseEntity): Integer;
var
  LQuery: TFDQuery;
  LUser: TUser;
begin
  LUser := AEntity as TUser;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    // INSERT + retorna o ID gerado via SCOPE_IDENTITY
    LQuery.SQL.Text := TRttiMapper.BuildInsertSQL(TUser) +
      '; SELECT SCOPE_IDENTITY() AS NewId;';
    SetUserParams(LQuery, LUser);
    LQuery.Open;

    Result := LQuery.FieldByName('NewId').AsInteger;
    LUser.Id := Result;
  finally
    LQuery.Free;
  end;
end;

procedure TSQLServerUserRepository.Update(AEntity: TBaseEntity);
var
  LQuery: TFDQuery;
  LUser: TUser;
begin
  LUser := AEntity as TUser;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildUpdateSQL(TUser);
    SetUserParams(LQuery, LUser);
    LQuery.ParamByName('Id').AsInteger := LUser.Id;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TSQLServerUserRepository.Delete(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildDeleteSQL(TUser);
    LQuery.ParamByName('Id').AsInteger := AId;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerUserRepository.FindByEmail(const AEmail: string): TBaseEntity;
var
  LQuery: TFDQuery;
  LUser: TUser;
  LTable: string;
begin
  Result := nil;
  LTable := TRttiMapper.GetTableName(TUser);
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := Format('SELECT * FROM [%s] WHERE [Email] = :Email', [LTable]);
    LQuery.ParamByName('Email').AsString := AEmail;
    LQuery.Open;

    if not LQuery.Eof then
    begin
      LUser := TUser.Create;
      MapQueryToUser(LQuery, LUser);
      Result := LUser;
    end;
  finally
    LQuery.Free;
  end;
end;

{ TSQLServerTaskRepository }

constructor TSQLServerTaskRepository.Create(AConnection: TFDConnection);
begin
  inherited Create;
  FConnection := AConnection;
end;

procedure TSQLServerTaskRepository.MapQueryToTask(AQuery: TFDQuery; ATask: TTask);
begin
  ATask.Id := AQuery.FieldByName('Id').AsInteger;
  ATask.UserId := AQuery.FieldByName('UserId').AsInteger;
  ATask.Title := AQuery.FieldByName('Title').AsString;
  ATask.Description := AQuery.FieldByName('Description').AsString;
  ATask.Priority := AQuery.FieldByName('Priority').AsInteger;
  ATask.Status := AQuery.FieldByName('Status').AsInteger;
  ATask.CreatedAt := AQuery.FieldByName('CreatedAt').AsDateTime;

  if not AQuery.FieldByName('UpdatedAt').IsNull then
    ATask.UpdatedAt := AQuery.FieldByName('UpdatedAt').AsDateTime;
  if not AQuery.FieldByName('CompletedAt').IsNull then
    ATask.CompletedAt := AQuery.FieldByName('CompletedAt').AsDateTime;
end;

procedure TSQLServerTaskRepository.SetTaskParams(AQuery: TFDQuery; ATask: TTask);
var
  LMappings: TArray<TColumnMapping>;
  LMapping: TColumnMapping;
begin
  LMappings := TRttiMapper.GetColumnMappings(TTask);
  for LMapping in LMappings do
  begin
    if LMapping.IsAutoIncrement or LMapping.IsReadOnly then
      Continue;
    if AQuery.Params.FindParam(LMapping.PropertyName) <> nil then
    begin
      AQuery.Params.ParamByName(LMapping.PropertyName).Value :=
        TRttiMapper.GetPropertyValue(ATask, LMapping.PropertyName).AsVariant;
    end;
  end;
end;

function TSQLServerTaskRepository.FindById(AId: Integer): TBaseEntity;
var
  LQuery: TFDQuery;
  LTask: TTask;
begin
  Result := nil;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildSelectByIdSQL(TTask);
    LQuery.ParamByName('Id').AsInteger := AId;
    LQuery.Open;

    if not LQuery.Eof then
    begin
      LTask := TTask.Create;
      MapQueryToTask(LQuery, LTask);
      Result := LTask;
    end;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerTaskRepository.FindAll: TObjectList<TBaseEntity>;
var
  LQuery: TFDQuery;
  LTask: TTask;
  LList: TObjectList<TBaseEntity>;
begin
  LList := TObjectList<TBaseEntity>.Create(True);
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildSelectAllSQL(TTask);
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LTask := TTask.Create;
      MapQueryToTask(LQuery, LTask);
      LList.Add(LTask);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
  Result := LList;
end;

function TSQLServerTaskRepository.Insert(AEntity: TBaseEntity): Integer;
var
  LQuery: TFDQuery;
  LTask: TTask;
begin
  LTask := AEntity as TTask;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildInsertSQL(TTask) +
      '; SELECT SCOPE_IDENTITY() AS NewId;';
    SetTaskParams(LQuery, LTask);
    LQuery.Open;

    Result := LQuery.FieldByName('NewId').AsInteger;
    LTask.Id := Result;
  finally
    LQuery.Free;
  end;
end;

procedure TSQLServerTaskRepository.Update(AEntity: TBaseEntity);
var
  LQuery: TFDQuery;
  LTask: TTask;
begin
  LTask := AEntity as TTask;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildUpdateSQL(TTask);
    SetTaskParams(LQuery, LTask);
    LQuery.ParamByName('Id').AsInteger := LTask.Id;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

procedure TSQLServerTaskRepository.Delete(AId: Integer);
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := TRttiMapper.BuildDeleteSQL(TTask);
    LQuery.ParamByName('Id').AsInteger := AId;
    LQuery.ExecSQL;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerTaskRepository.FindByUserId(AUserId: Integer): TObjectList<TBaseEntity>;
var
  LQuery: TFDQuery;
  LTask: TTask;
  LList: TObjectList<TBaseEntity>;
  LTable: string;
begin
  LList := TObjectList<TBaseEntity>.Create(True);
  LTable := TRttiMapper.GetTableName(TTask);
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text := Format(
      'SELECT * FROM [%s] WHERE [UserId] = :UserId ORDER BY [CreatedAt] DESC',
      [LTable]);
    LQuery.ParamByName('UserId').AsInteger := AUserId;
    LQuery.Open;

    while not LQuery.Eof do
    begin
      LTask := TTask.Create;
      MapQueryToTask(LQuery, LTask);
      LList.Add(LTask);
      LQuery.Next;
    end;
  finally
    LQuery.Free;
  end;
  Result := LList;
end;

{ Desafio SQL - Consultas executadas diretamente no SQL Server }

function TSQLServerTaskRepository.GetTotalTaskCount(AUserId: Integer): Integer;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS Total ' +
      'FROM [Tasks] ' +
      'WHERE [UserId] = :UserId';
    LQuery.ParamByName('UserId').AsInteger := AUserId;
    LQuery.Open;
    Result := LQuery.FieldByName('Total').AsInteger;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerTaskRepository.GetAveragePendingPriority(AUserId: Integer): Double;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT ISNULL(AVG(CAST([Priority] AS FLOAT)), 0) AS AvgPriority ' +
      'FROM [Tasks] ' +
      'WHERE [UserId] = :UserId AND [Status] = 0'; // 0 = Pendente
    LQuery.ParamByName('UserId').AsInteger := AUserId;
    LQuery.Open;
    Result := LQuery.FieldByName('AvgPriority').AsFloat;
  finally
    LQuery.Free;
  end;
end;

function TSQLServerTaskRepository.GetCompletedLast7Days(AUserId: Integer): Integer;
var
  LQuery: TFDQuery;
begin
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LQuery.SQL.Text :=
      'SELECT COUNT(*) AS Completed ' +
      'FROM [Tasks] ' +
      'WHERE [UserId] = :UserId ' +
      '  AND [Status] = 2 ' +        // 2 = Concluida
      '  AND [CompletedAt] >= DATEADD(DAY, -7, GETDATE())';
    LQuery.ParamByName('UserId').AsInteger := AUserId;
    LQuery.Open;
    Result := LQuery.FieldByName('Completed').AsInteger;
  finally
    LQuery.Free;
  end;
end;

end.
