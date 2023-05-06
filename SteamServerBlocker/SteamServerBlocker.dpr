program SteamServerBlocker;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {MainForm},
  uPing in 'uPing.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Material White Smoke');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
