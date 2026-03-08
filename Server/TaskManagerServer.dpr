program TaskManagerServer;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.JSON,
  Horse,
  Horse.Jhonson,          // Middleware para parse JSON automatico
  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Phys.MSSQL,     // Driver SQL Server
  FireDAC.Phys.MSSQLDef,
  TaskManager.Entities.Base in 'src\Entities\TaskManager.Entities.Base.pas',
  TaskManager.Entities.User in 'src\Entities\TaskManager.Entities.User.pas',
  TaskManager.Entities.Task in 'src\Entities\TaskManager.Entities.Task.pas',
  TaskManager.Attributes in 'src\Attributes\TaskManager.Attributes.pas',
  TaskManager.RTTI.Mapper in 'src\Repositories\TaskManager.RTTI.Mapper.pas',
  TaskManager.Repositories.Interfaces in 'src\Repositories\TaskManager.Repositories.Interfaces.pas',
  TaskManager.Repositories.Memory in 'src\Repositories\TaskManager.Repositories.Memory.pas',
  TaskManager.Repositories.SQLServer in 'src\Repositories\TaskManager.Repositories.SQLServer.pas',
  TaskManager.Services.Interfaces in 'src\Services\TaskManager.Services.Interfaces.pas',
  TaskManager.Services.User in 'src\Services\TaskManager.Services.User.pas',
  TaskManager.Services.Task in 'src\Services\TaskManager.Services.Task.pas',
  TaskManager.Factories in 'src\Factories\TaskManager.Factories.pas',
  TaskManager.Middleware.Auth in 'src\Middleware\TaskManager.Middleware.Auth.pas',
  TaskManager.Controllers.User in 'src\Controllers\TaskManager.Controllers.User.pas',
  TaskManager.Controllers.Task in 'src\Controllers\TaskManager.Controllers.Task.pas',
  TaskManager.Utils.Hash in 'src\Utils\TaskManager.Utils.Hash.pas',
  TaskManager.Utils.JWT in 'src\Utils\TaskManager.Utils.JWT.pas';

var
  LConnection: TFDConnection;
  LUserRepo: IUserRepository;
  LTaskRepo: ITaskRepository;
  LUserService: IUserService;
  LTaskService: ITaskService;
  LUserController: TUserController;
  LTaskController: TTaskController;
  LUseDatabase: Boolean;

procedure ConfigureDatabase;
begin
  LConnection := TFDConnection.Create(nil);
  LConnection.Params.DriverID := 'MSSQL';
  LConnection.Params.Database := 'TaskManagerDB';
  LConnection.Params.Values['Server'] := 'localhost';

  // Autenticação Windows (Trusted Connection)
  LConnection.Params.Values['OSAuthent'] := 'Yes';  // Usar autenticação do Windows
  LConnection.Params.Add('Encrypt=no');
  LConnection.Params.Add('TrustServerCertificate=yes');

  LConnection.LoginPrompt := False;
  LConnection.Connected := True;
  Writeln('[DB] Conectado ao SQL Server com autenticação Windows com sucesso.');
end;

begin
  try
    Writeln('===========================================');
    Writeln('  TaskManager BDMG - API Server');
    Writeln('===========================================');
    Writeln('');

    // Configurar tipo de repositorio
    // Altere para True quando houver SQL Server disponivel
    LUseDatabase := True;

    if LUseDatabase then
    begin
      ConfigureDatabase;
      LUserRepo := TRepositoryFactory.CreateUserRepository(rtSQLServer, LConnection);
      LTaskRepo := TRepositoryFactory.CreateTaskRepository(rtSQLServer, LConnection);
      Writeln('[Config] Usando repositorio SQL Server');
    end
    else
    begin
      LUserRepo := TRepositoryFactory.CreateUserRepository(rtMemory);
      LTaskRepo := TRepositoryFactory.CreateTaskRepository(rtMemory);
      Writeln('[Config] Usando repositorio em memoria (desenvolvimento)');
    end;

    // Criar servicos via Factory
    LUserService := TServiceFactory.CreateUserService(LUserRepo);
    LTaskService := TServiceFactory.CreateTaskService(LTaskRepo);

    // Criar controllers
    LUserController := TUserController.Create(LUserService);
    LTaskController := TTaskController.Create(LTaskService);

    // Configurar Horse
    THorse.Use(Jhonson); // Middleware para JSON parsing

    // === Rotas publicas (sem autenticacao) ===
    THorse.Post('/api/users/register',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin
        LUserController.Register(Req, Res, Next);
      end
    );

    THorse.Post('/api/users/login',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      begin
        LUserController.Login(Req, Res, Next);
      end
    );

    // === Rotas protegidas (com JWT) ===
    // Todas as rotas de tarefas passam pelo middleware de autenticacao

    THorse.AddCallback(TAuthMiddleware.Validate)
      .Get('/api/tasks',
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          LTaskController.GetAll(Req, Res, Next);
        end
      );

    THorse.AddCallback(TAuthMiddleware.Validate)
      .Post('/api/tasks',
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          LTaskController.CreateTask(Req, Res, Next);
        end
      );

    THorse.AddCallback(TAuthMiddleware.Validate)
      .Put('/api/tasks/:id/status',
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          LTaskController.UpdateStatus(Req, Res, Next);
        end
      );

    THorse.AddCallback(TAuthMiddleware.Validate)
      .Delete('/api/tasks/:id',
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          LTaskController.DeleteTask(Req, Res, Next);
        end
      );

    THorse.AddCallback(TAuthMiddleware.Validate)
      .Get('/api/tasks/stats',
        procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
        begin
          LTaskController.GetStats(Req, Res, Next);
        end
      );

    // Rota de health check
    THorse.Get('/api/health',
      procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
      var
        LResponse: TJSONObject;
      begin
        LResponse := TJSONObject.Create;
        LResponse.AddPair('status', 'OK');
        LResponse.AddPair('service', 'TaskManager BDMG API');
        LResponse.AddPair('version', '1.0.0');
        Res.Send<TJSONObject>(LResponse).Status(200);
      end
    );

    Writeln('');
    Writeln('[Server] Iniciando na porta 9000...');
    Writeln('[Server] Endpoints disponiveis:');
    Writeln('  POST   /api/users/register   (publico)');
    Writeln('  POST   /api/users/login       (publico)');
    Writeln('  GET    /api/tasks             (JWT)');
    Writeln('  POST   /api/tasks             (JWT)');
    Writeln('  PUT    /api/tasks/:id/status  (JWT)');
    Writeln('  DELETE /api/tasks/:id         (JWT)');
    Writeln('  GET    /api/tasks/stats       (JWT)');
    Writeln('  GET    /api/health            (publico)');
    Writeln('');

    THorse.Listen(9000);

  except
    on E: Exception do
      Writeln('[ERRO] ', E.ClassName, ': ', E.Message);
  end;
end.
