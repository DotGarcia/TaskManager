unit TaskManager.Repositories.Memory;

interface

uses
  System.SysUtils, System.Generics.Collections, System.DateUtils,
  TaskManager.Entities.Base, TaskManager.Entities.User, TaskManager.Entities.Task,
  TaskManager.Repositories.Interfaces;

type
  /// <summary>
  /// Repositorio em memoria para Usuarios.
  /// Implementacao mock para testes unitarios (sem dependencia de banco).
  /// Demonstra Polimorfismo: mesma interface IUserRepository, implementacao diferente.
  /// </summary>
  TMemoryUserRepository = class(TInterfacedObject, IUserRepository)
  private
    FItems: TObjectList<TUser>;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByEmail(const AEmail: string): TBaseEntity;
  end;

  /// <summary>
  /// Repositorio em memoria para Tarefas.
  /// Inclui implementacao das estatisticas SQL (simuladas em memoria).
  /// </summary>
  TMemoryTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FItems: TObjectList<TTask>;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByUserId(AUserId: Integer): TObjectList<TBaseEntity>;

    // Estatisticas
    function GetTotalTaskCount(AUserId: Integer): Integer;
    function GetAveragePendingPriority(AUserId: Integer): Double;
    function GetCompletedLast7Days(AUserId: Integer): Integer;
  end;

implementation

{ TMemoryUserRepository }

constructor TMemoryUserRepository.Create;
begin
  inherited Create;
  FItems := TObjectList<TUser>.Create(False);
  FNextId := 1;
end;

destructor TMemoryUserRepository.Destroy;
var
  LUser: TUser;
begin
  for LUser in FItems do
    LUser.Free;
  FItems.Free;
  inherited;
end;

function TMemoryUserRepository.FindById(AId: Integer): TBaseEntity;
var
  LUser: TUser;
begin
  Result := nil;
  for LUser in FItems do
  begin
    if LUser.Id = AId then
      Exit(LUser);
  end;
end;

function TMemoryUserRepository.FindAll: TObjectList<TBaseEntity>;
var
  LUser: TUser;
  LResult: TObjectList<TBaseEntity>;
begin
  LResult := TObjectList<TBaseEntity>.Create(False);
  for LUser in FItems do
    LResult.Add(LUser);
  Result := LResult;
end;

function TMemoryUserRepository.Insert(AEntity: TBaseEntity): Integer;
var
  LUser: TUser;
begin
  LUser := AEntity as TUser;
  LUser.Id := FNextId;
  Inc(FNextId);
  FItems.Add(LUser);
  Result := LUser.Id;
end;

procedure TMemoryUserRepository.Update(AEntity: TBaseEntity);
var
  I: Integer;
  LUser: TUser;
begin
  LUser := AEntity as TUser;
  for I := 0 to FItems.Count - 1 do
  begin
    if FItems[I].Id = LUser.Id then
    begin
      FItems[I] := LUser;
      Exit;
    end;
  end;
  raise Exception.CreateFmt('User with Id %d not found', [LUser.Id]);
end;

procedure TMemoryUserRepository.Delete(AId: Integer);
var
  I: Integer;
begin
  for I := FItems.Count - 1 downto 0 do
  begin
    if FItems[I].Id = AId then
    begin
      FItems[I].Free;
      FItems.Delete(I);
      Exit;
    end;
  end;
  raise Exception.CreateFmt('User with Id %d not found', [AId]);
end;

function TMemoryUserRepository.FindByEmail(const AEmail: string): TBaseEntity;
var
  LUser: TUser;
begin
  Result := nil;
  for LUser in FItems do
  begin
    if SameText(LUser.Email, AEmail) then
      Exit(LUser);
  end;
end;

{ TMemoryTaskRepository }

constructor TMemoryTaskRepository.Create;
begin
  inherited Create;
  FItems := TObjectList<TTask>.Create(False);
  FNextId := 1;
end;

destructor TMemoryTaskRepository.Destroy;
var
  LTask: TTask;
begin
  for LTask in FItems do
    LTask.Free;
  FItems.Free;
  inherited;
end;

function TMemoryTaskRepository.FindById(AId: Integer): TBaseEntity;
var
  LTask: TTask;
begin
  Result := nil;
  for LTask in FItems do
  begin
    if LTask.Id = AId then
      Exit(LTask);
  end;
end;

function TMemoryTaskRepository.FindAll: TObjectList<TBaseEntity>;
var
  LTask: TTask;
  LResult: TObjectList<TBaseEntity>;
begin
  LResult := TObjectList<TBaseEntity>.Create(False);
  for LTask in FItems do
    LResult.Add(LTask);
  Result := LResult;
end;

function TMemoryTaskRepository.Insert(AEntity: TBaseEntity): Integer;
var
  LTask: TTask;
begin
  LTask := AEntity as TTask;
  LTask.Id := FNextId;
  Inc(FNextId);
  FItems.Add(LTask);
  Result := LTask.Id;
end;

procedure TMemoryTaskRepository.Update(AEntity: TBaseEntity);
var
  I: Integer;
  LTask: TTask;
begin
  LTask := AEntity as TTask;
  for I := 0 to FItems.Count - 1 do
  begin
    if FItems[I].Id = LTask.Id then
    begin
      FItems[I] := LTask;
      Exit;
    end;
  end;
  raise Exception.CreateFmt('Task with Id %d not found', [LTask.Id]);
end;

procedure TMemoryTaskRepository.Delete(AId: Integer);
var
  I: Integer;
begin
  for I := FItems.Count - 1 downto 0 do
  begin
    if FItems[I].Id = AId then
    begin
      FItems[I].Free;
      FItems.Delete(I);
      Exit;
    end;
  end;
  raise Exception.CreateFmt('Task with Id %d not found', [AId]);
end;

function TMemoryTaskRepository.FindByUserId(AUserId: Integer): TObjectList<TBaseEntity>;
var
  LTask: TTask;
  LResult: TObjectList<TBaseEntity>;
begin
  LResult := TObjectList<TBaseEntity>.Create(False);
  for LTask in FItems do
  begin
    if LTask.UserId = AUserId then
      LResult.Add(LTask);
  end;
  Result := LResult;
end;

function TMemoryTaskRepository.GetTotalTaskCount(AUserId: Integer): Integer;
var
  LTask: TTask;
begin
  Result := 0;
  for LTask in FItems do
  begin
    if LTask.UserId = AUserId then
      Inc(Result);
  end;
end;

function TMemoryTaskRepository.GetAveragePendingPriority(AUserId: Integer): Double;
var
  LTask: TTask;
  LSum, LCount: Integer;
begin
  LSum := 0;
  LCount := 0;
  for LTask in FItems do
  begin
    if (LTask.UserId = AUserId) and (LTask.Status = Ord(tsPending)) then
    begin
      LSum := LSum + LTask.Priority;
      Inc(LCount);
    end;
  end;

  if LCount > 0 then
    Result := LSum / LCount
  else
    Result := 0;
end;

function TMemoryTaskRepository.GetCompletedLast7Days(AUserId: Integer): Integer;
var
  LTask: TTask;
  LCutoff: TDateTime;
begin
  Result := 0;
  LCutoff := IncDay(Now, -7);
  for LTask in FItems do
  begin
    if (LTask.UserId = AUserId) and
       (LTask.Status = Ord(tsCompleted)) and
       (LTask.CompletedAt >= LCutoff) then
      Inc(Result);
  end;
end;

end.
