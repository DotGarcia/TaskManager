{ ============================================================================ }
{ TaskManagerServer                                                            }
{                                                                              }
{ Servidor REST API do TaskManager BDMG.                                       }
{ Framework Horse + MVC + JWT.                                                 }
{                                                                              }
{ Configuracao via server-config.json:                                         }
{   - Conexao SQL Server (driver, servidor, banco, autenticacao)               }
{   - Porta do servidor HTTP                                                   }
{   - Chave secreta e expiracao do JWT                                         }
{ ============================================================================ }
program TaskManagerServer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  { RTL / System }
  FireDAC.Comp.Client,
  FireDAC.Phys.MSSQL,
  FireDAC.Phys.MSSQLDef,
  FireDAC.Stan.Def,
  System.JSON,
  System.SysUtils,

  { Frameworks }
  Horse,
  Horse.Jhonson,

  { Config }
  TaskManager.Config.Server in 'src\Config\TaskManager.Config.Server.pas',

  { Entities (Model) }
  TaskManager.Attributes in 'src\Attributes\TaskManager.Attributes.pas',
  TaskManager.Entities.Base in 'src\Entities\TaskManager.Entities.Base.pas',
  TaskManager.Entities.Task in 'src\Entities\TaskManager.Entities.Task.pas',
  TaskManager.Entities.User in 'src\Entities\TaskManager.Entities.User.pas',

  { Repositories (Data Access) }
  TaskManager.Repositories.Interfaces in 'src\Repositories\TaskManager.Repositories.Interfaces.pas',
  TaskManager.Repositories.Memory in 'src\Repositories\TaskManager.Repositories.Memory.pas',
  TaskManager.Repositories.SQLServer in 'src\Repositories\TaskManager.Repositories.SQLServer.pas',
  TaskManager.RTTI.Mapper in 'src\Repositories\TaskManager.RTTI.Mapper.pas',

  { Services (Business Logic) }
  TaskManager.Services.Interfaces in 'src\Services\TaskManager.Services.Interfaces.pas',
  TaskManager.Services.Task in 'src\Services\TaskManager.Services.Task.pas',
  TaskManager.Services.User in 'src\Services\TaskManager.Services.User.pas',

  { Factories }
  TaskManager.Factories in 'src\Factories\TaskManager.Factories.pas',

  { Middleware }
  TaskManager.Middleware.Auth in 'src\Middleware\TaskManager.Middleware.Auth.pas',

  { Controllers }
  TaskManager.Controllers.Task in 'src\Controllers\TaskManager.Controllers.Task.pas',
  TaskManager.Controllers.User in 'src\Controllers\TaskManager.Controllers.User.pas',

  { Utils }
  TaskManager.Utils.Hash in 'src\Utils\TaskManager.Utils.Hash.pas',
  TaskManager.Utils.JWT in 'src\Utils\TaskManager.Utils.JWT.pas';

var
  LConnection: TFDConnection;
  LUserRepository: IUserRepository;
  LTaskRepository: ITaskRepository;
  LUserService: IUserService;
  LTaskService: ITaskService;
  LUserController: TUserController;
  LTaskController: TTaskController;
  LDatabaseConfig: TDatabaseConfig;
  LServerPort: Integer;

{ Configura a conexao FireDAC com SQL Server a partir do JSON }
procedure ConfigureDatabase;
begin
  LDatabaseConfig := TServerConfig.DatabaseConfig;

  LConnection := TFDConnection.Create(nil);
  LConnection.Params.DriverID := LDatabaseConfig.DriverID;
  LConnection.Params.Database := LDatabaseConfig.Database;
  LConnection.Params.Values['Server'] := LDatabaseConfig.Server;

  case LDatabaseConfig.Authentication of
    atWindows:
    begin
      LConnection.Params.Values['OSAuthent'] := 'Yes';
      Writeln('[DB] Autenticacao: Windows (usuario logado)');
    end;
    atSQLServer:
    begin
      LConnection.Params.Values['OSAuthent'] := 'No';
      LConnection.Params.UserName := LDatabaseConfig.Username;
      LConnection.Params.Password := LDatabaseConfig.Password;
      Writeln('[DB] Autenticacao: SQL Server (' + LDatabaseConfig.Username + ')');
    end;
  end;

  LConnection.Params.Add('Encrypt=' + LDatabaseConfig.Encrypt);
  LConnection.Params.Add('TrustServerCertificate=' + LDatabaseConfig.TrustServerCertificate);
  LConnection.LoginPrompt := False;
  LConnection.Connected := True;

  Writeln('[DB] Conectado: ' + LDatabaseConfig.Server + '/' + LDatabaseConfig.Database);
