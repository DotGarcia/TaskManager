unit TaskManager.Factories;

interface

uses
  System.SysUtils, FireDAC.Comp.Client,
  TaskManager.Repositories.Interfaces,
  TaskManager.Repositories.Memory,
  TaskManager.Repositories.SQLServer,
  TaskManager.Services.Interfaces,
  TaskManager.Services.User,
  TaskManager.Services.Task;

type
  /// <summary>
  /// Tipo de repositorio a ser utilizado.
  /// Permite alternar entre memoria (testes) e SQL Server (producao).
  /// </summary>
  TRepositoryType = (rtMemory, rtSQLServer);

  /// <summary>
  /// Factory para criacao de repositorios (Padrao Abstract Factory).
  /// Centraliza a instanciacao e permite trocar a implementacao
  /// sem modificar o codigo dos servicos ou controllers.
  /// </summary>
  TRepositoryFactory = class
  public
    class function CreateUserRepository(AType: TRepositoryType;
      AConnection: TFDConnection = nil): IUserRepository;
    class function CreateTaskRepository(AType: TRepositoryType;
      AConnection: TFDConnection = nil): ITaskRepository;
  end;

  /// <summary>
  /// Factory para criacao de servicos (Padrao Factory Method).
  /// </summary>
  TServiceFactory = class
  public
    class function CreateUserService(ARepository: IUserRepository): IUserService;
    class function CreateTaskService(ARepository: ITaskRepository): ITaskService;
  end;

implementation

{ TRepositoryFactory }

class function TRepositoryFactory.CreateUserRepository(
  AType: TRepositoryType; AConnection: TFDConnection): IUserRepository;
begin
  case AType of
    rtMemory:
      Result := TMemoryUserRepository.Create;
    rtSQLServer:
    begin
      if not Assigned(AConnection) then
        raise Exception.Create('Conexao com banco de dados e obrigatoria para SQL Server');
      Result := TSQLServerUserRepository.Create(AConnection);
    end;
  end;
end;

class function TRepositoryFactory.CreateTaskRepository(
  AType: TRepositoryType; AConnection: TFDConnection): ITaskRepository;
begin
  case AType of
    rtMemory:
      Result := TMemoryTaskRepository.Create;
    rtSQLServer:
    begin
      if not Assigned(AConnection) then
        raise Exception.Create('Conexao com banco de dados e obrigatoria para SQL Server');
      Result := TSQLServerTaskRepository.Create(AConnection);
    end;
  end;
end;

{ TServiceFactory }

class function TServiceFactory.CreateUserService(
  ARepository: IUserRepository): IUserService;
begin
  Result := TUserService.Create(ARepository);
end;

class function TServiceFactory.CreateTaskService(
  ARepository: ITaskRepository): ITaskService;
begin
  Result := TTaskService.Create(ARepository);
end;

end.
