unit TaskManager.Tests.TaskService;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.DateUtils,
  System.Generics.Collections,
  TaskManager.Entities.Task, TaskManager.Entities.User,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory,
  TaskManager.Services.Interfaces,
  TaskManager.Services.User,
  TaskManager.Services.Task;

type
  /// <summary>
  /// Testes unitarios para TTaskService.
  /// Valida regras de negocio: ownership, CRUD, e isolamento entre usuarios.
  /// </summary>
  [TestFixture]
  TTaskServiceTests = class
  private
    FUserRepo: IUserRepository;
    FTaskRepo: ITaskRepository;
    FUserService: IUserService;
    FTaskService: ITaskService;
    FUser1Id: Integer;
    FUser2Id: Integer;

    procedure CreateTestUsers;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // === Criacao ===

    [Test]
    procedure Test_CreateTask_Success;

    [Test]
    procedure Test_CreateTask_EmptyTitle_RaisesException;

    [Test]
    procedure Test_CreateTask_InvalidPriority_RaisesException;

    // === Listagem / Isolamento ===

    [Test]
    procedure Test_GetAllTasks_ReturnsOnlyUserTasks;

    [Test]
    procedure Test_GetAllTasks_NeverReturnsOtherUserTasks;

    // === Atualizacao de status ===

    [Test]
    procedure Test_UpdateStatus_OwnTask_Success;

    [Test]
    procedure Test_UpdateStatus_OtherUserTask_Raises403;

    [Test]
    procedure Test_UpdateStatus_Completed_SetsCompletedAt;

    // === Remocao ===

    [Test]
    procedure Test_DeleteTask_OwnTask_Success;

    [Test]
    procedure Test_DeleteTask_OtherUserTask_Raises403;

    [Test]
    procedure Test_DeleteTask_NonExistent_Raises404;

    // === Estatisticas ===

    [Test]
    procedure Test_Stats_TotalTaskCount;

    [Test]
    procedure Test_Stats_AveragePendingPriority;

    [Test]
    procedure Test_Stats_CompletedLast7Days;
  end;

implementation

{ TTaskServiceTests }

procedure TTaskServiceTests.Setup;
begin
  FUserRepo := TMemoryUserRepository.Create;
  FTaskRepo := TMemoryTaskRepository.Create;
  FUserService := TUserService.Create(FUserRepo);
  FTaskService := TTaskService.Create(FTaskRepo);
  CreateTestUsers;
end;

procedure TTaskServiceTests.TearDown;
begin
  FTaskService := nil;
  FUserService := nil;
  FTaskRepo := nil;
  FUserRepo := nil;
end;

procedure TTaskServiceTests.CreateTestUsers;
var
  LUser1, LUser2: TUser;
begin
  LUser1 := FUserService.Register('User1', 'user1@test.com', 'senha123');
  LUser2 := FUserService.Register('User2', 'user2@test.com', 'senha456');
  FUser1Id := LUser1.Id;
  FUser2Id := LUser2.Id;
end;

// === Criacao ===

procedure TTaskServiceTests.Test_CreateTask_Success;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Minha Tarefa', 'Descricao', 2);

  Assert.IsNotNull(LTask);
  Assert.IsTrue(LTask.Id > 0);
  Assert.AreEqual('Minha Tarefa', LTask.Title);
  Assert.AreEqual(FUser1Id, LTask.UserId);
  Assert.AreEqual(Ord(tsPending), LTask.Status);
end;

procedure TTaskServiceTests.Test_CreateTask_EmptyTitle_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FTaskService.CreateTask(FUser1Id, '', 'Desc', 1);
    end,
    Exception
  );
end;

procedure TTaskServiceTests.Test_CreateTask_InvalidPriority_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FTaskService.CreateTask(FUser1Id, 'Task', 'Desc', 99);
    end,
    Exception
  );
end;

// === Listagem / Isolamento ===

procedure TTaskServiceTests.Test_GetAllTasks_ReturnsOnlyUserTasks;
var
  LTasks: TObjectList<TTask>;
begin
  FTaskService.CreateTask(FUser1Id, 'Task User1 A', '', 1);
  FTaskService.CreateTask(FUser1Id, 'Task User1 B', '', 2);
  FTaskService.CreateTask(FUser2Id, 'Task User2 A', '', 1);

  LTasks := FTaskService.GetAllTasks(FUser1Id);
  try
    Assert.AreEqual(2, LTasks.Count, 'User1 deve ter exatamente 2 tarefas');
  finally
    LTasks.Free;
  end;
end;

procedure TTaskServiceTests.Test_GetAllTasks_NeverReturnsOtherUserTasks;
var
  LTasks: TObjectList<TTask>;
  LTask: TTask;
begin
  FTaskService.CreateTask(FUser1Id, 'Task A', '', 1);
  FTaskService.CreateTask(FUser2Id, 'Task B', '', 1);

  LTasks := FTaskService.GetAllTasks(FUser1Id);
  try
    for LTask in LTasks do
      Assert.AreEqual(FUser1Id, LTask.UserId,
        'Listagem nao deve conter tarefas de outro usuario');
  finally
    LTasks.Free;
  end;
