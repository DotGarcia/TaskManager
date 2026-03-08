unit TaskManager.Tests.MemoryRepositoryTests;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Generics.Collections,
  TaskManager.Entities,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory;

type
  /// <summary>
  /// Testes unitários para o repositório em memória (mock).
  /// Valida que a implementação da interface IRepository<T> funciona corretamente.
  /// </summary>
  [TestFixture]
  TMemoryRepositoryTests = class
  private
    FUserRepo: IUserRepository;
    FTaskRepo: ITaskRepository;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // ===== Repositório de Usuários =====

    [Test]
    procedure Test_UserRepo_Insert_AssignsId;

    [Test]
    procedure Test_UserRepo_FindById_ReturnsCorrectUser;

    [Test]
    procedure Test_UserRepo_FindById_ReturnsNilIfNotFound;

    [Test]
    procedure Test_UserRepo_FindByEmail_ReturnsCorrectUser;

    [Test]
    procedure Test_UserRepo_FindByEmail_CaseInsensitive;

    [Test]
    procedure Test_UserRepo_Update_ModifiesData;

    [Test]
    procedure Test_UserRepo_Delete_RemovesUser;

    [Test]
    procedure Test_UserRepo_FindAll_ReturnsAllUsers;

    // ===== Repositório de Tarefas =====

    [Test]
    procedure Test_TaskRepo_Insert_AssignsId;

    [Test]
    procedure Test_TaskRepo_FindByUserId_FiltersCorrectly;

    [Test]
    procedure Test_TaskRepo_CountByUserId_ReturnsCorrectCount;

    [Test]
    procedure Test_TaskRepo_Delete_RemovesTask;

    [Test]
    procedure Test_TaskRepo_Update_ModifiesData;
  end;

implementation

procedure TMemoryRepositoryTests.Setup;
begin
  FUserRepo := TMemoryUserRepository.Create;
  FTaskRepo := TMemoryTaskRepository.Create;
end;

procedure TMemoryRepositoryTests.TearDown;
begin
  FUserRepo := nil;
  FTaskRepo := nil;
end;

// ===== User Repository =====

procedure TMemoryRepositoryTests.Test_UserRepo_Insert_AssignsId;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Teste';
  LUser.Email := 'teste@test.com';
  LUser := FUserRepo.Insert(LUser);

  Assert.IsTrue(LUser.Id > 0);
end;

procedure TMemoryRepositoryTests.Test_UserRepo_FindById_ReturnsCorrectUser;
var
  LUser, LFound: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Busca por ID';
  LUser.Email := 'busca@test.com';
  LUser := FUserRepo.Insert(LUser);

  LFound := FUserRepo.FindById(LUser.Id);

  Assert.IsNotNull(LFound);
  Assert.AreEqual(LUser.Id, LFound.Id);
  Assert.AreEqual('Busca por ID', LFound.Name);
end;

procedure TMemoryRepositoryTests.Test_UserRepo_FindById_ReturnsNilIfNotFound;
begin
  Assert.IsNull(FUserRepo.FindById(99999));
end;

procedure TMemoryRepositoryTests.Test_UserRepo_FindByEmail_ReturnsCorrectUser;
var
  LUser, LFound: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Email Test';
  LUser.Email := 'email@test.com';
  FUserRepo.Insert(LUser);

  LFound := FUserRepo.FindByEmail('email@test.com');

  Assert.IsNotNull(LFound);
  Assert.AreEqual('Email Test', LFound.Name);
end;

procedure TMemoryRepositoryTests.Test_UserRepo_FindByEmail_CaseInsensitive;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Case Test';
  LUser.Email := 'UPPER@TEST.COM';
  FUserRepo.Insert(LUser);

  Assert.IsNotNull(FUserRepo.FindByEmail('upper@test.com'),
    'Busca por e-mail deve ser case-insensitive');
end;

procedure TMemoryRepositoryTests.Test_UserRepo_Update_ModifiesData;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Original';
  LUser.Email := 'update@test.com';
  LUser := FUserRepo.Insert(LUser);

  LUser.Name := 'Modificado';
  Assert.IsTrue(FUserRepo.Update(LUser));

  Assert.AreEqual('Modificado', FUserRepo.FindById(LUser.Id).Name);
