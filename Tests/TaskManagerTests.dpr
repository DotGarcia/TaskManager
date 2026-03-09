program TaskManagerTests;

{$APPTYPE CONSOLE}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  // Units do servidor necessarias para os testes
  TaskManager.Entities.Base in '..\Server\src\Entities\TaskManager.Entities.Base.pas',
  TaskManager.Entities.User in '..\Server\src\Entities\TaskManager.Entities.User.pas',
  TaskManager.Entities.Task in '..\Server\src\Entities\TaskManager.Entities.Task.pas',
  TaskManager.Attributes in '..\Server\src\Attributes\TaskManager.Attributes.pas',
  TaskManager.RTTI.Mapper in '..\Server\src\Repositories\TaskManager.RTTI.Mapper.pas',
  TaskManager.Repositories.Interfaces in '..\Server\src\Repositories\TaskManager.Repositories.Interfaces.pas',
  TaskManager.Repositories.Memory in '..\Server\src\Repositories\TaskManager.Repositories.Memory.pas',
  TaskManager.Services.Interfaces in '..\Server\src\Services\TaskManager.Services.Interfaces.pas',
  TaskManager.Services.User in '..\Server\src\Services\TaskManager.Services.User.pas',
  TaskManager.Services.Task in '..\Server\src\Services\TaskManager.Services.Task.pas',
  TaskManager.Utils.Hash in '..\Server\src\Utils\TaskManager.Utils.Hash.pas',
  TaskManager.Utils.JWT in '..\Server\src\Utils\TaskManager.Utils.JWT.pas',
  // Fixtures de teste
  TaskManager.Tests.UserService in 'src\TaskManager.Tests.UserService.pas',
  TaskManager.Tests.TaskService in 'src\TaskManager.Tests.TaskService.pas',
  TaskManager.Tests.RttiMapper in 'src\TaskManager.Tests.RttiMapper.pas';

var
  LRunner: ITestRunner;
  LResults: IRunResults;
  LLogger: ITestLogger;
  LNUnitLogger: ITestLogger;
begin
  try
    // Verificar se ha fixtures de teste registradas
    TDUnitX.CheckCommandLine;

    // Criar o runner
    LRunner := TDUnitX.CreateRunner;

    // Logger de console para saida ao vivo
    LLogger := TDUnitXConsoleLogger.Create(True);
    LRunner.AddLogger(LLogger);

    // Logger XML NUnit para integracao com CI/CD
    LNUnitLogger := TDUnitXXMLNUnitFileLogger.Create(
      TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLogger);

    LRunner.FailsOnNoAsserts := False;

    // Executar testes
    Writeln('===========================================');
    Writeln('  TaskManager BDMG - Testes Unitarios');
    Writeln('===========================================');
    Writeln('');

    LResults := LRunner.Execute;

    // Resultado final
    Writeln('');
    Writeln('===========================================');
    if not LResults.AllPassed then
    begin
      Writeln('  RESULTADO: FALHAS DETECTADAS');
      System.ExitCode := EXIT_ERRORS;
    end
    else
    begin
      Writeln('  RESULTADO: TODOS OS TESTES PASSARAM');
      System.ExitCode := EXIT_OK;
    end;
    Writeln('===========================================');

  except
    on E: Exception do
    begin
      Writeln('[ERRO] ', E.ClassName, ': ', E.Message);
      System.ExitCode := EXIT_ERRORS;
    end;
  end;

  {$IFNDEF CI}
  Writeln('');
  Write('Pressione ENTER para sair...');
  Readln;
  {$ENDIF}
end.
