program serverBackup_daemon;

uses
  Vcl.SvcMgr,
  ServiceUnit in 'ServiceUnit.pas' {Backup4you: TService},
  FTPSUnit in 'FTPSUnit.pas',
  HtmlUnit in 'HtmlUnit.pas',
  jobsThreadUnit in 'jobsThreadUnit.pas',
  mainUnit in 'mainUnit.pas' {DataModule2: TDataModule},
  messageExecute in 'messageExecute.pas',
  MySQLUnit in 'MySQLUnit.pas',
  SocketUnit in 'SocketUnit.pas',
  varsUnit in 'varsUnit.pas';

{$R *.RES}

begin
  // Windows 2003 Server requires StartServiceCtrlDispatcher to be
  // called before CoRegisterClassObject, which can be called indirectly
  // by Application.Initialize. TServiceApplication.DelayInitialize allows
  // Application.Initialize to be called from TService.Main (after
  // StartServiceCtrlDispatcher has been called).
  //
  // Delayed initialization of the Application object may affect
  // events which then occur prior to initialization, such as
  // TService.OnCreate. It is only recommended if the ServiceApplication
  // registers a class object with OLE and is intended for use with
  // Windows 2003 Server.
  //
  // Application.DelayInitialize := True;
  //
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;
  Application.CreateForm(TBackup4you, Backup4you);
//  Application.CreateForm(TDataModule2, DataModule2);
  Application.Run;
end.
