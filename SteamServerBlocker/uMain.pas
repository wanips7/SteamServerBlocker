{

  Steam Server Blocker

  https://github.com/wanips7/SteamServerBlocker

}

unit uMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Grids, uServerBlocker;

type
  TMainForm = class(TForm)
    ButtonSwitchServer: TButton;
    ButtonUpdate: TButton;
    ServersStringGrid: TStringGrid;
    LabelStatus: TLabel;
    ButtonPingServers: TButton;
    ButtonUnblockAll: TButton;
    ButtonBlockAll: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonSwitchServerClick(Sender: TObject);
    procedure ButtonUpdateClick(Sender: TObject);
    procedure ServersStringGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure ButtonPingServersClick(Sender: TObject);
    procedure ButtonUnblockAllClick(Sender: TObject);
    procedure ButtonBlockAllClick(Sender: TObject);
  private
    FServerDataUpdater: TServerDataUpdater;
    procedure AddServerDataToGrid(const Value: TServerData);
    procedure LoadServerDataToGrid;
    procedure InitServersGrid;
    procedure SwitchServer(const Name: string);
    procedure SetStatus(const Value: string);
    procedure PingServers;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;
  AppPath: string;

implementation

{$R *.dfm}

uses
  uPing;

const
  APP_VERSION = '0.8.1';
  SERVERS_FILENAME = 'Servers.db';
  ALLOWED_TEXT = '✔';
  BLOCKED_TEXT = '✖';
  NOT_ACCESS_TEXT = 'N/A';

procedure TMainForm.AddServerDataToGrid(const Value: TServerData);
var
  Row: Integer;
  Ping: Integer;
  Text: string;
begin
  Row := ServersStringGrid.RowCount;

  ServersStringGrid.RowCount := Row + 1;
  ServersStringGrid.Cells[0, Row] := Value.Name;

  if Value.Ping = NOT_RESPONDING then
    Text := NOT_ACCESS_TEXT
  else
    Text := Value.Ping.ToString;

  ServersStringGrid.Cells[1, Row] := Text;

  if Value.IsBlocked then
    Text := BLOCKED_TEXT
  else
    Text := ALLOWED_TEXT;

  ServersStringGrid.Cells[2, Row] := Text;

  ServersStringGrid.FixedRows := 1;
end;

procedure TMainForm.ButtonUnblockAllClick(Sender: TObject);
begin
  TServerBlocker.Unblock(FServerDataUpdater.List);

  LoadServerDataToGrid;
end;

procedure TMainForm.ButtonBlockAllClick(Sender: TObject);
begin
  TServerBlocker.Block(FServerDataUpdater.List);

  LoadServerDataToGrid;
end;

procedure TMainForm.ButtonPingServersClick(Sender: TObject);
begin
  PingServers;
end;

procedure TMainForm.ButtonSwitchServerClick(Sender: TObject);
var
  Name: string;
  Row: Integer;
begin
  Row := ServersStringGrid.Row;

  if Row > 0 then
  begin
    Name := ServersStringGrid.Cells[0, Row];

    SwitchServer(Name);

    LoadServerDataToGrid;
  end;

end;

procedure TMainForm.ButtonUpdateClick(Sender: TObject);
begin
  SetStatus('Updating server data...');

  FServerDataUpdater.Update;

  PingServers;

end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  AppPath := ExtractFilePath(ParamStr(0));

  FServerDataUpdater := TServerDataUpdater.Create;

  FServerDataUpdater.LoadFromFile(AppPath + SERVERS_FILENAME);
  LoadServerDataToGrid;

  Caption := 'Steam Server Blocker' + ' ' + APP_VERSION;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FServerDataUpdater.SaveToFile(AppPath + SERVERS_FILENAME);

  FServerDataUpdater.Free;
end;

procedure TMainForm.InitServersGrid;
begin
  ServersStringGrid.RowCount := 1;

  ServersStringGrid.Cells[0, 0] := 'Name';
  ServersStringGrid.Cells[1, 0] := 'Ping';
  ServersStringGrid.Cells[2, 0] := 'Status';

  ServersStringGrid.ColWidths[0] := 180;
  ServersStringGrid.ColWidths[1] := 60;
  ServersStringGrid.ColWidths[2] := 60;

end;

procedure TMainForm.LoadServerDataToGrid;
var
  ServerData: TServerData;
begin
  InitServersGrid;

  for ServerData in FServerDataUpdater.List do
  begin
    AddServerDataToGrid(ServerData);
  end;

  SetStatus('Server count: ' + FServerDataUpdater.List.Count.ToString);
end;

procedure TMainForm.PingServers;
begin
  SetStatus('Pinging...');

  FServerDataUpdater.PingServers;

  LoadServerDataToGrid;
end;

procedure TMainForm.ServersStringGridDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Text: string;
  Ping: Integer;
  Color: TColor;
begin
  Text := ServersStringGrid.Cells[ACol, ARow];
  Color := clBlack;

  if ARow > 0 then
    if ACol = 2 then
    begin
      if Text = ALLOWED_TEXT then
        Color := clGreen
      else
        Color := clRed;
    end
      else
    if ACol = 1 then
    begin
      if TryStrToInt(Text, Ping) then
      begin
        if Ping < 50 then
          Color := clGreen
        else
          if Ping >= 100 then
            Color := clWebFirebrick
          else
            Color := clWebOrange;
      end;
    end;

  ServersStringGrid.Canvas.Font.Color := Color;
  ServersStringGrid.Canvas.TextOut(Rect.Left + 6, Rect.Top + 2, Text);
end;

procedure TMainForm.SetStatus(const Value: string);
begin
  LabelStatus.Caption := Value;

  Application.ProcessMessages;
end;

procedure TMainForm.SwitchServer(const Name: string);
var
  ServerData: PServerData;
begin
  if FServerDataUpdater.GetServerDataByName(Name, ServerData) then
  begin
    if ServerData.IsBlocked then
      TServerBlocker.Unblock(ServerData)
    else
      TServerBlocker.Block(ServerData);
  end;

end;

end.
