unit TaskManager.Tests.UserService;

interface

uses
  DUnitX.TestFramework, System.SysUtils,
  TaskManager.Entities.User,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory,
  TaskManager.Services.Interfaces,
  TaskManager.Services.User,
  TaskManager.Utils.JWT;

type
  /// <summary>
  /// Testes unitarios para TUserService.
  /// Utiliza repositorio em memoria (mock) - sem dependencia de banco.
  /// </summary>
  [TestFixture]
  TUserServiceTests = class
  private
    FUserRepo: IUserRepository;
    FService: IUserService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // === Caminho feliz ===

    [Test]
    procedure Test_Register_Success;

    [Test]
    procedure Test_Login_Success_Returns_JWT;

    // === Caminho de erro ===

    [Test]
    procedure Test_Register_DuplicateEmail_RaisesException;

    [Test]
    procedure Test_Login_WrongPassword_RaisesException;

    [Test]
    procedure Test_Login_NonExistentEmail_RaisesException;

    [Test]
    procedure Test_Register_EmptyName_RaisesException;

    [Test]
    procedure Test_Register_ShortPassword_RaisesException;
  end;

implementation

{ TUserServiceTests }

procedure TUserServiceTests.Setup;
begin
  FUserRepo := TMemoryUserRepository.Create;
  FService := TUserService.Create(FUserRepo);
end;

procedure TUserServiceTests.TearDown;
begin
  FService := nil;
  FUserRepo := nil;
end;

procedure TUserServiceTests.Test_Register_Success;
var
  LUser: TUser;
begin
  LUser := FService.Register('Garcia', 'garcia@test.com', 'senha123');
  Assert.IsNotNull(LUser, 'Usuario nao deve ser nulo');
  Assert.IsTrue(LUser.Id > 0, 'Id deve ser gerado');
  Assert.AreEqual('Garcia', LUser.Name);
  Assert.AreEqual('garcia@test.com', LUser.Email);
  Assert.IsNotEmpty(LUser.PasswordHash, 'Hash nao deve estar vazio');
  Assert.IsNotEmpty(LUser.Salt, 'Salt nao deve estar vazio');
end;

procedure TUserServiceTests.Test_Login_Success_Returns_JWT;
var
  LToken: string;
  LPayload: TJWTPayload;
begin
  FService.Register('Garcia', 'garcia@test.com', 'senha123');

  LToken := FService.Login('garcia@test.com', 'senha123');

  Assert.IsNotEmpty(LToken, 'Token nao deve estar vazio');

  // Validar que o token e um JWT valido
  LPayload := TJWTHelper.ValidateToken(LToken);
  Assert.IsTrue(LPayload.IsValid, 'Token deve ser valido');
  Assert.AreEqual('garcia@test.com', LPayload.Email);
  Assert.IsTrue(LPayload.UserId > 0, 'UserId deve ser positivo');
end;

procedure TUserServiceTests.Test_Register_DuplicateEmail_RaisesException;
begin
  FService.Register('Garcia', 'garcia@test.com', 'senha123');

  Assert.WillRaise(
    procedure
    begin
      FService.Register('Outro', 'garcia@test.com', 'outrasenha');
    end,
    Exception
  );
end;

procedure TUserServiceTests.Test_Login_WrongPassword_RaisesException;
begin
  FService.Register('Garcia', 'garcia@test.com', 'senha123');

  Assert.WillRaise(
    procedure
    begin
      FService.Login('garcia@test.com', 'senhaerrada');
    end,
    Exception
  );
end;

procedure TUserServiceTests.Test_Login_NonExistentEmail_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.Login('naoexiste@test.com', 'qualquersenha');
    end,
    Exception
  );
end;

procedure TUserServiceTests.Test_Register_EmptyName_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.Register('', 'test@test.com', 'senha123');
    end,
    Exception
  );
end;

procedure TUserServiceTests.Test_Register_ShortPassword_RaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      FService.Register('Garcia', 'test@test.com', '123');
    end,
    Exception
  );
end;

initialization
  TDUnitX.RegisterTestFixture(TUserServiceTests);

end.
