unit TaskManager.Tests.UserServiceTests;

interface

uses
  DUnitX.TestFramework, System.SysUtils,
  TaskManager.Entities,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory,
  TaskManager.Services.Interfaces,
  TaskManager.Services.UserService,
  TaskManager.Utils.JWT;

type
  /// <summary>
  /// Testes unitários para o serviço de usuários.
  /// Utiliza repositório em memória (mock) sem dependência de banco de dados.
  /// </summary>
  [TestFixture]
  TUserServiceTests = class
  private
    FUserRepo: IUserRepository;
    FJWTManager: TJWTManager;
    FUserService: IUserService;
  public
    [Setup]
    procedure Setup;

    [TearDown]
    procedure TearDown;

    // ===== Caminho feliz =====

    [Test]
    [TestCase('Cadastro válido')]
    procedure Test_Register_Success;

    [Test]
    [TestCase('Login válido retorna token JWT')]
    procedure Test_Login_Success_ReturnsJWT;

    [Test]
    [TestCase('Login válido retorna UserId correto')]
    procedure Test_Login_Success_ReturnsCorrectUserId;

    // ===== Caminho de erro =====

    [Test]
    [TestCase('Cadastro com e-mail duplicado deve falhar')]
    procedure Test_Register_DuplicateEmail_RaisesConflict;

    [Test]
    [TestCase('Cadastro com nome vazio deve falhar')]
    procedure Test_Register_EmptyName_RaisesError;

    [Test]
    [TestCase('Cadastro com e-mail vazio deve falhar')]
    procedure Test_Register_EmptyEmail_RaisesError;

    [Test]
    [TestCase('Cadastro com senha vazia deve falhar')]
    procedure Test_Register_EmptyPassword_RaisesError;

    [Test]
    [TestCase('Login com senha incorreta deve falhar')]
    procedure Test_Login_WrongPassword_Fails;

    [Test]
    [TestCase('Login com e-mail inexistente deve falhar')]
    procedure Test_Login_NonExistentEmail_Fails;

    [Test]
    [TestCase('Senha é armazenada como hash, não em texto puro')]
    procedure Test_Register_PasswordIsHashed;
  end;

implementation

{ TUserServiceTests }

procedure TUserServiceTests.Setup;
begin
  FUserRepo := TMemoryUserRepository.Create;
  FJWTManager := TJWTManager.Create('test_secret_key_12345');
  FUserService := TUserService.Create(FUserRepo, FJWTManager);
end;

procedure TUserServiceTests.TearDown;
begin
  FJWTManager.Free;
  FUserService := nil;
  FUserRepo := nil;
end;

procedure TUserServiceTests.Test_Register_Success;
var
  LUser: TUser;
begin
  LUser := FUserService.Register('João Silva', 'joao@email.com', 'senha123');

  Assert.IsNotNull(LUser, 'Usuário não deve ser nulo');
  Assert.IsTrue(LUser.Id > 0, 'Id deve ser maior que zero');
  Assert.AreEqual('João Silva', LUser.Name);
  Assert.AreEqual('joao@email.com', LUser.Email);
end;

procedure TUserServiceTests.Test_Login_Success_ReturnsJWT;
var
  LResult: TAuthResult;
begin
  FUserService.Register('Maria', 'maria@email.com', 'senha456');

  LResult := FUserService.Login('maria@email.com', 'senha456');

  Assert.IsTrue(LResult.Success, 'Login deve ser bem-sucedido');
  Assert.IsNotEmpty(LResult.Token, 'Token JWT não deve estar vazio');
  Assert.IsTrue(LResult.Token.Contains('.'), 'Token deve ter formato JWT (com pontos)');
end;

procedure TUserServiceTests.Test_Login_Success_ReturnsCorrectUserId;
var
  LUser: TUser;
  LResult: TAuthResult;
begin
  LUser := FUserService.Register('Carlos', 'carlos@email.com', 'senha789');
  LResult := FUserService.Login('carlos@email.com', 'senha789');

  Assert.IsTrue(LResult.Success);
  Assert.AreEqual(LUser.Id, LResult.UserId, 'UserId do login deve coincidir com o do cadastro');
end;

procedure TUserServiceTests.Test_Register_DuplicateEmail_RaisesConflict;
begin
  FUserService.Register('User 1', 'duplicado@email.com', 'senha1');

  Assert.WillRaise(
    procedure
    begin
      FUserService.Register('User 2', 'duplicado@email.com', 'senha2');
    end,
    EConflictException,
    'Deve lançar EConflictException para e-mail duplicado'
  );
end;

procedure TUserServiceTests.Test_Register_EmptyName_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FUserService.Register('', 'teste@email.com', 'senha');
    end,
    EArgumentException
  );
end;

procedure TUserServiceTests.Test_Register_EmptyEmail_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FUserService.Register('Nome', '', 'senha');
    end,
    EArgumentException
  );
end;

procedure TUserServiceTests.Test_Register_EmptyPassword_RaisesError;
begin
  Assert.WillRaise(
    procedure
    begin
      FUserService.Register('Nome', 'teste@email.com', '');
    end,
    EArgumentException
  );
end;

procedure TUserServiceTests.Test_Login_WrongPassword_Fails;
var
  LResult: TAuthResult;
begin
  FUserService.Register('Ana', 'ana@email.com', 'senhaCorreta');

  LResult := FUserService.Login('ana@email.com', 'senhaErrada');

  Assert.IsFalse(LResult.Success, 'Login com senha errada deve falhar');
  Assert.IsEmpty(LResult.Token, 'Token deve estar vazio em caso de falha');
  Assert.IsNotEmpty(LResult.ErrorMessage, 'Deve haver mensagem de erro');
end;

procedure TUserServiceTests.Test_Login_NonExistentEmail_Fails;
var
  LResult: TAuthResult;
begin
  LResult := FUserService.Login('naoexiste@email.com', 'qualquersenha');

  Assert.IsFalse(LResult.Success, 'Login com e-mail inexistente deve falhar');
  Assert.IsEmpty(LResult.Token);
end;

procedure TUserServiceTests.Test_Register_PasswordIsHashed;
var
  LUser: TUser;
begin
  LUser := FUserService.Register('Pedro', 'pedro@email.com', 'minhasenha');

  Assert.AreNotEqual('minhasenha', LUser.Password,
    'Senha não deve ser armazenada em texto puro');
  Assert.IsNotEmpty(LUser.Salt, 'Salt deve estar preenchido');
end;

initialization
  TDUnitX.RegisterTestFixture(TUserServiceTests);

end.
