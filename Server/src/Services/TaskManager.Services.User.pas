unit TaskManager.Services.User;

interface

uses
  System.SysUtils,
  TaskManager.Entities.Base,
  TaskManager.Entities.User,
  TaskManager.Repositories.Interfaces,
  TaskManager.Services.Interfaces,
  TaskManager.Utils.Hash,
  TaskManager.Utils.JWT,
  FireDAC.DApt,
  FireDAC.Stan.Async;

type
  /// <summary>
  /// Implementacao do servico de usuarios.
  /// Gerencia cadastro (com hash de senha) e autenticacao (com JWT).
  /// </summary>
  TUserService = class(TInterfacedObject, IUserService)
  private
    FRepository: IUserRepository;
  public
    constructor Create(ARepository: IUserRepository);

    /// Cadastra um novo usuario. Lanca excecao se e-mail ja existe.
    function Register(const AName, AEmail, APassword: string): TUser;

    /// Autentica o usuario e retorna um token JWT.
    /// Lanca excecao se credenciais invalidas.
    function Login(const AEmail, APassword: string): string;
  end;

implementation

{ TUserService }

constructor TUserService.Create(ARepository: IUserRepository);
begin
  inherited Create;
  FRepository := ARepository;
end;

function TUserService.Register(const AName, AEmail, APassword: string): TUser;
var
  LExisting: TBaseEntity;
  LUser: TUser;
  LSalt: string;
begin
  // Validacoes basicas
  if AName.Trim.IsEmpty then
    raise Exception.Create('Nome e obrigatorio');
  if AEmail.Trim.IsEmpty then
    raise Exception.Create('E-mail e obrigatorio');
  if APassword.Trim.IsEmpty then
    raise Exception.Create('Senha e obrigatoria');
  if Length(APassword) < 6 then
    raise Exception.Create('Senha deve ter pelo menos 6 caracteres');

  // Verificar se e-mail ja existe
  LExisting := FRepository.FindByEmail(AEmail);
  if Assigned(LExisting) then
    raise Exception.Create('E-mail ja cadastrado');

  // Criar usuario com senha hasheada
  LSalt := TPasswordHasher.GenerateSalt;

  LUser := TUser.Create;
  try
    LUser.Name := AName.Trim;
    LUser.Email := AEmail.Trim.ToLower;
    LUser.Salt := LSalt;
    LUser.PasswordHash := TPasswordHasher.HashPassword(APassword, LSalt);

    FRepository.Insert(LUser);
    Result := LUser;
  except
    LUser.Free;
    raise;
  end;
end;

function TUserService.Login(const AEmail, APassword: string): string;
var
  LEntity: TBaseEntity;
  LUser: TUser;
begin
  if AEmail.Trim.IsEmpty or APassword.Trim.IsEmpty then
    raise Exception.Create('E-mail e senha sao obrigatorios');

  LEntity := FRepository.FindByEmail(AEmail.Trim.ToLower);
  if not Assigned(LEntity) then
    raise Exception.Create('Credenciais invalidas');

  LUser := LEntity as TUser;

  // Verificar senha
  if not TPasswordHasher.VerifyPassword(APassword, LUser.Salt, LUser.PasswordHash) then
    raise Exception.Create('Credenciais invalidas');

  // Gerar e retornar token JWT
  Result := TJWTHelper.GenerateToken(LUser.Id, LUser.Email);
end;

end.
