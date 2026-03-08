unit TaskManager.Controllers.UserController;

interface

uses
  System.SysUtils, System.JSON,
  Horse,
  TaskManager.Entities,
  TaskManager.Services.Interfaces,
  TaskManager.Services.UserService;

type
  /// <summary>
  /// Controller de Usuários — endpoints públicos (sem JWT).
  /// POST /api/users/register  — Cadastro
  /// POST /api/users/login     — Autenticação
  /// </summary>
  TUserController = class
  private
    FUserService: IUserService;
  public
    constructor Create(AUserService: IUserService);

    procedure Register(Req: THorseRequest; Res: THorseResponse);
    procedure Login(Req: THorseRequest; Res: THorseResponse);

    procedure RegisterRoutes(AApp: THorse);
  end;

implementation

{ TUserController }

constructor TUserController.Create(AUserService: IUserService);
begin
  inherited Create;
  FUserService := AUserService;
end;

procedure TUserController.Register(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LUser: TUser;
  LResponse: TJSONObject;
begin
  try
    LBody := Req.Body<TJSONObject>;

    LUser := FUserService.Register(
      LBody.GetValue<string>('name', ''),
      LBody.GetValue<string>('email', ''),
      LBody.GetValue<string>('password', '')
    );

    LResponse := TJSONObject.Create;
    LResponse.AddPair('id', TJSONNumber.Create(LUser.Id));
    LResponse.AddPair('name', LUser.Name);
    LResponse.AddPair('email', LUser.Email);
    LResponse.AddPair('message', 'Usuário cadastrado com sucesso');

    Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.Created);
  except
    on E: EConflictException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.Conflict);
    end;
    on E: EArgumentException do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.BadRequest);
    end;
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', 'Erro interno: ' + E.Message);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TUserController.Login(Req: THorseRequest; Res: THorseResponse);
var
  LBody: TJSONObject;
  LAuthResult: TAuthResult;
  LResponse: TJSONObject;
begin
  try
    LBody := Req.Body<TJSONObject>;

    LAuthResult := FUserService.Login(
      LBody.GetValue<string>('email', ''),
      LBody.GetValue<string>('password', '')
    );

    LResponse := TJSONObject.Create;
    if LAuthResult.Success then
    begin
      LResponse.AddPair('token', LAuthResult.Token);
      LResponse.AddPair('userId', TJSONNumber.Create(LAuthResult.UserId));
      LResponse.AddPair('userName', LAuthResult.UserName);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.OK);
    end
    else
    begin
      LResponse.AddPair('error', LAuthResult.ErrorMessage);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.Unauthorized);
    end;
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', 'Erro interno: ' + E.Message);
      Res.Send<TJSONObject>(LResponse).Status(THTTPStatus.InternalServerError);
    end;
  end;
end;

procedure TUserController.RegisterRoutes(AApp: THorse);
begin
  // Rotas públicas (sem middleware JWT)
  AApp.Post('/api/users/register', Self.Register);
  AApp.Post('/api/users/login', Self.Login);
end;

end.
