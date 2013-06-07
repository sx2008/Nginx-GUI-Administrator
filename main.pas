{
_________      .__                                    .__    .__
\______   \____ |  | ___.__. _____   _________________ |  |__ |__| ____
 |     ___/  _ \|  |<   |  |/     \ /  _ \_  __ \____ \|  |  \|  |/    \
 |    |  (  <_> )  |_\___  |  Y Y  (  <_> )  | \/  |_> >   Y  \  |   |  \
 |____|   \____/|____/ ____|__|_|  /\____/|__|  |   __/|___|  /__|___|  /
                     \/          \/             |__|        \/        \/
        [explosiv2k - Polymorphin @ 2013-06-05 17:11:01]
}
unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Imaging.jpeg,
  Vcl.ExtCtrls, Vcl.ImgList, Vcl.Imaging.pngimage, ShellApi, process, Registry;

type
  TGUI = class(TForm)
    MainBox: TGroupBox;
    Memo1: TMemo;
    Autostart: TLabel;
    Port: TLabel;
    Action: TLabel;
    btStart: TButton;
    btEdtConf: TButton;
    Status: TLabel;
    lblStatus: TLabel;
    btnAutostart: TButton;
    ImageList1: TImageList;
    lblHTTP: TLabel;
    Line1: TBevel;
    Memo2: TMemo;
    lblALog: TLabel;
    lblELog: TLabel;
    LogTimer: TTimer;
    lblHTTPS: TLabel;
    procedure btStartClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnAutostartClick(Sender: TObject);
    procedure LogTimerTimer(Sender: TObject);
    procedure btEdtConfClick(Sender: TObject);
  private
    function AutoStartExist: Boolean;
    procedure loadAccess;
    procedure loadErrors;
    procedure refreshLogs;
    procedure loadPort;
    function OnlyNumbersInString(const aValue: String): String;
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  GUI: TGUI;
  IsRunning : Boolean = False;
  IsAutoStart : Boolean = False;
  sConfPath: String;

implementation

{$R *.dfm}

procedure TGUI.btStartClick(Sender: TObject);
var
  sPath: String;
begin
  if not IsRunning then begin // Wenn IsRunning auf False ist
    try
      sPath := ExtractFileName(Application.Exename);
      loadPort;
      ShellExecute(Application.Handle,'open','nginx.exe',''{Parameter},'sPath',SW_HIDE);
      begin
        if IsExeRunning('nginx.exe') then begin
          IsRunning := True;
          btStart.Caption := 'Stop';
          lblStatus.Font.Color := clGreen;
          lblStatus.Caption := 'Server started';
          LogTimer.Enabled  := True;
        end
        else begin
          IsRunning := False;
          btStart.Caption := 'Start';
          lblStatus.Font.Color := clGray;
          lblStatus.Caption := 'Server is not started.';
        end;
     end;
    except
      ShowMessage('Nginx.exe could not be started. Please check that nginx.exe exists.');
    end;
  end
  else begin      // Wenn IsRunning auf True ist
      try
      KillTask('nginx.exe');
      lblStatus.Font.Color := clGray;
      lblStatus.Caption := 'Server is not started';
      btStart.Caption := 'Start';
      IsRunning := False;
      except
        ShowMessage('Nginx.exe could not be terminated.');
      end;
    end;
end;

procedure TGUI.btEdtConfClick(Sender: TObject);
var
  sPath, conf: String;
begin
  try
  sConfPath := GetCurrentDir + '\conf\' + 'nginx.conf';
  ShellExecute(Handle, nil, PChar('notepad.exe'),
    PChar(sConfPath),
    nil, SW_SHOWNORMAL)
  except
    ShowMessage('Invalid config path.');
  end;
end;

procedure TGUI.btnAutostartClick(Sender: TObject);
var
  reg : TRegistry;
  sNGINXPath: String;
