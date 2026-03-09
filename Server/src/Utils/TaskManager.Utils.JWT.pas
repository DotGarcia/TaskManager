unit TaskManager.Utils.JWT;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils,
  System.NetEncoding, System.Hash;

type
  TJWTPayload = record
    UserId: Integer;
    Email: string;
    IssuedAt: TDateTime;
    ExpiresAt: TDateTime;
    IsValid: Boolean;
  end;

  TJWTHelper = class
  private
    class var FSecretKey: string;
    class function Base64UrlEncode(const AInput: TBytes): string;
    class function Base64UrlDecode(const AInput: string): TBytes;
    class function HMACSHA256(const AData, AKey: string): string;
  public
    class property SecretKey: string read FSecretKey write FSecretKey;
    class function GenerateToken(AUserId: Integer; const AEmail: string;
      AExpirationHours: Integer = 24): string;
    class function ValidateToken(const AToken: string): TJWTPayload;
    class function ExtractTokenFromHeader(const AAuthHeader: string): string;
  end;

implementation

{ TJWTHelper }

class function TJWTHelper.Base64UrlEncode(const AInput: TBytes): string;
begin
  Result := TNetEncoding.Base64.EncodeBytesToString(AInput);
  // CORRECAO: Remove CRLF que TNetEncoding.Base64 insere a cada 76 chars
  Result := Result.Replace(#13, '', [rfReplaceAll]);
  Result := Result.Replace(#10, '', [rfReplaceAll]);
  Result := Result.Replace(' ', '', [rfReplaceAll]);
  // Base64 padrao -> Base64Url (RFC 4648)
  Result := Result.Replace('+', '-', [rfReplaceAll]);
  Result := Result.Replace('/', '_', [rfReplaceAll]);
  Result := Result.TrimRight(['=']);
end;

class function TJWTHelper.Base64UrlDecode(const AInput: string): TBytes;
var
  LPadded: string;
begin
  LPadded := AInput.Replace('-', '+', [rfReplaceAll]);
  LPadded := LPadded.Replace('_', '/', [rfReplaceAll]);
  while Length(LPadded) mod 4 <> 0 do
    LPadded := LPadded + '=';
  Result := TNetEncoding.Base64.DecodeStringToBytes(LPadded);
end;

class function TJWTHelper.HMACSHA256(const AData, AKey: string): string;
var
  LKeyBytes, LDataBytes, LHashBytes: TBytes;
begin
  LKeyBytes := TEncoding.UTF8.GetBytes(AKey);
  LDataBytes := TEncoding.UTF8.GetBytes(AData);
  LHashBytes := THashSHA2.GetHMACAsBytes(LDataBytes, LKeyBytes);
  // CORRECAO: Retorna Base64Url dos bytes HMAC (antes era IntToHex -> invalido)
  Result := Base64UrlEncode(LHashBytes);
end;

class function TJWTHelper.GenerateToken(AUserId: Integer;
  const AEmail: string; AExpirationHours: Integer): string;
var
  LHeader, LPayload, LHeaderB64, LPayloadB64, LSignature: string;
  LHeaderJSON, LPayloadJSON: TJSONObject;
  LNow: TDateTime;
begin
  LNow := Now;

  LHeaderJSON := TJSONObject.Create;
  try
    LHeaderJSON.AddPair('alg', 'HS256');
    LHeaderJSON.AddPair('typ', 'JWT');
    LHeader := LHeaderJSON.ToJSON;
  finally
    LHeaderJSON.Free;
  end;

  LPayloadJSON := TJSONObject.Create;
  try
    LPayloadJSON.AddPair('userId', TJSONNumber.Create(AUserId));
    LPayloadJSON.AddPair('email', AEmail);
    LPayloadJSON.AddPair('iat', TJSONNumber.Create(DateTimeToUnix(LNow, False)));
    LPayloadJSON.AddPair('exp', TJSONNumber.Create(
      DateTimeToUnix(IncHour(LNow, AExpirationHours), False)));
    LPayload := LPayloadJSON.ToJSON;
  finally
    LPayloadJSON.Free;
  end;

  LHeaderB64 := Base64UrlEncode(TEncoding.UTF8.GetBytes(LHeader));
  LPayloadB64 := Base64UrlEncode(TEncoding.UTF8.GetBytes(LPayload));
  LSignature := HMACSHA256(LHeaderB64 + '.' + LPayloadB64, FSecretKey);

  Result := LHeaderB64 + '.' + LPayloadB64 + '.' + LSignature;
end;

class function TJWTHelper.ValidateToken(const AToken: string): TJWTPayload;
var
  LParts: TArray<string>;
  LPayloadJSON: TJSONObject;
  LPayloadBytes: TBytes;
  LPayloadStr, LExpectedSig, LActualSig, LCleanToken: string;
  LExp: Int64;
begin
  Result := Default(TJWTPayload);
  Result.IsValid := False;

  LCleanToken := AToken.Trim
    .Replace(#13, '', [rfReplaceAll])
    .Replace(#10, '', [rfReplaceAll])
    .Replace(' ', '', [rfReplaceAll]);

  LParts := LCleanToken.Split(['.']);
  if Length(LParts) <> 3 then Exit;

  LExpectedSig := HMACSHA256(LParts[0] + '.' + LParts[1], FSecretKey);
  LActualSig := LParts[2];
  if not SameStr(LExpectedSig, LActualSig) then Exit;

  try
    LPayloadBytes := Base64UrlDecode(LParts[1]);
    LPayloadStr := TEncoding.UTF8.GetString(LPayloadBytes);
    LPayloadJSON := TJSONObject.ParseJSONValue(LPayloadStr) as TJSONObject;
    try
      if not Assigned(LPayloadJSON) then Exit;
      Result.UserId := LPayloadJSON.GetValue<Integer>('userId');
      Result.Email := LPayloadJSON.GetValue<string>('email');
      Result.IssuedAt := UnixToDateTime(LPayloadJSON.GetValue<Int64>('iat'), False);
      LExp := LPayloadJSON.GetValue<Int64>('exp');
      Result.ExpiresAt := UnixToDateTime(LExp, False);
      if Now > Result.ExpiresAt then Exit;
      Result.IsValid := True;
    finally
      LPayloadJSON.Free;
    end;
  except
    Result.IsValid := False;
  end;
end;

class function TJWTHelper.ExtractTokenFromHeader(const AAuthHeader: string): string;
const
  BEARER_PREFIX = 'Bearer ';
var
  LClean: string;
begin
  LClean := AAuthHeader.Trim
    .Replace(#13, '', [rfReplaceAll])
    .Replace(#10, '', [rfReplaceAll]);
  if LClean.StartsWith(BEARER_PREFIX, True) then
    Result := LClean.Substring(Length(BEARER_PREFIX)).Trim
  else
    Result := '';
end;

initialization
  TJWTHelper.SecretKey := 'scrt';

end.
