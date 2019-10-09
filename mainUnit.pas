unit mainUnit;

interface

uses
  System.SysUtils, System.Classes, IdBaseComponent, IdComponent, SocketUnit, HtmlUnit, FTPSUnit,
  IdCustomTCPServer, IdTCPServer, IdContext, System.JSON, messageExecute, System.SyncObjs, System.Generics.Collections,
  myconfig.Logs, myconfig.ini, varsUnit, IdGlobal, System.Hash, FireDAC, MySQLUnit, jobsThreadUnit,
  IdCustomHTTPServer, IdHTTPServer, IdCookie, IdServerIOHandler, IdSSL,
  IdSSLOpenSSL, inifiles, IdCmdTCPServer, IdExplicitTLSClientServerBase,
  IdFTPServer

  ;


type
  TDataModule2 = class(TDataModule)
    IdTCPServer1: TIdTCPServer;
    IdHTTPServer1: TIdHTTPServer;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    IdFTPServer1: TIdFTPServer;
    procedure DataModuleCreate(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);

    procedure Check_NewJob();
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure IdFTPServer1UserLogin(ASender: TIdFTPServerContext;
      const AUsername, APassword: string; var AAuthenticated: Boolean);
    procedure IdFTPServer1UserAccount(ASender: TIdFTPServerContext;
      const AUsername, APassword, AAcount: string; var AAuthenticated: Boolean);
    procedure IdTCPServer1Exception(AContext: TIdContext;
      AException: Exception);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  DataModule2: TDataModule2;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure TDataModule2.Check_NewJob();
var
  i : Integer;
//  SocketConf : TSocketConf;
  Job           : Tjob;
  JS_JobResult  : TJSONObject;
  JS_JobsArray  : TJSONArray;

  FTPSocketConf : TFTPClient;
  JS : TJSONObject;
  JSArr : TJSONArray;
  Agent       : TAgent;
  result      : string;
begin
  {if jobsThread.GetJob_toDo(Job) = True then
  begin
    log.SaveLog('Read New Job from Quere');
    JS_JobResult  := TJsonObject.create;
    JS_JobsArray  := TJSONArray.Create;

    JS_JobResult.AddPair('AgentID',   TJSONNumber.Create(Job.AgentID));
    JS_JobsArray.Add(JS_JobResult);


    JS := TJSONObject.Create;
    JSArr := TJSONObject.ParseJSONValue(Job.job_scheduler.rules) as TJSONArray;

    JS.AddPair('sendto', 'server');
    JS.AddPair('action', 'newJob');

    JS.AddPair('job',  JSArr);

    if AllAgents.GetSocketConf(Job.AgentID, Agent) then
    begin
      try
        if Agent.AContext <> nil then
        begin
          Agent.AContext.Connection.Socket.WriteLn(JS.ToJSON);
          result := Agent.AContext.Connection.Socket.ReadLn();
        end;
      except on E: Exception do
        begin
          log.SaveLog('Error socker 1' + E.Message);
        end;
      end;
    end;
  end;   }
end;


procedure LoadLocalization();
var
  sr: TSearchRec;
  Files, URLS, StrList2 : TStringList;
  I, j, k: Integer;
  INI_LNG : TIniFile;

  URLList : TDictionary<string, Tlist<TLangKeyAndValue>>;
  LangKeyAndValueList : Tlist<TLangKeyAndValue>;
  LangKeyAndValue : TLangKeyAndValue;
begin
  Files   := TStringList.Create;
  URLS  := TStringList.Create;
  StrList2  := TStringList.Create;
  Files.Clear;
  if FindFirst(MyDir + '\www\localhost\lng\*.ini', faAnyFile, sr)=0  then  //ищем  файлы Word  в каталоге
  repeat
    Files.Add(sr.Name);
  until FindNext(sr)<>0;
  FindClose(sr);

