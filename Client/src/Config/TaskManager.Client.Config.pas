{ ============================================================================ }
{ TaskManager.Client.Config                                                    }
{                                                                              }
{ Carrega configuracoes do cliente a partir de client-config.json.             }
{ Permite configurar host, porta e protocolo do servidor da API.               }
{ Se o arquivo nao existir, utiliza http://localhost:9000 como padrao.          }
{ ============================================================================ }
unit TaskManager.Client.Config;

interface

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils;

type
  /// <summary>Configuracoes de conexao com o servidor da API.</summary>
  TClientServerConfig = record
    Host: string;
    Port: Integer;
    Protocol: string;
  end;

  /// <summary>
  /// Carrega configuracoes do cliente a partir de JSON.
  /// Gera a URL base para o TApiService.
  /// </summary>
  TClientConfig = class
  private
    class var FServerConfig: TClientServerConfig;
    class var FLoaded: Boolean;
    class procedure SetDefaults;
  public
    class procedure LoadFromFile(const AConfigFile: string);
    class function GetDefaultConfigPath: string;
    class function GetBaseUrl: string;
    class property ServerConfig: TClientServerConfig read FServerConfig;
  end;

implementation

class procedure TClientConfig.SetDefaults;
begin
  FServerConfig.Host := 'localhost';
  FServerConfig.Port := 9000;
  FServerConfig.Protocol := 'http';
end;

class function TClientConfig.GetDefaultConfigPath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'client-config.json');
end;

class function TClientConfig.GetBaseUrl: string;
begin
  if not FLoaded then
    LoadFromFile(GetDefaultConfigPath);
  Result := Format('%s://%s:%d', [FServerConfig.Protocol, FServerConfig.Host, FServerConfig.Port]);
end;

class procedure TClientConfig.LoadFromFile(const AConfigFile: string);
var
  LFileContent: string;
  LRootJSON, LServerJSON: TJSONObject;
begin
  SetDefaults;

  if not TFile.Exists(AConfigFile) then
  begin
    FLoaded := True;
    Exit;
  end;

  try
    LFileContent := TFile.ReadAllText(AConfigFile, TEncoding.UTF8);
    LRootJSON := TJSONObject.ParseJSONValue(LFileContent) as TJSONObject;
    if not Assigned(LRootJSON) then
    begin
      FLoaded := True;
      Exit;
    end;

    try
      if LRootJSON.TryGetValue<TJSONObject>('server', LServerJSON) then
      begin
        FServerConfig.Host := LServerJSON.GetValue<string>('host', FServerConfig.Host);
        FServerConfig.Port := LServerJSON.GetValue<Integer>('port', FServerConfig.Port);
        FServerConfig.Protocol := LServerJSON.GetValue<string>('protocol', FServerConfig.Protocol);
      end;
    finally
      LRootJSON.Free;
    end;
  except
    { Falha silenciosa: usa valores padrao }
  end;

  FLoaded := True;
end;

end.
