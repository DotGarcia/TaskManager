unit TaskManager.Repositories.Interfaces;

interface

uses
  System.Generics.Collections,
  TaskManager.Entities.Base;

type
  /// <summary>
  /// Interface generica de repositorio (Polimorfismo).
  /// Define operacoes CRUD que podem ter diferentes implementacoes:
  ///   - TMemoryRepository (para testes unitarios)
  ///   - TSQLServerRepository (para producao)
  /// </summary>
  IRepository<T: TBaseEntity> = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function FindById(AId: Integer): T;
    function FindAll: TObjectList<T>;
    function Insert(AEntity: T): Integer;
    procedure Update(AEntity: T);
    procedure Delete(AId: Integer);
  end;

  /// <summary>
  /// Interface estendida para repositorio de usuarios.
  /// Adiciona busca por e-mail alem do CRUD generico.
  /// </summary>
  IUserRepository = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByEmail(const AEmail: string): TBaseEntity;
  end;

  /// <summary>
  /// Interface estendida para repositorio de tarefas.
  /// Adiciona consultas especificas por usuario e estatisticas SQL.
  /// </summary>
  ITaskRepository = interface
    ['{C3D4E5F6-A7B8-9012-CDEF-123456789012}']
    function FindById(AId: Integer): TBaseEntity;
    function FindAll: TObjectList<TBaseEntity>;
    function Insert(AEntity: TBaseEntity): Integer;
    procedure Update(AEntity: TBaseEntity);
    procedure Delete(AId: Integer);
    function FindByUserId(AUserId: Integer): TObjectList<TBaseEntity>;

    // Desafio SQL - Estatisticas por usuario
    function GetTotalTaskCount(AUserId: Integer): Integer;
    function GetAveragePendingPriority(AUserId: Integer): Double;
    function GetCompletedLast7Days(AUserId: Integer): Integer;
  end;

implementation

end.