begin
  if not IsAutoStart then begin
    reg := tregistry.create;
    with reg do
    begin
      sNGINXPath := GetCurrentDir;
      RootKey := HKEY_LOCAL_MACHINE;
      OpenKey('Software\Microsoft\Windows\CurrentVersion\Run', true);
      WriteString('Nginx', sNGINXPath + '\nginx.exe');
      btnAutostart.ImageIndex := -1;
      btnAutostart.ImageIndex := 5;
      IsAutoStart := True;
      CloseKey;
      Free;
    end
  end
  else
    with TRegistry.Create do try
      RootKey:=HKEY_LOCAL_MACHINE;
      OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', False);
      DeleteValue('Nginx');
      btnAutostart.ImageIndex := -1;
      btnAutostart.ImageIndex := 0;
      IsAutoStart := False;
    finally
      Free;
    end;
end;

procedure TGUI.FormCreate(Sender: TObject);
begin
  try
  AutoStartExist;
  loadPort;
  if IsExeRunning('nginx.exe') then begin
    IsRunning := True;
    btStart.Caption := 'Stop';
    lblStatus.Font.Color := clGreen;
    lblStatus.Caption := 'Server started.';
    refreshLogs;
  end
  else begin
    IsRunning := False;
    btStart.Caption := 'Start';
    lblStatus.Font.Color := clGray;
    lblStatus.Caption := 'Server is not started.';
  end;
  except
    ShowMessage('Please provide that the nginx folder is complete and in the original file format.');
  end;

  end;

function TGUI.AutoStartExist: Boolean;
var
  reg : TRegistry;
begin
    with TRegistry.Create do try
      RootKey:=HKEY_LOCAL_MACHINE;
      OpenKeyReadOnly('\Software\Microsoft\Windows\CurrentVersion\Run');
      if ValueExists('Nginx') then begin
        Result := True;
        btnAutostart.ImageIndex := 5;
        IsAutoStart := True
    end
    else begin
      Result := False;
      btnAutostart.ImageIndex := 0;
      IsAutoStart := False;
    end;
    finally
      Free;
    end;
end;

procedure TGUI.loadAccess;
var
  sLogPath: String;
  p1, p2: String;
  stream: TStream;
begin
   sLogPath := GetCurrentDir;
   p1 := sLogPath + '\logs\' + 'access.log';
   p2 := sLogPath + '\logs\' + 'error.log';
      stream := TFileStream.Create(p1, fmOpenRead or fmShareDenyNone);
      try
         Memo1.Lines.LoadFromStream(stream);
      finally
         stream.Free;
      end;
end;

procedure TGUI.loadErrors;
var
  sLogPath: String;
  p1 : String;
  stream: TStream;
begin
   sLogPath := GetCurrentDir;
   p1 := sLogPath + '\logs\' + 'error.log';
      stream := TFileStream.Create(p1, fmOpenRead or fmShareDenyNone);
      try
         Memo2.Lines.LoadFromStream(stream);
      finally
         stream.Free;
      end;
end;


procedure TGUI.LogTimerTimer(Sender: TObject);
begin
  refreshLogs;
end;

procedure TGUI.refreshLogs;
begin
  loadAccess;
  loadErrors;
  SendMessage(Memo1.Handle, WM_VScroll, SB_Bottom, 0);  // Automatischer Memo Scroll nach unten
  SendMessage(Memo2.Handle, WM_VScroll, SB_Bottom, 0); // Automatischer Memo Scroll nach unten
end;

procedure TGUI.loadPort;
var
  list: TStringlist;
begin
  try
  sConfPath := GetCurrentDir + '\conf\' + 'nginx.conf';
  list := TStringlist.create;
  list.loadfromfile(sConfPath);
  lblHTTP.Caption  := 'HTTP ' + OnlyNumbersInString(list.strings[35]);
  lblHTTPS.Caption := 'HTTPS ' + OnlyNumbersInString(list.strings[98]);
  finally
    list.free;
  end;
end;

function TGUI.OnlyNumbersInString(const aValue: String): String;
const aChars = ['0'..'9'];
var
  i, j: integer;
begin
  SetLength(Result,Length(aValue));
  j := 0;
  for i := 1 to Length(aValue) do
  begin
    if (aValue[i] in aChars) then
    begin
      inc(j);
      Result[j] := aValue[i];
    end;
  end;
  SetLength(Result, j);
end;

end.
