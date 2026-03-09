unit TaskManager.Middleware.Auth;

interface

uses
  System.SysUtils, System.JSON,
  Horse,
  TaskManager.Utils.JWT;

type
  /// <summary>
  /// Middleware de autenticacao JWT para o framework Horse.
  /// Intercepta requisicoes protegidas e valida o token Bearer.
  /// </summary>
  TAuthMiddleware = class
  public
    class procedure Validate(Req: THorseRequest; Res: THorseResponse;
      Next: TProc);
  end;

  /// <summary>
  /// Helper para extrair dados do JWT direto do header Authorization.
  /// Usado pelos controllers em vez de headers customizados (read-only).
  /// </summary>
  TJWTAuthHelper = class
  public
    class function GetUserIdFromRequest(Req: THorseRequest): Integer;
    class function GetUserEmailFromRequest(Req: THorseRequest): string;
    class function GetPayloadFromRequest(Req: THorseRequest): TJWTPayload;
  end;

implementation

{ TAuthMiddleware }

class procedure TAuthMiddleware.Validate(Req: THorseRequest;
  Res: THorseResponse; Next: TProc);
var
  LAuthHeader, LToken: string;
  LPayload: TJWTPayload;
  LErrorJSON: TJSONObject;
begin
  LAuthHeader := Req.Headers['Authorization'];
  LAuthHeader := LAuthHeader.Trim
    .Replace(#13, '', [rfReplaceAll])
    .Replace(#10, '', [rfReplaceAll]);

  if LAuthHeader.IsEmpty then
  begin
    LErrorJSON := TJSONObject.Create;
    LErrorJSON.AddPair('error', 'Token de autenticacao nao fornecido');
    LErrorJSON.AddPair('code', 'UNAUTHORIZED');
    Res.Send<TJSONObject>(LErrorJSON).Status(401);
    raise EHorseCallbackInterrupted.Create;
  end;

  LToken := TJWTHelper.ExtractTokenFromHeader(LAuthHeader);
  if LToken.IsEmpty then
  begin
    LErrorJSON := TJSONObject.Create;
    LErrorJSON.AddPair('error', 'Formato de token invalido. Use: Bearer <token>');
    LErrorJSON.AddPair('code', 'UNAUTHORIZED');
    Res.Send<TJSONObject>(LErrorJSON).Status(401);
    raise EHorseCallbackInterrupted.Create;
  end;

  LPayload := TJWTHelper.ValidateToken(LToken);
  if not LPayload.IsValid then
  begin
    LErrorJSON := TJSONObject.Create;
    LErrorJSON.AddPair('error', 'Token invalido ou expirado');
    LErrorJSON.AddPair('code', 'UNAUTHORIZED');
    Res.Send<TJSONObject>(LErrorJSON).Status(401);
    raise EHorseCallbackInterrupted.Create;
  end;

  // Token valido - NAO escreve nos headers (read-only).
  // Controllers usam TJWTAuthHelper para obter UserId.
  Next;
end;

{ TJWTAuthHelper }

class function TJWTAuthHelper.GetPayloadFromRequest(
  Req: THorseRequest): TJWTPayload;
var
  LAuthHeader, LToken: string;
begin
  LAuthHeader := Req.Headers['Authorization'];
  LAuthHeader := LAuthHeader.Trim
    .Replace(#13, '', [rfReplaceAll])
    .Replace(#10, '', [rfReplaceAll]);

  LToken := TJWTHelper.ExtractTokenFromHeader(LAuthHeader);
  Result := TJWTHelper.ValidateToken(LToken);

  if not Result.IsValid then
    raise Exception.Create('Usuario nao autenticado');
end;

class function TJWTAuthHelper.GetUserIdFromRequest(
  Req: THorseRequest): Integer;
begin
  Result := GetPayloadFromRequest(Req).UserId;
end;

class function TJWTAuthHelper.GetUserEmailFromRequest(
  Req: THorseRequest): string;
begin
  Result := GetPayloadFromRequest(Req).Email;
end;

end.
