unit TaskManager.Client.Forms.Register;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  TaskManager.Client.ApiService;

type
  TfrmRegister = class(TForm)
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblName: TLabel;
    edtName: TEdit;
    lblEmail: TLabel;
    edtEmail: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
    lblConfirmPassword: TLabel;
    edtConfirmPassword: TEdit;
    pnlBtnRegister: TPanel;
    pnlBtnCancel: TPanel;
    lblStatus: TLabel;
    shpLine: TShape;
    procedure FormCreate(Sender: TObject);
    procedure pnlBtnRegisterClick(Sender: TObject);
    procedure pnlBtnCancelClick(Sender: TObject);
    procedure pnlBtnRegisterMouseEnter(Sender: TObject);
    procedure pnlBtnRegisterMouseLeave(Sender: TObject);
    procedure pnlBtnCancelMouseEnter(Sender: TObject);
    procedure pnlBtnCancelMouseLeave(Sender: TObject);
  private
    FApiService: TApiService;
    FRegisteredEmail: string;
  public
    property ApiService: TApiService read FApiService write FApiService;
    property RegisteredEmail: string read FRegisteredEmail;
  end;

var
  frmRegister: TfrmRegister;

implementation

{$R *.dfm}

procedure TfrmRegister.FormCreate(Sender: TObject);
begin
  Caption := 'TaskManager - Nova Conta';
  lblStatus.Caption := '';
  pnlBtnRegister.Cursor := crHandPoint;
  pnlBtnCancel.Cursor := crHandPoint;
end;

procedure TfrmRegister.pnlBtnRegisterClick(Sender: TObject);
begin
  if Trim(edtName.Text).IsEmpty then
  begin
    lblStatus.Caption := 'Informe o nome';
    lblStatus.Font.Color := $004040FF;
    edtName.SetFocus;
    Exit;
  end;

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

  if edtPassword.Text <> edtConfirmPassword.Text then
  begin
    lblStatus.Caption := 'As senhas nao conferem';
    lblStatus.Font.Color := $004040FF;
    edtConfirmPassword.SetFocus;
    Exit;
  end;

  lblStatus.Caption := 'Cadastrando...';
  lblStatus.Font.Color := $00CC8800;
  Application.ProcessMessages;

  try
    FApiService.Register(edtName.Text, edtEmail.Text, edtPassword.Text);
    FRegisteredEmail := edtEmail.Text;
    ModalResult := mrOk;
  except
    on E: Exception do
    begin
      lblStatus.Caption := E.Message;
      lblStatus.Font.Color := $004040FF;
    end;
  end;
end;

procedure TfrmRegister.pnlBtnCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmRegister.pnlBtnRegisterMouseEnter(Sender: TObject);
begin
  pnlBtnRegister.Color := $00CC5500;
end;

procedure TfrmRegister.pnlBtnRegisterMouseLeave(Sender: TObject);
begin
  pnlBtnRegister.Color := $00EE7700;
end;

procedure TfrmRegister.pnlBtnCancelMouseEnter(Sender: TObject);
begin
  pnlBtnCancel.Color := $00F0F0F0;
end;

procedure TfrmRegister.pnlBtnCancelMouseLeave(Sender: TObject);
begin
  pnlBtnCancel.Color := clWhite;
end;

end.
