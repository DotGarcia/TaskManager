object frmRegister: TfrmRegister
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'TaskManager - Nova Conta'
  ClientHeight = 500
  ClientWidth = 440
  Color = clWhitesmoke
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 3355443
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  TextHeight = 17
  object pnlMain: TPanel
    Left = 30
    Top = 16
    Width = 380
    Height = 468
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 0
      Top = 24
      Width = 380
      Height = 28
      Alignment = taCenter
      AutoSize = False
      Caption = 'Criar Nova Conta'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -22
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object shpLine: TShape
      Left = 50
      Top = 66
      Width = 280
      Height = 1
      Brush.Color = 14737632
      Pen.Color = 14737632
    end
    object lblName: TLabel
      Left = 50
      Top = 82
      Width = 36
      Height = 17
      Caption = 'Nome'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblEmail: TLabel
      Left = 50
      Top = 140
      Width = 36
      Height = 17
      Caption = 'E-mail'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblPassword: TLabel
      Left = 50
      Top = 198
      Width = 35
      Height = 17
      Caption = 'Senha'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblConfirmPassword: TLabel
      Left = 50
      Top = 256
      Width = 97
      Height = 17
      Caption = 'Confirmar Senha'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 6710886
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblStatus: TLabel
      Left = 50
      Top = 424
      Width = 280
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 4210943
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object edtName: TEdit
      Left = 50
      Top = 102
      Width = 280
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object edtEmail: TEdit
      Left = 50
      Top = 160
      Width = 280
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
    end
    object edtPassword: TEdit
      Left = 50
      Top = 218
      Width = 280
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 2
    end
    object edtConfirmPassword: TEdit
      Left = 50
      Top = 276
      Width = 280
      Height = 28
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 3
    end
    object pnlBtnRegister: TPanel
      Left = 50
      Top = 330
      Width = 280
      Height = 40
      BevelOuter = bvNone
      Caption = 'CADASTRAR'
      Color = 15628032
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 4
      OnClick = pnlBtnRegisterClick
      OnMouseEnter = pnlBtnRegisterMouseEnter
      OnMouseLeave = pnlBtnRegisterMouseLeave
    end
    object pnlBtnCancel: TPanel
      Left = 50
      Top = 378
      Width = 280
      Height = 36
      BevelOuter = bvNone
      Caption = 'Cancelar'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 8947848
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 5
      OnClick = pnlBtnCancelClick
      OnMouseEnter = pnlBtnCancelMouseEnter
      OnMouseLeave = pnlBtnCancelMouseLeave
    end
  end
end
