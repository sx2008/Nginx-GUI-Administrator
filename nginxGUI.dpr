program nginxGUI;

uses
  Vcl.Forms,
  main in 'main.pas' {GUI},
  process in 'process.pas',
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TGUI, GUI);
  Application.Run;
end.
