unit TaskManager.Services.Interfaces;

interface

uses
  System.JSON, System.Generics.Collections,
  TaskManager.Entities.User, TaskManager.Entities.Task;

type
  /// <summary>
  /// Interface do servico de usuarios.
  /// Define operacoes de cadastro e autenticacao.
  /// </summary>
  IUserService = interface
    ['{A6059734-0FD3-4B4D-B4C3-29749F0A592E}']
    function Register(const AName, AEmail, APassword: string): TUser;
    function Login(const AEmail, APassword: string): string; // retorna JWT
  end;

  /// <summary>
  /// DTO com estatisticas das tarefas (Desafio SQL).
  /// </summary>
  TTaskStats = record
    TotalTasks: Integer;
    AveragePendingPriority: Double;
    CompletedLast7Days: Integer;
  end;

  /// <summary>
  /// Interface do servico de tarefas.
  /// Todas as operacoes sao limitadas ao usuario autenticado.
  /// </summary>
  ITaskService = interface
    ['{BB20AE25-D0A4-4B24-835E-69800332B04B}']
    function GetAllTasks(AUserId: Integer): TObjectList<TTask>;
    function CreateTask(AUserId: Integer; const ATitle, ADescription: string;
      APriority: Integer): TTask;
    function UpdateTaskStatus(AUserId, ATaskId, ANewStatus: Integer): TTask;
    procedure DeleteTask(AUserId, ATaskId: Integer);
    function GetStats(AUserId: Integer): TTaskStats;
  end;

implementation

end.
