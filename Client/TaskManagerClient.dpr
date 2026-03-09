{ ============================================================================ }
{ TaskManagerClient                                                            }
{                                                                              }
{ Aplicacao VCL cliente do TaskManager BDMG.                                   }
{ Consome a API REST do servidor via TApiService (REST.Client nativo).         }
{                                                                              }
{ Configuracao via client-config.json:                                         }
{   - Host, porta e protocolo do servidor                                      }
{   - Se o arquivo nao existir, usa http://localhost:9000                       }
{ ============================================================================ }
program TaskManagerClient;

uses
  { RTL }
  System.SysUtils,

  { VCL }
  Vcl.Forms,

  { Config }
  TaskManager.Client.Config in 'src\Config\TaskManager.Client.Config.pas',

  { Services }
  TaskManager.Client.ApiService in 'src\Services\TaskManager.Client.ApiService.pas',

  { Forms }
  TaskManager.Client.Forms.Login in 'src\Forms\TaskManager.Client.Forms.Login.pas' {frmLogin},
  TaskManager.Client.Forms.Main in 'src\Forms\TaskManager.Client.Forms.Main.pas' {frmMain},
  TaskManager.Client.Forms.Register in 'src\Forms\TaskManager.Client.Forms.Register.pas' {frmRegister};

{$R *.res}

var
  LApiService: TApiService;
  LBaseUrl: string;

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;

  { Carregar configuracoes do JSON (host, porta, protocolo) }
  TClientConfig.LoadFromFile(TClientConfig.GetDefaultConfigPath);
  LBaseUrl := TClientConfig.GetBaseUrl;

  { Criar servico de API com URL configurada }
  LApiService := TApiService.Create(LBaseUrl);
  try
    { Exibir LoginForm primeiro — ele se torna o MainForm real.
      Dessa forma o icone na taskbar pertence a janela que o usuario ve.
      O frmMain so e criado apos login bem-sucedido, evitando o problema
      de icone invisivel causado pelo ShowModal dentro do OnShow. }
    Application.CreateForm(TfrmLogin, frmLogin);
    frmLogin.ApiService := LApiService;

    { O frmMain cuida de reexibir o frmLogin no seu FormClose.
      O callback apenas garante que o close seja disparado caso
      a sessao expire durante uma requisicao. }
    LApiService.OnUnauthorized :=
      procedure
      begin
        if Assigned(frmMain) then
          frmMain.Close;
      end;

    Application.Run;
  finally
    LApiService.Free;
  end;
end.
