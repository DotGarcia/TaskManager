unit TaskManager.Tests.TaskServiceTests;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.DateUtils,
  System.Generics.Collections,
  TaskManager.Entities,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory,
  TaskManager.Services.Interfaces,
  TaskManager.Services.TaskService;

type
  /// <summary>
  /// Testes unitários para o serviço de tarefas.
  /// Valida regras de negócio: isolamento entre usuários, CRUD, estatísticas.
  /// </summary>
  [TestFixture]
  TTaskServiceTests = class
  private
    FTaskRepo: ITaskRepository;
    FTaskService: ITaskService;

    // Helpers
    function CreateSampleTask(AUserId: Integer; const ATitle: string;
      APriority: Integer = 3; AStatus: TTaskStatus = tsPending): TTask;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // ===== Criação de tarefas =====

    [Test]
    [TestCase('Criar tarefa vinculada ao usuário')]
    procedure Test_CreateTask_Success;

    [Test]
    [TestCase('Criar tarefa sem título deve falhar')]
    procedure Test_CreateTask_EmptyTitle_RaisesError;

    [Test]
    [TestCase('Criar tarefa com UserId inválido deve falhar')]
    procedure Test_CreateTask_InvalidUserId_RaisesError;

    [Test]
    [TestCase('Tarefa criada deve ter status Pendente')]
    procedure Test_CreateTask_DefaultStatusIsPending;

    // ===== Listagem e isolamento entre usuários =====

    [Test]
    [TestCase('Listagem retorna apenas tarefas do usuário')]
    procedure Test_GetAllTasks_OnlyReturnsUserTasks;

    [Test]
    [TestCase('Listagem não retorna tarefas de outros usuários')]
    procedure Test_GetAllTasks_DoesNotReturnOtherUserTasks;

    // ===== Atualização de status =====

    [Test]
    [TestCase('Atualizar status de tarefa própria')]
    procedure Test_UpdateTaskStatus_OwnTask_Success;

    [Test]
    [TestCase('Atualizar tarefa de outro usuário deve retornar 403')]
    procedure Test_UpdateTaskStatus_OtherUser_RaisesForbidden;

    [Test]
    [TestCase('Atualizar tarefa inexistente deve retornar 404')]
    procedure Test_UpdateTaskStatus_NonExistent_RaisesNotFound;

    [Test]
    [TestCase('Status inválido deve retornar erro')]
    procedure Test_UpdateTaskStatus_InvalidStatus_RaisesError;

    // ===== Remoção =====

    [Test]
    [TestCase('Remover tarefa própria com sucesso')]
    procedure Test_DeleteTask_OwnTask_Success;

    [Test]
    [TestCase('Remover tarefa de outro usuário deve retornar 403')]
    procedure Test_DeleteTask_OtherUser_RaisesForbidden;

    [Test]
    [TestCase('Remover tarefa inexistente deve retornar 404')]
    procedure Test_DeleteTask_NonExistent_RaisesNotFound;

    // ===== Estatísticas (Desafio SQL) =====

    [Test]
    [TestCase('Estatísticas - total de tarefas')]
    procedure Test_GetStats_TotalTasks;

    [Test]
    [TestCase('Estatísticas - média de prioridade pendentes')]
    procedure Test_GetStats_AvgPendingPriority;

    [Test]
    [TestCase('Estatísticas - concluídas últimos 7 dias')]
    procedure Test_GetStats_CompletedLast7Days;

    [Test]
    [TestCase('Estatísticas - escopo limitado ao usuário')]
    procedure Test_GetStats_ScopedToUser;
  end;

implementation

{ TTaskServiceTests }

procedure TTaskServiceTests.Setup;
begin
  FTaskRepo := TMemoryTaskRepository.Create;
  FTaskService := TTaskService.Create(FTaskRepo);
end;

procedure TTaskServiceTests.TearDown;
begin
  FTaskService := nil;
  FTaskRepo := nil;
end;

function TTaskServiceTests.CreateSampleTask(AUserId: Integer;
  const ATitle: string; APriority: Integer; AStatus: TTaskStatus): TTask;
begin
  Result := TTask.Create;
  Result.UserId := AUserId;
  Result.Title := ATitle;
  Result.Description := 'Descrição de teste';
  Result.Priority := APriority;
  Result.Status := Ord(AStatus);
end;

// ===== Criação =====

procedure TTaskServiceTests.Test_CreateTask_Success;
var
  LTask: TTask;
begin
  LTask := CreateSampleTask(1, 'Tarefa de Teste');
  LTask := FTaskService.CreateTask(LTask);

  Assert.IsNotNull(LTask);
  Assert.IsTrue(LTask.Id > 0, 'Id deve ser atribuído após criação');
  Assert.AreEqual(1, LTask.UserId, 'UserId deve ser o do usuário autenticado');
  Assert.AreEqual('Tarefa de Teste', LTask.Title);
