unit TaskManager.Services.UserService;

interface

uses
  System.SysUtils,
  TaskManager.Entities,
  TaskManager.Repositories.Interfaces,
  TaskManager.Services.Interfaces,
  TaskManager.Utils.Hash,
  TaskManager.Utils.JWT;

type
  /// <summary>
  /// Exceção lançada quando há conflito de dados (ex: e-mail duplicado).
  /// </summary>
  EConflictException = class(Exception);

  /// <summary>
  /// Exceção de autenticação inválida.
  /// </summary>
  EAuthenticationException = class(Exception);

  /// <summary>
  /// Implementação do serviço de usuários.
  /// Regras de negócio: cadastro com validação de e-mail único,
  /// autenticação com hash de senha e geração de JWT.
  /// </summary>
  TUserService = class(TInterfacedObject, IUserService)
  private
    FUserRepository: IUserRepository;
    FJWTManager: TJWTManager;
  public
    constructor Create(AUserRepository: IUserRepository; AJWTManager: TJWTManager);

    function Register(const AName, AEmail, APassword: string): TUser;
    function Login(const AEmail, APassword: string): TAuthResult;
    function GetUserById(AId: Integer): TUser;
  end;

implementation

{ TUserService }

constructor TUserService.Create(AUserRepository: IUserRepository; AJWTManager: TJWTManager);
begin
  inherited Create;
  FUserRepository := AUserRepository;
  FJWTManager := AJWTManager;
end;

function TUserService.Register(const AName, AEmail, APassword: string): TUser;
var
  LExisting: TUser;
  LUser: TUser;
  LSalt: string;
begin
  // Validação de campos obrigatórios
  if AName.Trim.IsEmpty then
    raise EArgumentException.Create('Nome é obrigatório');
  if AEmail.Trim.IsEmpty then
    raise EArgumentException.Create('E-mail é obrigatório');
  if APassword.Trim.IsEmpty then
    raise EArgumentException.Create('Senha é obrigatória');

  // Verifica se e-mail já está cadastrado
  LExisting := FUserRepository.FindByEmail(AEmail);
  if LExisting <> nil then
    raise EConflictException.Create('E-mail já cadastrado');

  // Cria o usuário com senha hashada
  LUser := TUser.Create;
  try
    LUser.Name := AName.Trim;
    LUser.Email := AEmail.Trim.ToLower;

    LSalt := TPasswordHasher.GenerateSalt;
    LUser.Salt := LSalt;
    LUser.Password := TPasswordHasher.HashPassword(APassword, LSalt);

    Result := FUserRepository.Insert(LUser);
  except
    LUser.Free;
    raise;
  end;
end;

function TUserService.Login(const AEmail, APassword: string): TAuthResult;
var
  LUser: TUser;
begin
  Result.Success := False;
  Result.Token := '';
  Result.UserId := 0;
  Result.UserName := '';
  Result.ErrorMessage := '';

  // Busca usuário pelo e-mail
  LUser := FUserRepository.FindByEmail(AEmail.Trim.ToLower);
  if LUser = nil then
  begin
    Result.ErrorMessage := 'Credenciais inválidas';
    Exit;
  end;

  // Verifica senha
  if not TPasswordHasher.VerifyPassword(APassword, LUser.Salt, LUser.Password) then
  begin
    Result.ErrorMessage := 'Credenciais inválidas';
    Exit;
  end;

  // Gera token JWT
  Result.Success := True;
  Result.UserId := LUser.Id;
  Result.UserName := LUser.Name;
  Result.Token := FJWTManager.GenerateToken(LUser.Id, LUser.Name);
end;

function TUserService.GetUserById(AId: Integer): TUser;
begin
  Result := FUserRepository.FindById(AId);
end;

end.
