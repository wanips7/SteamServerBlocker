object MainForm: TMainForm
  Left = 0
  Top = 0
  VertScrollBar.Smooth = True
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'Steam Server Blocker'
  ClientHeight = 502
  ClientWidth = 437
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -15
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesktopCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 120
  TextHeight = 20
  object LabelStatus: TLabel
    Left = 9
    Top = 478
    Width = 97
    Height = 20
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Server count: 0'
  end
  object ButtonSwitchServer: TButton
    Left = 352
    Top = 9
    Width = 85
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Switch'
    TabOrder = 0
    OnClick = ButtonSwitchServerClick
  end
  object ButtonUpdate: TButton
    Left = 353
    Top = 442
    Width = 85
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Update'
    TabOrder = 1
    OnClick = ButtonUpdateClick
  end
  object ServersStringGrid: TStringGrid
    Left = 4
    Top = 4
    Width = 341
    Height = 466
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    ColCount = 3
    DefaultColWidth = 140
    FixedCols = 0
    RowCount = 1
    FixedRows = 0
    Options = [goFixedVertLine, goFixedHorzLine, goHorzLine, goRowSelect, goThumbTracking, goFixedRowDefAlign]
    ScrollBars = ssVertical
    TabOrder = 2
    OnDrawCell = ServersStringGridDrawCell
  end
  object ButtonPingServers: TButton
    Left = 353
    Top = 409
    Width = 85
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Ping'
    TabOrder = 3
    OnClick = ButtonPingServersClick
  end
  object ButtonUnblockAll: TButton
    Left = 353
    Top = 42
    Width = 85
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Unblock all'
    TabOrder = 4
    OnClick = ButtonUnblockAllClick
  end
  object ButtonBlockAll: TButton
    Left = 353
    Top = 75
    Width = 85
    Height = 25
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Caption = 'Block all'
    TabOrder = 5
    OnClick = ButtonBlockAllClick
  end
end
