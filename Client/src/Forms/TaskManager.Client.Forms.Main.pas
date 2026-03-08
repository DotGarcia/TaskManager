unit TaskManager.Client.Forms.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  TaskManager.Client.ApiService;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblWelcome: TLabel;
    pnlBtnLogout: TPanel;
    pnlBtnRefresh: TPanel;
    pgcMain: TPageControl;
    tabTasks: TTabSheet;
    tabStats: TTabSheet;
    // Aba Tarefas
    pnlTaskActions: TPanel;
    pnlBtnAdd: TPanel;
    pnlBtnStatus: TPanel;
    pnlBtnDelete: TPanel;
    lvTasks: TListView;
    // Aba Estatisticas
    pnlStats: TPanel;
    pnlStatCard1: TPanel;
    lblStatTitle1: TLabel;
    lblStatValue1: TLabel;
    pnlStatCard2: TPanel;
    lblStatTitle2: TLabel;
    lblStatValue2: TLabel;
    pnlStatCard3: TPanel;
    lblStatTitle3: TLabel;
    lblStatValue3: TLabel;
    pnlBtnRefreshStats: TPanel;
    // Status bar
    sbStatus: TStatusBar;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pnlBtnLogoutClick(Sender: TObject);
    procedure pnlBtnRefreshClick(Sender: TObject);
    procedure pnlBtnAddClick(Sender: TObject);
    procedure pnlBtnStatusClick(Sender: TObject);
    procedure pnlBtnDeleteClick(Sender: TObject);
    procedure pnlBtnRefreshStatsClick(Sender: TObject);
    procedure tabStatsShow(Sender: TObject);
    // Hover effects
    procedure PanelBtnMouseEnter(Sender: TObject);
    procedure PanelBtnMouseLeave(Sender: TObject);
    procedure PanelAccentMouseEnter(Sender: TObject);
    procedure PanelAccentMouseLeave(Sender: TObject);
  private
    FApiService: TApiService;
    procedure LoadTasks;
    procedure LoadStats;
    procedure HandleUnauthorized;
    procedure ShowLogin;
    procedure SetupHoverEffect(APanel: TPanel);
    procedure SetupAccentHoverEffect(APanel: TPanel);
  public
    property ApiService: TApiService read FApiService write FApiService;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  TaskManager.Client.Forms.Login;

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'TaskManager BDMG';

  // Configurar ListView
  lvTasks.ViewStyle := vsReport;
  lvTasks.RowSelect := True;
  lvTasks.GridLines := True;
  lvTasks.Font.Size := 10;

  with lvTasks.Columns.Add do begin Caption := 'ID'; Width := 50; end;
  with lvTasks.Columns.Add do begin Caption := 'Titulo'; Width := 220; end;
  with lvTasks.Columns.Add do begin Caption := 'Descricao'; Width := 200; end;
  with lvTasks.Columns.Add do begin Caption := 'Prioridade'; Width := 90; end;
  with lvTasks.Columns.Add do begin Caption := 'Status'; Width := 110; end;
  with lvTasks.Columns.Add do begin Caption := 'Criado em'; Width := 140; end;

  // Cursor de mao nos botoes
  pnlBtnAdd.Cursor := crHandPoint;
  pnlBtnStatus.Cursor := crHandPoint;
  pnlBtnDelete.Cursor := crHandPoint;
  pnlBtnRefresh.Cursor := crHandPoint;
  pnlBtnLogout.Cursor := crHandPoint;
  pnlBtnRefreshStats.Cursor := crHandPoint;

  // Hover effects
  SetupAccentHoverEffect(pnlBtnAdd);
  SetupHoverEffect(pnlBtnStatus);
  SetupHoverEffect(pnlBtnDelete);
  SetupAccentHoverEffect(pnlBtnRefreshStats);
end;

procedure TfrmMain.SetupHoverEffect(APanel: TPanel);
begin
  APanel.OnMouseEnter := PanelBtnMouseEnter;
  APanel.OnMouseLeave := PanelBtnMouseLeave;
end;

procedure TfrmMain.SetupAccentHoverEffect(APanel: TPanel);
begin
  APanel.OnMouseEnter := PanelAccentMouseEnter;
  APanel.OnMouseLeave := PanelAccentMouseLeave;
end;

procedure TfrmMain.PanelBtnMouseEnter(Sender: TObject);
begin
  (Sender as TPanel).Color := $00E8E8E8;
end;

procedure TfrmMain.PanelBtnMouseLeave(Sender: TObject);
begin
  (Sender as TPanel).Color := $00F2F2F2;
end;

procedure TfrmMain.PanelAccentMouseEnter(Sender: TObject);
begin
  (Sender as TPanel).Color := $00CC5500;
end;

procedure TfrmMain.PanelAccentMouseLeave(Sender: TObject);
begin
  (Sender as TPanel).Color := $00EE7700;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if not FApiService.IsAuthenticated then
    ShowLogin
  else
    LoadTasks;
end;

procedure TfrmMain.ShowLogin;
var
  LFormLogin: TfrmLogin;
begin
  LFormLogin := TfrmLogin.Create(Self);
  try
    LFormLogin.ApiService := FApiService;
    if LFormLogin.ShowModal = mrOk then
    begin
      lblWelcome.Caption := 'TaskManager BDMG';
      LoadTasks;
    end
    else
      Application.Terminate;
  finally
    LFormLogin.Free;
  end;