end;

// === Atualizacao de status ===

procedure TTaskServiceTests.Test_UpdateStatus_OwnTask_Success;
var
  LTask, LUpdated: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Task', '', 1);
  LUpdated := FTaskService.UpdateTaskStatus(FUser1Id, LTask.Id, Ord(tsInProgress));

  Assert.AreEqual(Ord(tsInProgress), LUpdated.Status);
end;

procedure TTaskServiceTests.Test_UpdateStatus_OtherUserTask_Raises403;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Task do User1', '', 1);

  Assert.WillRaise(
    procedure
    begin
      // User2 tentando atualizar tarefa do User1 -> 403 Forbidden
      FTaskService.UpdateTaskStatus(FUser2Id, LTask.Id, Ord(tsCompleted));
    end,
    EForbiddenException,
    'Deve lancar EForbiddenException (403) ao acessar tarefa de outro usuario'
  );
end;

procedure TTaskServiceTests.Test_UpdateStatus_Completed_SetsCompletedAt;
var
  LTask, LUpdated: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Task', '', 1);
  LUpdated := FTaskService.UpdateTaskStatus(FUser1Id, LTask.Id, Ord(tsCompleted));

  Assert.AreEqual(Ord(tsCompleted), LUpdated.Status);
  Assert.IsTrue(LUpdated.CompletedAt > 0,
    'CompletedAt deve ser preenchido ao marcar como concluida');
end;

// === Remocao ===

procedure TTaskServiceTests.Test_DeleteTask_OwnTask_Success;
var
  LTask: TTask;
  LTasks: TObjectList<TTask>;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Task para remover', '', 1);
  FTaskService.DeleteTask(FUser1Id, LTask.Id);

  LTasks := FTaskService.GetAllTasks(FUser1Id);
  try
    Assert.AreEqual(0, LTasks.Count, 'Lista deve estar vazia apos remocao');
  finally
    LTasks.Free;
  end;
end;

procedure TTaskServiceTests.Test_DeleteTask_OtherUserTask_Raises403;
var
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'Task do User1', '', 1);

  Assert.WillRaise(
    procedure
    begin
      // User2 tentando remover tarefa do User1 -> 403 Forbidden
      FTaskService.DeleteTask(FUser2Id, LTask.Id);
    end,
    EForbiddenException,
    'Deve lancar EForbiddenException (403) ao remover tarefa de outro usuario'
  );
end;

procedure TTaskServiceTests.Test_DeleteTask_NonExistent_Raises404;
begin
  Assert.WillRaise(
    procedure
    begin
      FTaskService.DeleteTask(FUser1Id, 99999);
    end,
    ENotFoundException,
    'Deve lancar ENotFoundException (404) para tarefa inexistente'
  );
end;

// === Estatisticas ===

procedure TTaskServiceTests.Test_Stats_TotalTaskCount;
var
  LStats: TTaskStats;
begin
  FTaskService.CreateTask(FUser1Id, 'A', '', 1);
  FTaskService.CreateTask(FUser1Id, 'B', '', 2);
  FTaskService.CreateTask(FUser1Id, 'C', '', 3);

  LStats := FTaskService.GetStats(FUser1Id);
  Assert.AreEqual(3, LStats.TotalTasks);
end;

procedure TTaskServiceTests.Test_Stats_AveragePendingPriority;
var
  LStats: TTaskStats;
  LTask: TTask;
begin
  // Prioridades: 1, 3 pendentes; 2 concluida
  FTaskService.CreateTask(FUser1Id, 'A', '', 1); // pendente, prio 1
  FTaskService.CreateTask(FUser1Id, 'B', '', 3); // pendente, prio 3
  LTask := FTaskService.CreateTask(FUser1Id, 'C', '', 2);
  FTaskService.UpdateTaskStatus(FUser1Id, LTask.Id, Ord(tsCompleted));

  LStats := FTaskService.GetStats(FUser1Id);
  // Media das pendentes: (1 + 3) / 2 = 2.0
  Assert.AreEqual(Double(2.0), LStats.AveragePendingPriority, 0.01);
end;

procedure TTaskServiceTests.Test_Stats_CompletedLast7Days;
var
  LStats: TTaskStats;
  LTask: TTask;
begin
  LTask := FTaskService.CreateTask(FUser1Id, 'A', '', 1);
  FTaskService.UpdateTaskStatus(FUser1Id, LTask.Id, Ord(tsCompleted));

  LTask := FTaskService.CreateTask(FUser1Id, 'B', '', 2);
  FTaskService.UpdateTaskStatus(FUser1Id, LTask.Id, Ord(tsCompleted));

  FTaskService.CreateTask(FUser1Id, 'C', '', 3); // pendente, nao conta

  LStats := FTaskService.GetStats(FUser1Id);
  Assert.AreEqual(2, LStats.CompletedLast7Days);
end;

initialization
  TDUnitX.RegisterTestFixture(TTaskServiceTests);

end.