//  Langs := TDictionary<string, TLangPage>.create;
  for I := 0 to Files.Count-1 do
  begin // Цикл по файлам
    INI_LNG := TIniFile.Create(MyDir + '\www\localhost\lng\' + Files[i]);
    INI_LNG.ReadSections(URLS);

    URLList := TDictionary<string, Tlist<TLangKeyAndValue>>.Create();
    for j := 0 to URLS.Count-1 do
    begin  // цикл по секциям


      INI_LNG.ReadSection(URLS[j], StrList2);
      LangKeyAndValueList := Tlist<TLangKeyAndValue>.create;
      for k := 0 to StrList2.Count-1 do
      begin // цикл по ключам и значениям в секции
        LangKeyAndValue[0] := StrList2[k];
        LangKeyAndValue[1] := INI_LNG.ReadString(URLS[j], StrList2[k], 'Control Panel');
        LangKeyAndValueList.Add(LangKeyAndValue);
      end;
      URLList.Add(URLS[j], LangKeyAndValueList);
    end;
    INI_LNG.Free;
    Localization1.Add(Files[i], URLList);
  end;

  Files.Free;
  URLS.Free;
  StrList2.Free;

end;

procedure TDataModule2.DataModuleCreate(Sender: TObject);
var
 test : TSQL;
begin
 // FS  := TFormatSettings.Create;
  FS  := FormatSettings;
  FS.DecimalSeparator := '.';
  FS.TimeSeparator    := ':';
  FS.LongDateFormat   := 'yyyy-mm-dd';
  FS.ShortDateFormat  := 'yyyy-mm-dd';
  FS.LongTimeFormat   := 'hh:nn:ss';
  FS.ShortTimeFormat  := 'hh:nn:ss';
  log := TLogsSaveClasses.Create();
  MyDir         := GetCurrentDir;
  CreateMIMEtypesTabel;
//  Localization  := TDictionary<string,string>.Create();
  //Localization  := TDictionary<string, TLangPage>.create;
  Localization1 := TDictionary<string, TDictionary<string, Tlist<TLangKeyAndValue>>>.Create();
  LoadLocalization;
  Event         := TEvent.create;
  HTTPini       := TConfigs.Create('HTTP.ini');
  allFTTPs      := TFTPS_AllConnects.Create;
  wwwpath := HTTPini.GetValue_OrSetDefoult('Server', 'path', GetCurrentDir+'\www\').AsString;
  enableSSL := HTTPini.GetValue_OrSetDefoult('SSL', 'Secure', 'False').AsBoolean;
  if enableSSL then
  begin
    IdServerIOHandlerSSLOpenSSL1.SSLOptions.CertFile := MyDir +'\key\'+ HTTPini.GetValue_OrSetDefoult('SSL', 'CertFile', '.cert').AsString;
    IdServerIOHandlerSSLOpenSSL1.SSLOptions.KeyFile  := MyDir +'\key\'+ HTTPini.GetValue_OrSetDefoult('SSL', 'KeyFile', '.key').AsString;
    if  FileExists(IdServerIOHandlerSSLOpenSSL1.SSLOptions.CertFile)
    and FileExists(IdServerIOHandlerSSLOpenSSL1.SSLOptions.KeyFile) then
    begin
      IdHTTPServer1.IOHandler := IdServerIOHandlerSSLOpenSSL1;
    end else
    begin
      log.SaveLog('Error not found CertFiles');
    end;
  end;



  IdHTTPServer1.DefaultPort := HTTPini.GetValue_OrSetDefoult('Server', 'port', '80').AsInteger;
  IdHTTPServer1.Active := True;


  log.SaveLog('HTTP is active. Port : ' + IdHTTPServer1.DefaultPort.ToString);

//  IdTCPServer1 := TIdTCPServer.Create();
  ini := TConfigs.Create('config.ini');
  SQL := TFireDAC.Create(TFireDAC.DataBaseType.Mysql,
  ini.GetValue_OrSetDefoult('Mysql', 'IP', '127.0.0.1').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'login', 'admin').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'pass', '12345').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'DB', 'backup').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'port', '3306').AsInteger,
  ini.GetValue_OrSetDefoult('Mysql', 'Pool_Maximum', '123').AsInteger);

  IdFTPServer1.DefaultPort      := ini.GetValue_OrSetDefoult('FTPS', 'Port',     '10023').AsInteger;
  IdFTPServer1.DefaultDataPort  := ini.GetValue_OrSetDefoult('FTPS', 'DataPort', '10024').AsInteger;
  IdFTPServer1.Active := True;

  passSalt := ini.GetValue_OrSetDefoult('System', 'salt', GenerateSalt).AsString;
//  ini.GetValue_OrSetDefoult('global', 'dbfileName', 'jobs').AsString,

  MySQLUnit.CreateTables;
  MySQL_Agent_SetOfflineALL();

  secretKey := ini.GetValue_OrSetDefoult('socket', 'key','').AsString;

  AllAgents := TAllAgents.Create;//создаем allSockets из socketUnit
  IdTCPServer1.DefaultPort := ini.GetValue_OrSetDefoult('socket', 'port', '80').AsInteger;
  IdTCPServer1.Active := True;

  jobsThread := TjobsThread.Create;

  repeat
  //    Event.WaitFor(INFINITE);
    Check_NewJob();
//    Event.ResetEvent;
    Sleep(5000);
  until (TjobsThread_dead);
  log.SaveLog('Error TDataModule2.DataModuleCreate Main thead dead');
//  IdTCPServer1
end;

