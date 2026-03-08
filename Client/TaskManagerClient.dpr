program TaskManagerClient;

uses
  Vcl.Forms,
  System.SysUtils,
  TaskManager.Client.ApiService in 'src\Services\TaskManager.Client.ApiService.pas',
  TaskManager.Client.Forms.Main in 'src\Forms\TaskManager.Client.Forms.Main.pas' {frmMain},
  TaskManager.Client.Forms.Login in 'src\Forms\TaskManager.Client.Forms.Login.pas' {frmLogin},
  TaskManager.Client.Forms.Register in 'src\Forms\TaskManager.Client.Forms.Register.pas' {frmRegister},
  FireDAC.DApt,
  FireDAC.Comp.Client;

{$R *.res}

var
  LApiService: TApiService;
begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  // Criar servico de API compartilhado (URL do servidor)
  LApiService := TApiService.Create('http://localhost:9000');
  try
    // Callback para tratar token expirado (401)
    LApiService.OnUnauthorized :=
      procedure
      begin
        // O formulario principal trata o redirecionamento ao login
      end;

    Application.CreateForm(TfrmMain, frmMain);
    frmMain.ApiService := LApiService;

    Application.Run;
  finally
    LApiService.Free;
  end;
end.
