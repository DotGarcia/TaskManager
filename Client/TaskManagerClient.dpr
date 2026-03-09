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
    LApiService.OnUnauthorized :=
      procedure
      begin
        { Formulario principal trata redirecionamento ao login }
      end;

    Application.CreateForm(TfrmMain, frmMain);
    frmMain.ApiService := LApiService;
    Application.Run;
  finally
    LApiService.Free;
  end;
end.