procedure TDataModule2.IdFTPServer1UserAccount(ASender: TIdFTPServerContext;
  const AUsername, APassword, AAcount: string; var AAuthenticated: Boolean);
begin
  Sleep(0);
end;

procedure TDataModule2.IdFTPServer1UserLogin(ASender: TIdFTPServerContext;
  const AUsername, APassword: string; var AAuthenticated: Boolean);
begin
  FTPSUnit.IdFTPServer1UserLogin(ASender, AUsername, APassword, AAuthenticated);
end;

procedure TDataModule2.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  GetHTML(ARequestInfo, AResponseInfo);
end;

procedure TDataModule2.IdTCPServer1Connect(AContext: TIdContext);
var
  msg         : string;
  Agent       : TAgent;
  ID          : Integer;
  js          : TJSONObject;
begin
  try
    log.SaveLog('new connect ' + AContext.Connection.Socket.Binding.PeerIP);
    msg := AContext.Connection.Socket.ReadLn(#10, 5000, 1024);
    log.SaveLog('Agent nil <<== ' + msg);

  except on E: Exception do
    begin
      log.SaveLog('Socket error ' + E.Message);
    end;
  end;
  if msg <> '' then
  begin
    if Check_AgentLogin(msg, ID) = 0 then
    begin
      log.SaveLog('authorization successful AgentID ' + ID.ToString);
      js :=  TJSONObject.Create;
      try
        js.AddPair('action', 'login');
        if AllAgents.СheckAlreadyConnected(ID) = false then
        begin
          js.AddPair('result', TJSONNumber.Create(0));
          log.SaveLog('Agent ' + ID.ToString + ' ==>> ' + js.ToJSON);
          AContext.Connection.Socket.WriteLn(js.ToJSON);
          Agent    := AllAgents.AddNewSocket(ID, AContext);
        end else
        begin
          js.AddPair('result', TJSONNumber.Create(1000));
          js.AddPair('error', 'Error AlreadyConnected');
          Sleep(5000);
          log.SaveLog('Agent Already Connected Socket.Close');
          log.SaveLog('Agent ' + ID.ToString + ' ==>> ' +js.ToJSON);
          AContext.Connection.Socket.WriteLn(js.ToJSON);
          AContext.Connection.Socket.InputBuffer.Clear;
          AContext.Connection.Socket.Close;
        end;
      finally
        js.Free;
      end;
    end else
    begin
      log.SaveLog('authorization error Socket.Close');
      AContext.Connection.Socket.InputBuffer.Clear;
      AContext.Connection.Socket.Close;
    end;
  end else
  begin
    log.SaveLog('authorization error Socket.Close');
    AContext.Connection.Socket.InputBuffer.Clear;
    AContext.Connection.Socket.Close;
  end;
end;

procedure TDataModule2.IdTCPServer1Disconnect(AContext: TIdContext);
var
  Agent  : TAgent;
begin
  log.SaveLog(AContext.Connection.Socket.Binding.PeerIP + ' disconet');
  if AContext.Data <> nil then
  begin
    Agent := TAgent(AContext.Data);
    AContext.Data := nil;
    AllAgents.AgentDisconnect(Agent.Agent.agentID);
  end;
end;

procedure TDataModule2.IdTCPServer1Exception(AContext: TIdContext;
  AException: Exception);
begin
  log.SaveLog('TCPServer Exception ' + AException.Message);
  AException.Free;
end;

procedure TDataModule2.IdTCPServer1Execute(AContext: TIdContext);
var
  msg   : string;
  code, ID  : integer;
  Agent   : TAgent;
  boof    : TIdBytes;

  test    : Byte;
  HashMD5 : THashMD5;
begin
    sleep(5000);
//  msg := AContext.Connection.Socket.ReadLn();
//  log.SaveLog('!!!!!!!!!!!!!!!!!!!!!!!!!! ' + msg);
{  msg := '';
  try
 //   log.SaveLog(AContext.Connection.Socket.Binding.PeerIP);

    if AContext.Data <> nil then
    begin
      Agent := TAgent(AContext.Data);
      Agent.lastOnline := Now;
      msg := AContext.Connection.Socket.ReadLn(#10, 5000, 5120);
      if msg <> '' then
      if newMessage(msg, Agent) = 0 then
      begin
      end else
      begin
  //      AContext.Connection.Socket.Close;
        // послать ошибку.
      end;
    end else
    begin
      log.SaveLog('Socket error Data is nil');
      AContext.Connection.Socket.InputBuffer.Clear;
      AContext.Connection.Socket.Close;
    end;

  except on E: Exception do
    begin
      log.SaveLog('Error socker ' + E.Message);
      AContext.Connection.Socket.InputBuffer.Clear;
      AContext.Connection.Socket.Close;
    end;
  end;    }
end;

end.