end;

procedure TfrmMain.HandleUnauthorized;
begin
  ShowMessage('Sessao expirada. Faca login novamente.');
  ShowLogin;
end;

procedure TfrmMain.LoadTasks;
var
  LTasks: TArray<TTaskDTO>;
  LTask: TTaskDTO;
  LItem: TListItem;
begin
  sbStatus.SimpleText := 'Carregando tarefas...';
  Application.ProcessMessages;
  try
    LTasks := FApiService.GetTasks;

    lvTasks.Items.BeginUpdate;
    try
      lvTasks.Items.Clear;
      for LTask in LTasks do
      begin
        LItem := lvTasks.Items.Add;
        LItem.Caption := IntToStr(LTask.Id);
        LItem.SubItems.Add(LTask.Title);
        LItem.SubItems.Add(LTask.Description);
        LItem.SubItems.Add(LTask.PriorityLabel);
        LItem.SubItems.Add(LTask.StatusLabel);
        LItem.SubItems.Add(LTask.CreatedAt);
        LItem.Data := Pointer(LTask.Id);
      end;
    finally
      lvTasks.Items.EndUpdate;
    end;

    sbStatus.SimpleText := Format('%d tarefa(s) encontrada(s)', [Length(LTasks)]);
  except
    on E: Exception do
    begin
      sbStatus.SimpleText := 'Erro: ' + E.Message;
      if Pos('Sessao expirada', E.Message) > 0 then
        HandleUnauthorized;
    end;
  end;
end;

procedure TfrmMain.LoadStats;
var
  LStats: TStatsDTO;
begin
  sbStatus.SimpleText := 'Carregando estatisticas...';
  Application.ProcessMessages;
  try
    LStats := FApiService.GetStats;

    lblStatValue1.Caption := IntToStr(LStats.TotalTasks);
    lblStatValue2.Caption := FormatFloat('0.00', LStats.AveragePendingPriority);
    lblStatValue3.Caption := IntToStr(LStats.CompletedLast7Days);

    sbStatus.SimpleText := 'Estatisticas atualizadas';
  except
    on E: Exception do
      sbStatus.SimpleText := 'Erro: ' + E.Message;
  end;
end;

procedure TfrmMain.pnlBtnRefreshClick(Sender: TObject);
begin
  LoadTasks;
end;

procedure TfrmMain.pnlBtnAddClick(Sender: TObject);
var
  LTitle, LDescription, LPriorityStr: string;
  LPriority: Integer;
begin
  LTitle := InputBox('Nova Tarefa', 'Titulo:', '');
  if LTitle.Trim.IsEmpty then Exit;

  LDescription := InputBox('Nova Tarefa', 'Descricao (opcional):', '');

  LPriorityStr := InputBox('Nova Tarefa',
    'Prioridade (1=Baixa, 2=Media, 3=Alta, 4=Critica):', '1');
  LPriority := StrToIntDef(LPriorityStr, 1);

  try
    FApiService.CreateTask(LTitle, LDescription, LPriority);
    LoadTasks;
    sbStatus.SimpleText := 'Tarefa criada com sucesso!';
  except
    on E: Exception do
      ShowMessage('Erro ao criar tarefa: ' + E.Message);
  end;
end;

procedure TfrmMain.pnlBtnStatusClick(Sender: TObject);
var
  LTaskId, LNewStatus: Integer;
  LStatusStr: string;
begin
  if lvTasks.Selected = nil then
  begin
    ShowMessage('Selecione uma tarefa na lista');
    Exit;
  end;

  LTaskId := StrToInt(lvTasks.Selected.Caption);

  LStatusStr := InputBox('Atualizar Status',
    'Novo status (0=Pendente, 1=Em Andamento, 2=Concluida):',
    lvTasks.Selected.SubItems[3]);
  LNewStatus := StrToIntDef(LStatusStr, -1);

  if not (LNewStatus in [0..2]) then
  begin
    ShowMessage('Status invalido. Use 0, 1 ou 2.');
    Exit;
  end;

  try
    FApiService.UpdateTaskStatus(LTaskId, LNewStatus);
    LoadTasks;
    sbStatus.SimpleText := 'Status atualizado!';
  except
    on E: Exception do
      ShowMessage('Erro: ' + E.Message);
  end;
end;

procedure TfrmMain.pnlBtnDeleteClick(Sender: TObject);
var
  LTaskId: Integer;
begin
  if lvTasks.Selected = nil then
  begin
    ShowMessage('Selecione uma tarefa na lista');
    Exit;
  end;

  LTaskId := StrToInt(lvTasks.Selected.Caption);

  if MessageDlg(Format('Remover tarefa "%s"?',
    [lvTasks.Selected.SubItems[0]]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FApiService.DeleteTask(LTaskId);
      LoadTasks;
      sbStatus.SimpleText := 'Tarefa removida!';
    except
      on E: Exception do
        ShowMessage('Erro: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.pnlBtnRefreshStatsClick(Sender: TObject);
begin
  LoadStats;
end;

procedure TfrmMain.tabStatsShow(Sender: TObject);
begin
  LoadStats;
end;

procedure TfrmMain.pnlBtnLogoutClick(Sender: TObject);
begin
  FApiService.Logout;
  lvTasks.Items.Clear;
  ShowLogin;
end;

end.