end;

procedure TMemoryRepositoryTests.Test_UserRepo_Delete_RemovesUser;
var
  LUser: TUser;
begin
  LUser := TUser.Create;
  LUser.Name := 'Delete';
  LUser.Email := 'delete@test.com';
  LUser := FUserRepo.Insert(LUser);

  Assert.IsTrue(FUserRepo.Delete(LUser.Id));
  Assert.IsNull(FUserRepo.FindById(LUser.Id));
end;

procedure TMemoryRepositoryTests.Test_UserRepo_FindAll_ReturnsAllUsers;
var
  LUser: TUser;
  LAll: TObjectList<TUser>;
begin
  LUser := TUser.Create;
  LUser.Name := 'User 1';
  LUser.Email := 'user1@test.com';
  FUserRepo.Insert(LUser);

  LUser := TUser.Create;
  LUser.Name := 'User 2';
  LUser.Email := 'user2@test.com';
  FUserRepo.Insert(LUser);

  LAll := FUserRepo.FindAll;
  try
    Assert.AreEqual(2, LAll.Count);
  finally
    LAll.Free;
  end;
end;

// ===== Task Repository =====

procedure TMemoryRepositoryTests.Test_TaskRepo_Insert_AssignsId;
var
  LTask: TTask;
begin
  LTask := TTask.Create;
  LTask.UserId := 1;
  LTask.Title := 'Test Task';
  LTask := FTaskRepo.Insert(LTask);

  Assert.IsTrue(LTask.Id > 0);
end;

procedure TMemoryRepositoryTests.Test_TaskRepo_FindByUserId_FiltersCorrectly;
var
  LTask: TTask;
  LResult: TObjectList<TTask>;
begin
  LTask := TTask.Create;
  LTask.UserId := 1;
  LTask.Title := 'User 1 Task';
  FTaskRepo.Insert(LTask);

  LTask := TTask.Create;
  LTask.UserId := 2;
  LTask.Title := 'User 2 Task';
  FTaskRepo.Insert(LTask);

  LResult := FTaskRepo.FindByUserId(1);
  try
    Assert.AreEqual(1, LResult.Count);
    Assert.AreEqual('User 1 Task', LResult[0].Title);
  finally
    LResult.Free;
  end;
end;

procedure TMemoryRepositoryTests.Test_TaskRepo_CountByUserId_ReturnsCorrectCount;
var
  LTask: TTask;
begin
  LTask := TTask.Create;
  LTask.UserId := 5;
  LTask.Title := 'T1';
  FTaskRepo.Insert(LTask);

  LTask := TTask.Create;
  LTask.UserId := 5;
  LTask.Title := 'T2';
  FTaskRepo.Insert(LTask);

  Assert.AreEqual(2, FTaskRepo.CountByUserId(5));
  Assert.AreEqual(0, FTaskRepo.CountByUserId(99));
end;

procedure TMemoryRepositoryTests.Test_TaskRepo_Delete_RemovesTask;
var
  LTask: TTask;
begin
  LTask := TTask.Create;
  LTask.UserId := 1;
  LTask.Title := 'To Delete';
  LTask := FTaskRepo.Insert(LTask);

  Assert.IsTrue(FTaskRepo.Delete(LTask.Id));
  Assert.IsNull(FTaskRepo.FindById(LTask.Id));
end;

procedure TMemoryRepositoryTests.Test_TaskRepo_Update_ModifiesData;
var
  LTask: TTask;
begin
  LTask := TTask.Create;
  LTask.UserId := 1;
  LTask.Title := 'Original';
  LTask := FTaskRepo.Insert(LTask);

  LTask.Title := 'Updated';
  LTask.Status := Ord(tsCompleted);
  Assert.IsTrue(FTaskRepo.Update(LTask));

  Assert.AreEqual('Updated', FTaskRepo.FindById(LTask.Id).Title);
  Assert.AreEqual(Ord(tsCompleted), FTaskRepo.FindById(LTask.Id).Status);
end;

initialization
  TDUnitX.RegisterTestFixture(TMemoryRepositoryTests);

end.
