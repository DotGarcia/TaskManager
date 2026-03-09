unit TaskManager.Controllers.User;

interface

uses
  System.SysUtils, System.JSON,
  Horse,
  TaskManager.Entities.User,
  TaskManager.Services.Interfaces;

type
  /// <summary>
  /// Controller de Usuarios (Camada C do MVC).
  /// Endpoints publicos para cadastro e login.
  /// </summary>
  TUserController = class
  private
    FService: IUserService;
  public
    constructor Create(AService: IUserService);

    /// POST /api/users/register
    procedure Register(Req: THorseRequest; Res: THorseResponse; Next: TProc);

    /// POST /api/users/login
    procedure Login(Req: THorseRequest; Res: THorseResponse; Next: TProc);
  end;

implementation

{ TUserController }

constructor TUserController.Create(AService: IUserService);
begin
  inherited Create;
  FService := AService;
end;

procedure TUserController.Register(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LBody: TJSONObject;
  LUser: TUser;
  LResponse: TJSONObject;
  LName, LEmail, LPassword: string;
begin
  try
    LBody := Req.Body<TJSONObject>;

    LName := LBody.GetValue<string>('name', '');
    LEmail := LBody.GetValue<string>('email', '');
    LPassword := LBody.GetValue<string>('password', '');

    LUser := FService.Register(LName, LEmail, LPassword);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('message', 'Usuario cadastrado com sucesso');
    LResponse.AddPair('user', TJSONObject.Create
      .AddPair('id', TJSONNumber.Create(LUser.Id))
      .AddPair('name', LUser.Name)
      .AddPair('email', LUser.Email));

    Res.Send<TJSONObject>(LResponse).Status(201);
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(400);
    end;
  end;
end;

procedure TUserController.Login(Req: THorseRequest; Res: THorseResponse;
  Next: TProc);
var
  LBody: TJSONObject;
  LToken: string;
  LResponse: TJSONObject;
  LEmail, LPassword: string;
begin
  try
    LBody := Req.Body<TJSONObject>;

    LEmail := LBody.GetValue<string>('email', '');
    LPassword := LBody.GetValue<string>('password', '');

    LToken := FService.Login(LEmail, LPassword);

    LResponse := TJSONObject.Create;
    LResponse.AddPair('token', LToken);
    LResponse.AddPair('type', 'Bearer');

    Res.Send<TJSONObject>(LResponse).Status(200);
  except
    on E: Exception do
    begin
      LResponse := TJSONObject.Create;
      LResponse.AddPair('error', E.Message);
      Res.Send<TJSONObject>(LResponse).Status(401);
    end;
  end;
end;

end.
