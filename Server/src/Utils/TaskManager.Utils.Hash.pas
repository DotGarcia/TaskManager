unit TaskManager.Utils.Hash;

interface

uses
  System.SysUtils, System.Hash, System.NetEncoding;

type
  /// <summary>
  /// Utilitario para hashing de senhas com SHA-256 + Salt.
  /// Garante armazenamento seguro das credenciais.
  /// </summary>
  TPasswordHasher = class
  public
    /// Gera um salt aleatorio codificado em Base64
    class function GenerateSalt: string;

    /// Cria o hash da senha concatenada com o salt
    class function HashPassword(const APassword, ASalt: string): string;

    /// Verifica se a senha fornecida corresponde ao hash armazenado
    class function VerifyPassword(const APassword, ASalt, AStoredHash: string): Boolean;
  end;

implementation

{ TPasswordHasher }

class function TPasswordHasher.GenerateSalt: string;
var
  LSaltBytes: TBytes;
  I: Integer;
begin
  SetLength(LSaltBytes, 32);
  for I := 0 to Length(LSaltBytes) - 1 do
    LSaltBytes[I] := Random(256);
  Result := TNetEncoding.Base64.EncodeBytesToString(LSaltBytes);
end;

class function TPasswordHasher.HashPassword(const APassword, ASalt: string): string;
begin
  // SHA-256 do (salt + password) para proteger contra rainbow tables
  Result := THashSHA2.GetHashString(ASalt + APassword, SHA256);
end;

class function TPasswordHasher.VerifyPassword(const APassword, ASalt,
  AStoredHash: string): Boolean;
begin
  Result := SameStr(HashPassword(APassword, ASalt), AStoredHash);
end;

end.