end;

procedure TTaskServiceTests.Test_CreateTask_EmptyTitle_RaisesError;
begin
  Assert.WillRaise(
    procedure
    var
      LTask: TTask;
    begin
      LTask := CreateSampleTask(1, '');
      FTaskService.CreateTask(LTask);
    end,
    EArgumentException
  );
end;

procedure TTaskServiceTests.Test_CreateTask_InvalidUserId_RaisesError;
begin
  Assert.WillRaise(
    procedure
    var
      LTask: TTask;
    begin
      LTask := CreateSampleTask(0, 'Tarefa Inválida');
      FTaskService.CreateTask(LTask);
    end,
    EArgumentException
  );
end;

procedure TTaskServiceTests.Test_CreateTask_DefaultStatusIsPending;
var
  LTask: TTask;
begin
  LTask := CreateSampleTask(1, 'Nova Tarefa');
  LTask := FTaskService.CreateTask(LTask);

  Assert.AreEqual(Ord(tsPending), LTask.Status,
    'Tarefa recém-criada deve ter status Pendente');
end;

// ===== Listagem e isolamento =====

procedure TTaskServiceTests.Test_GetAllTasks_OnlyReturnsUserTasks;
var
  LTasks: TObjectList<TTask>;
  LTask: TTask;
begin
  // Cria tarefas para usuário 1
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa User1 - A'));
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa User1 - B'));
  // Cria tarefas para usuário 2
  FTaskService.CreateTask(CreateSampleTask(2, 'Tarefa User2'));

  LTasks := FTaskService.GetAllTasks(1);
  try
    Assert.AreEqual(2, LTasks.Count, 'Usuário 1 deve ter exatamente 2 tarefas');

    for LTask in LTasks do
      Assert.AreEqual(1, LTask.UserId, 'Todas as tarefas devem pertencer ao usuário 1');
  finally
    LTasks.Free;
  end;
end;

procedure TTaskServiceTests.Test_GetAllTasks_DoesNotReturnOtherUserTasks;
var
  LTasks: TObjectList<TTask>;
  LTask: TTask;
begin
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa User1'));
  FTaskService.CreateTask(CreateSampleTask(2, 'Tarefa User2'));

  LTasks := FTaskService.GetAllTasks(2);
  try
    Assert.AreEqual(1, LTasks.Count);
    Assert.AreEqual('Tarefa User2', LTasks[0].Title);
    // Garante que a tarefa do user 1 NÃO aparece
    for LTask in LTasks do
      Assert.AreNotEqual(1, LTask.UserId, 'Não deve conter tarefas do usuário 1');
  finally
    LTasks.Free;
  end;
end;

// ===== Atualização de status =====

procedure TTaskServiceTests.Test_UpdateTaskStatus_OwnTask_Success;
var
  LTask: TTask;
  LResult: Boolean;
begin
  LTask := FTaskService.CreateTask(CreateSampleTask(1, 'Minha Tarefa'));

  LResult := FTaskService.UpdateTaskStatus(LTask.Id, 1, Ord(tsCompleted));

  Assert.IsTrue(LResult, 'Atualização deve retornar True');
end;

procedure TTaskServiceTests.Test_UpdateTaskStatus_OtherUser_RaisesForbidden;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa do User 1'));

  Assert.WillRaise(
    procedure
    begin
      // Usuário 2 tenta atualizar tarefa do usuário 1
      FTaskService.UpdateTaskStatus(LTask.Id, 2, Ord(tsCompleted));
    end,
    EForbiddenException,
    'Deve lançar EForbiddenException (403 Forbidden)'
  );
end;

procedure TTaskServiceTests.Test_UpdateTaskStatus_NonExistent_RaisesNotFound;
begin
  Assert.WillRaise(
    procedure
    begin
      FTaskService.UpdateTaskStatus(99999, 1, Ord(tsCompleted));
    end,
    ENotFoundException
  );
end;

procedure TTaskServiceTests.Test_UpdateTaskStatus_InvalidStatus_RaisesError;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa'));

  Assert.WillRaise(
    procedure
    begin
      FTaskService.UpdateTaskStatus(LTask.Id, 1, 99); // Status inválido
    end,
    EArgumentException
  );
end;

// ===== Remoção =====

procedure TTaskServiceTests.Test_DeleteTask_OwnTask_Success;
var
  LTask: TTask;
  LResult: Boolean;
  LTasks: TObjectList<TTask>;
