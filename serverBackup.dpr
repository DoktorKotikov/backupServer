program serverBackup;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  mainUnit in 'mainUnit.pas' {DataModule2: TDataModule},
  varsUnit in 'varsUnit.pas',
  SocketUnit in 'SocketUnit.pas',
  messageExecute in 'messageExecute.pas',
  MySQLUnit in 'MySQLUnit.pas',
  jobsThreadUnit in 'jobsThreadUnit.pas',
  HtmlUnit in 'HtmlUnit.pas';

begin
  try
    DataModule2:= TDataModule2.Create(nil);

    repeat
      Sleep(1000);
    until False ;
    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
