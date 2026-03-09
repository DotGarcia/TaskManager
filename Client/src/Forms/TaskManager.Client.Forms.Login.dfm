object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'TaskManager - Login'
  ClientHeight = 420
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
    Top = 20
    Width = 380
    Height = 380
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 0
      Top = 30
      Width = 380
      Height = 32
      Alignment = taCenter
      AutoSize = False
      Caption = 'TaskManager'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -24
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblSubtitle: TLabel
      Left = 0
      Top = 62
      Width = 380
      Height = 17
      Alignment = taCenter
      AutoSize = False
      Caption = 'BDMG - Gerenciador de Tarefas'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 10066329
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object shpLine: TShape
      Left = 50
      Top = 96
      Width = 280
      Height = 1
      Brush.Color = 14737632
      Pen.Color = 14737632
    end
    object lblEmail: TLabel
      Left = 50
      Top = 116
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
      Top = 180
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
    object lblStatus: TLabel
      Left = 50
      Top = 348
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
    object edtEmail: TEdit
      Left = 50
      Top = 138
      Width = 280
      Height = 27
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
    end
    object edtPassword: TEdit
      Left = 50
      Top = 202
      Width = 280
      Height = 27
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 3355443
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      PasswordChar = '*'
      TabOrder = 1
      OnKeyPress = edtPasswordKeyPress
    end
    object pnlBtnLogin: TPanel
      Left = 50
      Top = 256
      Width = 280
      Height = 40
      BevelOuter = bvNone
      Caption = 'ENTRAR'
      Color = 15628032
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -14
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentBackground = False
      ParentFont = False
      TabOrder = 2
      OnClick = pnlBtnLoginClick
      OnMouseEnter = pnlBtnLoginMouseEnter
      OnMouseLeave = pnlBtnLoginMouseLeave
    end
    object pnlBtnRegister: TPanel
      Left = 50
      Top = 304
      Width = 280
      Height = 36
      BevelOuter = bvNone
      Caption = 'Criar nova conta'
      Color = clWhite
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 15628032
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 3
      OnClick = pnlBtnRegisterClick
      OnMouseEnter = pnlBtnRegisterMouseEnter
      OnMouseLeave = pnlBtnRegisterMouseLeave
    end
  end
end
