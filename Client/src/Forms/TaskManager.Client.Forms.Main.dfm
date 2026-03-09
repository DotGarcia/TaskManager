object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'TaskManager BDMG'
  ClientHeight = 560
  ClientWidth = 860
  Color = clWhitesmoke
  Font.Charset = DEFAULT_CHARSET
  Font.Color = 3355443
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 17
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 860
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    Color = 3355443
    ParentBackground = False
    TabOrder = 0
    ExplicitWidth = 858
    DesignSize = (
      860
      56)
    object lblWelcome: TLabel
      Left = 20
      Top = 16
      Width = 173
      Height = 25
      Caption = 'TaskManager BDMG'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -18
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object pnlBtnLogout: TPanel
      Left = 758
      Top = 12
      Width = 80
      Height = 32
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Caption = 'Sair'
      Color = 5592405
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13421772
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 0
      OnClick = pnlBtnLogoutClick
    end
    object pnlBtnRefresh: TPanel
      Left = 664
      Top = 12
      Width = 88
      Height = 32
      Anchors = [akTop, akRight]
      BevelOuter = bvNone
      Caption = 'Atualizar'
      Color = 5592405
      Font.Charset = DEFAULT_CHARSET
      Font.Color = 13421772
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentBackground = False
      ParentFont = False
      TabOrder = 1
      OnClick = pnlBtnRefreshClick
      ExplicitLeft = 662
    end
  end
  object pgcMain: TPageControl
    Left = 0
    Top = 56
    Width = 860
    Height = 480
    ActivePage = tabTasks
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 3355443
    Font.Height = -13
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    ExplicitWidth = 858
    ExplicitHeight = 472
    object tabTasks: TTabSheet
      Caption = '  Tarefas  '
      object pnlTaskActions: TPanel
        Left = 0
        Top = 0
        Width = 852
        Height = 52
        Align = alTop
        BevelOuter = bvNone
        Color = clWhite
        ParentBackground = False
        TabOrder = 0
        ExplicitWidth = 850
        object pnlBtnAdd: TPanel
          Left = 12
          Top = 10
          Width = 130
          Height = 32
          BevelOuter = bvNone
          Caption = '+ Nova Tarefa'
          Color = 15628032
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 0
          OnClick = pnlBtnAddClick
        end
        object pnlBtnStatus: TPanel
          Left = 154
          Top = 10
          Width = 140
          Height = 32
          BevelOuter = bvNone
          Caption = 'Alterar Status'
          Color = 15921906
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 5592405
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentBackground = False
          ParentFont = False
          TabOrder = 1
          OnClick = pnlBtnStatusClick
        end
        object pnlBtnDelete: TPanel
          Left = 306
          Top = 10
          Width = 110
          Height = 32
          BevelOuter = bvNone
          Caption = 'Remover'
          Color = 15921906
          Font.Charset = DEFAULT_CHARSET
          Font.Color = 4210943
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentBackground = False
          ParentFont = False
          TabOrder = 2
          OnClick = pnlBtnDeleteClick
        end
      end
      object lvTasks: TListView
        Left = 0
        Top = 52
        Width = 852
        Height = 396
        Align = alClient
        Color = clWhite
        Columns = <>
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 3355443
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = []
        GridLines = True
        RowSelect = True
        ParentFont = False
        TabOrder = 1
        ViewStyle = vsReport
      end
    end
    object tabStats: TTabSheet
      Caption = '  Estatisticas  '
      OnShow = tabStatsShow
      object pnlStats: TPanel
        Left = 0
        Top = 0
        Width = 852
        Height = 448
        Align = alClient
        BevelOuter = bvNone
        Color = clWhitesmoke
        ParentBackground = False
        TabOrder = 0
        object pnlStatCard1: TPanel
          Left = 40
          Top = 40
          Width = 240
          Height = 120
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 0
          object lblStatTitle1: TLabel
            Left = 20
            Top = 20
            Width = 93
            Height = 17
            Caption = 'Total de Tarefas'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 8947848
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblStatValue1: TLabel
            Left = 20
            Top = 52
            Width = 18
            Height = 45
            Caption = '0'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 15628032
            Font.Height = -32
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlStatCard2: TPanel
          Left = 306
          Top = 40
          Width = 240
          Height = 120
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 1
          object lblStatTitle2: TLabel
            Left = 20
            Top = 20
            Width = 174
            Height = 17
            Caption = 'Media Prioridade (Pendentes)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 8947848
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblStatValue2: TLabel
            Left = 20
            Top = 52
            Width = 63
            Height = 45
            Caption = '0.00'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 15628032
            Font.Height = -32
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlStatCard3: TPanel
          Left = 572
          Top = 40
          Width = 240
          Height = 120
          BevelOuter = bvNone
          Color = clWhite
          ParentBackground = False
          TabOrder = 2
          object lblStatTitle3: TLabel
            Left = 20
            Top = 20
            Width = 110
            Height = 17
            Caption = 'Concluidas (7 dias)'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 8947848
            Font.Height = -13
            Font.Name = 'Segoe UI'
            Font.Style = []
            ParentFont = False
          end
          object lblStatValue3: TLabel
            Left = 20
            Top = 52
            Width = 18
            Height = 45
            Caption = '0'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = 15628032
            Font.Height = -32
            Font.Name = 'Segoe UI'
            Font.Style = [fsBold]
            ParentFont = False
          end
        end
        object pnlBtnRefreshStats: TPanel
          Left = 40
          Top = 190
          Width = 200
          Height = 40
          BevelOuter = bvNone
          Caption = 'Atualizar Estatisticas'
          Color = 15628032
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentBackground = False
          ParentFont = False
          TabOrder = 3
          OnClick = pnlBtnRefreshStatsClick
        end
      end
    end
  end
  object sbStatus: TStatusBar
    Left = 0
    Top = 536
    Width = 860
    Height = 24
    Font.Charset = DEFAULT_CHARSET
    Font.Color = 6710886
    Font.Height = -12
    Font.Name = 'Segoe UI'
    Font.Style = []
    Panels = <>
    SimplePanel = True
    SimpleText = 'Pronto'
    UseSystemFont = False
    ExplicitTop = 528
    ExplicitWidth = 858
  end
end
