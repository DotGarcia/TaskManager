{ ============================================================================ }
{ TaskManager.Config.Server                                                    }
{                                                                              }
{ Carrega configuracoes do servidor a partir de server-config.json.            }
{ Permite configurar conexao SQL Server, porta HTTP e JWT via arquivo externo. }
{ Se o arquivo nao existir, valores padrao sao utilizados como fallback.       }
{ ============================================================================ }
unit TaskManager.Config.Server;

interface

uses
  System.IOUtils,
  System.JSON,
  System.SysUtils;

type
  /// <summary>Tipo de autenticacao para o SQL Server.</summary>
  TAuthenticationType = (
    atWindows,    /// Autenticacao integrada do Windows (OSAuthent=Yes)
    atSQLServer   /// Autenticacao via usuario e senha do SQL Server
  );

  /// <summary>Configuracoes de conexao com o banco de dados.</summary>
  TDatabaseConfig = record
    UseDatabase: Boolean;
    DriverID: string;
    Server: string;
    Database: string;
    Authentication: TAuthenticationType;
    Username: string;
    Password: string;
    Encrypt: string;
    TrustServerCertificate: string;
  end;

  /// <summary>Configuracoes de rede do servidor HTTP.</summary>
  TServerNetworkConfig = record
    Port: Integer;
  end;

  /// <summary>Configuracoes do JWT.</summary>
  TJWTConfig = record
    SecretKey: string;
    ExpirationHours: Integer;
  end;

  /// <summary>
  /// Carrega e fornece configuracoes do servidor a partir de JSON.
  /// </summary>
  TServerConfig = class
  private
    class var FDatabaseConfig: TDatabaseConfig;
    class var FNetworkConfig: TServerNetworkConfig;
    class var FJWTConfig: TJWTConfig;
    class var FLoaded: Boolean;
    class procedure SetDefaults;
    class function ParseAuthType(const AValue: string): TAuthenticationType;
  public
    class procedure LoadFromFile(const AConfigFile: string);
    class function GetDefaultConfigPath: string;
    class property DatabaseConfig: TDatabaseConfig read FDatabaseConfig;
    class property NetworkConfig: TServerNetworkConfig read FNetworkConfig;
    class property JWTConfig: TJWTConfig read FJWTConfig;
  end;

implementation

class procedure TServerConfig.SetDefaults;
begin
  FDatabaseConfig.UseDatabase := True;
  FDatabaseConfig.DriverID := 'MSSQL';
  FDatabaseConfig.Server := 'localhost';
  FDatabaseConfig.Database := 'TaskManagerDB';
  FDatabaseConfig.Authentication := atWindows;
  FDatabaseConfig.Username := '';
  FDatabaseConfig.Password := '';
  FDatabaseConfig.Encrypt := 'no';
  FDatabaseConfig.TrustServerCertificate := 'yes';
  FNetworkConfig.Port := 9000;
  FJWTConfig.SecretKey := 'TaskManager_BDMG_Default_Key';
  FJWTConfig.ExpirationHours := 24;
end;

class function TServerConfig.ParseAuthType(const AValue: string): TAuthenticationType;
begin
  if SameText(AValue, 'sqlserver') then
    Result := atSQLServer
  else
    Result := atWindows;
end;

class function TServerConfig.GetDefaultConfigPath: string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'server-config.json');
end;

class procedure TServerConfig.LoadFromFile(const AConfigFile: string);
var
  LFileContent: string;
  LRootJSON, LDatabaseJSON, LServerJSON, LJWTJson: TJSONObject;
begin
  SetDefaults;

  if not TFile.Exists(AConfigFile) then
  begin
    Writeln('[Config] Arquivo nao encontrado: ' + AConfigFile);
    Writeln('[Config] Usando configuracoes padrao.');
    FLoaded := True;
    Exit;
  end;

  try
    LFileContent := TFile.ReadAllText(AConfigFile, TEncoding.UTF8);
    LRootJSON := TJSONObject.ParseJSONValue(LFileContent) as TJSONObject;
    if not Assigned(LRootJSON) then
    begin
      Writeln('[Config] AVISO: JSON invalido em ' + AConfigFile);
      FLoaded := True;
      Exit;
    end;

    try
      if LRootJSON.TryGetValue<TJSONObject>('database', LDatabaseJSON) then
      begin
        FDatabaseConfig.UseDatabase := LDatabaseJSON.GetValue<Boolean>('useDatabase', FDatabaseConfig.UseDatabase);
        FDatabaseConfig.DriverID := LDatabaseJSON.GetValue<string>('driverID', FDatabaseConfig.DriverID);
        FDatabaseConfig.Server := LDatabaseJSON.GetValue<string>('server', FDatabaseConfig.Server);
        FDatabaseConfig.Database := LDatabaseJSON.GetValue<string>('database', FDatabaseConfig.Database);
        FDatabaseConfig.Authentication := ParseAuthType(LDatabaseJSON.GetValue<string>('authentication', 'windows'));
        FDatabaseConfig.Username := LDatabaseJSON.GetValue<string>('username', FDatabaseConfig.Username);
        FDatabaseConfig.Password := LDatabaseJSON.GetValue<string>('password', FDatabaseConfig.Password);
        FDatabaseConfig.Encrypt := LDatabaseJSON.GetValue<string>('encrypt', FDatabaseConfig.Encrypt);
        FDatabaseConfig.TrustServerCertificate := LDatabaseJSON.GetValue<string>('trustServerCertificate', FDatabaseConfig.TrustServerCertificate);
      end;

      if LRootJSON.TryGetValue<TJSONObject>('server', LServerJSON) then
        FNetworkConfig.Port := LServerJSON.GetValue<Integer>('port', FNetworkConfig.Port);

      if LRootJSON.TryGetValue<TJSONObject>('jwt', LJWTJson) then
      begin
        FJWTConfig.SecretKey := LJWTJson.GetValue<string>('secretKey', FJWTConfig.SecretKey);
        FJWTConfig.ExpirationHours := LJWTJson.GetValue<Integer>('expirationHours', FJWTConfig.ExpirationHours);
      end;

      Writeln('[Config] Configuracoes carregadas de: ' + AConfigFile);
    finally
      LRootJSON.Free;
    end;
  except
    on E: Exception do
      Writeln('[Config] Erro ao ler configuracao: ' + E.Message);
  end;

  FLoaded := True;
end;

end.