begin
  LTask := FTaskService.CreateTask(CreateSampleTask(1, 'Para Remover'));

  LResult := FTaskService.DeleteTask(LTask.Id, 1);

  Assert.IsTrue(LResult, 'Remoção deve retornar True');

  // Verifica que a lista está vazia
  LTasks := FTaskService.GetAllTasks(1);
  try
    Assert.AreEqual(0, LTasks.Count, 'Lista deve estar vazia após remoção');
  finally
    LTasks.Free;
  end;
end;

procedure TTaskServiceTests.Test_DeleteTask_OtherUser_RaisesForbidden;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa do User 1'));

  Assert.WillRaise(
    procedure
    begin
      // Usuário 2 tenta remover tarefa do usuário 1
      FTaskService.DeleteTask(LTask.Id, 2);
    end,
    EForbiddenException,
    'Deve lançar EForbiddenException (403 Forbidden)'
  );
end;

procedure TTaskServiceTests.Test_DeleteTask_NonExistent_RaisesNotFound;
begin
  Assert.WillRaise(
    procedure
    begin
      FTaskService.DeleteTask(99999, 1);
    end,
    ENotFoundException
  );
end;

// ===== Estatísticas =====

procedure TTaskServiceTests.Test_GetStats_TotalTasks;
var
  LStats: TTaskStats;
begin
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa 1'));
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa 2'));
  FTaskService.CreateTask(CreateSampleTask(1, 'Tarefa 3'));

  LStats := FTaskService.GetStats(1);

  Assert.AreEqual(3, LStats.TotalTasks, 'Total deve ser 3');
end;

procedure TTaskServiceTests.Test_GetStats_AvgPendingPriority;
var
  LStats: TTaskStats;
begin
  // Cria tarefas pendentes com prioridades 1, 3, 5 → média = 3.0
  FTaskService.CreateTask(CreateSampleTask(1, 'Alta', 1, tsPending));
  FTaskService.CreateTask(CreateSampleTask(1, 'Média', 3, tsPending));
  FTaskService.CreateTask(CreateSampleTask(1, 'Baixa', 5, tsPending));

  // Cria tarefa concluída (não deve entrar na média de pendentes)
  var LTask := CreateSampleTask(1, 'Concluída', 1);
  LTask.Status := Ord(tsCompleted);
  FTaskRepo.Insert(LTask);

  LStats := FTaskService.GetStats(1);

  Assert.AreEqual(Double(3.0), LStats.AvgPendingPriority, 0.01,
    'Média de prioridade das pendentes deve ser 3.0');
end;

procedure TTaskServiceTests.Test_GetStats_CompletedLast7Days;
var
  LStats: TTaskStats;
  LTask: TTask;
begin
  // Tarefa concluída hoje (deve contar)
  LTask := CreateSampleTask(1, 'Concluída hoje');
  LTask.Status := Ord(tsCompleted);
  LTask.CompletedAt := Now;
  FTaskRepo.Insert(LTask);

  // Tarefa concluída há 3 dias (deve contar)
  LTask := CreateSampleTask(1, 'Concluída 3 dias');
  LTask.Status := Ord(tsCompleted);
  LTask.CompletedAt := IncDay(Now, -3);
  FTaskRepo.Insert(LTask);

  // Tarefa concluída há 10 dias (NÃO deve contar)
  LTask := CreateSampleTask(1, 'Concluída 10 dias');
  LTask.Status := Ord(tsCompleted);
  LTask.CompletedAt := IncDay(Now, -10);
  FTaskRepo.Insert(LTask);

  // Tarefa pendente (NÃO deve contar)
  FTaskService.CreateTask(CreateSampleTask(1, 'Pendente'));

  LStats := FTaskService.GetStats(1);

  Assert.AreEqual(2, LStats.CompletedLast7Days,
    'Deve contar apenas 2 tarefas concluídas nos últimos 7 dias');
end;

procedure TTaskServiceTests.Test_GetStats_ScopedToUser;
var
  LStats1, LStats2: TTaskStats;
begin
  // Tarefas do usuário 1
  FTaskService.CreateTask(CreateSampleTask(1, 'User1 - T1'));
  FTaskService.CreateTask(CreateSampleTask(1, 'User1 - T2'));
  FTaskService.CreateTask(CreateSampleTask(1, 'User1 - T3'));

  // Tarefas do usuário 2
  FTaskService.CreateTask(CreateSampleTask(2, 'User2 - T1'));

  LStats1 := FTaskService.GetStats(1);
  LStats2 := FTaskService.GetStats(2);

  Assert.AreEqual(3, LStats1.TotalTasks, 'User 1 deve ter 3 tarefas');
  Assert.AreEqual(1, LStats2.TotalTasks, 'User 2 deve ter 1 tarefa');
end;

initialization
  TDUnitX.RegisterTestFixture(TTaskServiceTests);

end.
