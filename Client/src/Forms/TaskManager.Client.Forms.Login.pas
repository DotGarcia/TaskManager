unit TaskManager.Client.Forms.Login;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons,
  TaskManager.Client.ApiService;

type
  TfrmLogin = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    pnlBtnLogin: TPanel;
    pnlBtnRegister: TPanel;
    lblStatus: TLabel;
    shpLine: TShape;
    procedure FormCreate(Sender: TObject);
    procedure edtPasswordKeyPress(Sender: TObject; var Key: Char);
    procedure pnlBtnLoginClick(Sender: TObject);
    procedure pnlBtnRegisterClick(Sender: TObject);
    procedure pnlBtnLoginMouseEnter(Sender: TObject);
    procedure pnlBtnLoginMouseLeave(Sender: TObject);
    procedure pnlBtnRegisterMouseEnter(Sender: TObject);
    procedure pnlBtnRegisterMouseLeave(Sender: TObject);
  private
    FApiService: TApiService;
    procedure SetApiService(AService: TApiService);
    procedure DoLogin;
  public
    property ApiService: TApiService read FApiService write SetApiService;
  end;

var
  frmLogin: TfrmLogin;

implementation

uses
  TaskManager.Client.Forms.Register,
  TaskManager.Client.Forms.Main;

{$R *.dfm}

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  Caption := 'TaskManager - Login';
  lblStatus.Caption := '';

  // Estilo moderno nos botoes via Panel
  pnlBtnLogin.Cursor := crHandPoint;
  pnlBtnRegister.Cursor := crHandPoint;
end;

procedure TfrmLogin.SetApiService(AService: TApiService);
begin
  FApiService := AService;
end;

procedure TfrmLogin.DoLogin;
begin
  if Trim(edtEmail.Text).IsEmpty then
  begin
    lblStatus.Caption := 'Informe o e-mail';
    lblStatus.Font.Color := $004040FF;
    edtEmail.SetFocus;
    Exit;
  end;

  if Trim(edtPassword.Text).IsEmpty then
  begin
    lblStatus.Caption := 'Informe a senha';
    lblStatus.Font.Color := $004040FF;
    edtPassword.SetFocus;
    Exit;
  end;

  lblStatus.Caption := 'Autenticando...';
  lblStatus.Font.Color := $00CC8800;
  Application.ProcessMessages;

  try
    if FApiService.Login(edtEmail.Text, edtPassword.Text) then
    begin
      lblStatus.Caption := 'Login realizado com sucesso!';
      lblStatus.Font.Color := $0000AA00;

      frmMain := TfrmMain.Create(Application);
      frmMain.ApiService := FApiService;
      Hide;
      frmMain.Show;
    end;
  except
    on E: Exception do
    begin
      lblStatus.Caption := E.Message;
      lblStatus.Font.Color := $004040FF;
    end;
  end;
end;

procedure TfrmLogin.pnlBtnLoginClick(Sender: TObject);
begin
  DoLogin;
end;

procedure TfrmLogin.pnlBtnRegisterClick(Sender: TObject);
var
  LFormRegister: TfrmRegister;
begin
  LFormRegister := TfrmRegister.Create(Self);
  try
    LFormRegister.ApiService := FApiService;
    if LFormRegister.ShowModal = mrOk then
    begin
      edtEmail.Text := LFormRegister.RegisteredEmail;
      edtPassword.SetFocus;
      lblStatus.Caption := 'Conta criada! Faca login.';
      lblStatus.Font.Color := $0000AA00;
    end;
  finally
    LFormRegister.Free;
  end;
end;

procedure TfrmLogin.pnlBtnLoginMouseEnter(Sender: TObject);
begin
  pnlBtnLogin.Color := $00CC5500; // Hover mais escuro
end;

procedure TfrmLogin.pnlBtnLoginMouseLeave(Sender: TObject);
begin
  pnlBtnLogin.Color := $00EE7700; // Cor normal
end;

procedure TfrmLogin.pnlBtnRegisterMouseEnter(Sender: TObject);
begin
  pnlBtnRegister.Color := $00F0F0F0;
end;

procedure TfrmLogin.pnlBtnRegisterMouseLeave(Sender: TObject);
begin
  pnlBtnRegister.Color := clWhite;
end;

procedure TfrmLogin.edtPasswordKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    DoLogin;
  end;
end;

end.
