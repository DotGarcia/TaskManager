unit TaskManager.Middleware.JWT;

interface

uses
  System.SysUtils, System.JSON,
  Horse,
  TaskManager.Utils.JWT;

type
  /// <summary>
  /// Middleware de autenticação JWT para o framework Horse.
  /// Intercepta requisições e valida o token Bearer no header Authorization.
  /// Injeta o UserId no request para uso pelos controllers.
  /// </summary>
  TJWTMiddleware = class
  private
    class var FJWTManager: TJWTManager;
  public
    class procedure SetJWTManager(AJWTManager: TJWTManager);
    class procedure Validate(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TJWTMiddleware }

class procedure TJWTMiddleware.SetJWTManager(AJWTManager: TJWTManager);
begin
  FJWTManager := AJWTManager;
end;

class procedure TJWTMiddleware.Validate(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  LAuthHeader, LToken: string;
  LUserId: Integer;
  LError: TJSONObject;
begin
  LAuthHeader := Req.Headers['Authorization'];

  if LAuthHeader.IsEmpty then
  begin
    LError := TJSONObject.Create;
    LError.AddPair('error', 'Token não fornecido');
    Res.Send<TJSONObject>(LError).Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

  // Remove prefixo "Bearer "
  if LAuthHeader.StartsWith('Bearer ', True) then
    LToken := Copy(LAuthHeader, 8, Length(LAuthHeader))
  else
    LToken := LAuthHeader;

  if FJWTManager = nil then
  begin
    LError := TJSONObject.Create;
    LError.AddPair('error', 'Erro interno de configuração JWT');
    Res.Send<TJSONObject>(LError).Status(THTTPStatus.InternalServerError);
    raise EHorseCallbackInterrupted.Create;
  end;

  if not FJWTManager.ValidateToken(LToken, LUserId) then
  begin
    LError := TJSONObject.Create;
    LError.AddPair('error', 'Token inválido ou expirado');
    Res.Send<TJSONObject>(LError).Status(THTTPStatus.Unauthorized);
    raise EHorseCallbackInterrupted.Create;
  end;

  // Armazena UserId no request para uso nos controllers
  // Usamos o campo Params com chave especial
  Req.Headers['X-User-Id'] := IntToStr(LUserId);

  Next;
end;

end.