end;

begin
  try
    Writeln('===========================================');
    Writeln('  TaskManager BDMG - API Server');
    Writeln('===========================================');
    Writeln('');

    { 1. Carregar configuracoes do JSON }
    TServerConfig.LoadFromFile(TServerConfig.GetDefaultConfigPath);
    TJWTHelper.SecretKey := TServerConfig.JWTConfig.SecretKey;

    { 2. Configurar repositorios }
    if TServerConfig.DatabaseConfig.UseDatabase then
    begin
      ConfigureDatabase;
      LUserRepository := TRepositoryFactory.CreateUserRepository(rtSQLServer, LConnection);
      LTaskRepository := TRepositoryFactory.CreateTaskRepository(rtSQLServer, LConnection);
      Writeln('[Config] Repositorio: SQL Server');
    end
    else
    begin
      LUserRepository := TRepositoryFactory.CreateUserRepository(rtMemory);
      LTaskRepository := TRepositoryFactory.CreateTaskRepository(rtMemory);
      Writeln('[Config] Repositorio: Memoria');
    end;

    { 3. Criar servicos via Factory }
    LUserService := TServiceFactory.CreateUserService(LUserRepository);
    LTaskService := TServiceFactory.CreateTaskService(LTaskRepository);

    { 4. Criar controllers }
    LUserController := TUserController.Create(LUserService);
    LTaskController := TTaskController.Create(LTaskService);

    { 5. Configurar Horse }
    THorse.Use(Jhonson);

    { Rotas publicas }
    THorse.Post('/api/users/register',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LUserController.Register(Req, Res, Next); end);

    THorse.Post('/api/users/login',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LUserController.Login(Req, Res, Next); end);

    { Rotas protegidas (JWT) }
    THorse.AddCallback(TAuthMiddleware.Validate).Get('/api/tasks',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LTaskController.GetAll(Req, Res, Next); end);

    THorse.AddCallback(TAuthMiddleware.Validate).Post('/api/tasks',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LTaskController.CreateTask(Req, Res, Next); end);

    THorse.AddCallback(TAuthMiddleware.Validate).Put('/api/tasks/:id/status',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LTaskController.UpdateStatus(Req, Res, Next); end);

    THorse.AddCallback(TAuthMiddleware.Validate).Delete('/api/tasks/:id',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LTaskController.DeleteTask(Req, Res, Next); end);

    THorse.AddCallback(TAuthMiddleware.Validate).Get('/api/tasks/stats',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin LTaskController.GetStats(Req, Res, Next); end);

    { Health check }
    THorse.Get('/api/health',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      var LResponseJSON: TJSONObject;
      begin
        LResponseJSON := TJSONObject.Create;
        LResponseJSON.AddPair('status', 'OK');
        LResponseJSON.AddPair('service', 'TaskManager BDMG API');
        LResponseJSON.AddPair('version', '1.0.0');
        Res.Send<TJSONObject>(LResponseJSON).Status(200);
      end);

    { 6. Iniciar servidor }
    LServerPort := TServerConfig.NetworkConfig.Port;
    Writeln('');
    Writeln(Format('[Server] Porta: %d', [LServerPort]));
    Writeln('[Server] Endpoints:');
    Writeln('  POST   /api/users/register   (publico)');
    Writeln('  POST   /api/users/login       (publico)');
    Writeln('  GET    /api/tasks             (JWT)');
    Writeln('  POST   /api/tasks             (JWT)');
    Writeln('  PUT    /api/tasks/:id/status  (JWT)');
    Writeln('  DELETE /api/tasks/:id         (JWT)');
    Writeln('  GET    /api/tasks/stats       (JWT)');
    Writeln('  GET    /api/health            (publico)');
    Writeln('');
    THorse.Listen(LServerPort);

  except
    on E: Exception do
      Writeln('[ERRO FATAL] ', E.ClassName, ': ', E.Message);
  end;
end.
