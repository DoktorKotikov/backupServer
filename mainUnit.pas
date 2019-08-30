unit mainUnit;

interface

uses
  System.SysUtils, System.Classes, IdBaseComponent, IdComponent, SocketUnit, HtmlUnit,
  IdCustomTCPServer, IdTCPServer, IdContext, System.JSON, messageExecute, System.SyncObjs, System.Generics.Collections,
  myconfig.Logs, myconfig.ini, varsUnit, IdGlobal, System.Hash, FireDAC, MySQLUnit, jobsThreadUnit,
  IdCustomHTTPServer, IdHTTPServer, IdCookie, IdServerIOHandler, IdSSL,
  IdSSLOpenSSL, inifiles

  ;


type
  TDataModule2 = class(TDataModule)
    IdTCPServer1: TIdTCPServer;
    IdHTTPServer1: TIdHTTPServer;
    IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL;
    procedure DataModuleCreate(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);

    function RunJob(agent_Id : integer; jobrec : Tjobrec) : integer;
    procedure Check_NewJob();
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
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

function TDataModule2.RunJob(agent_Id : integer; jobrec : Tjobrec) : integer;
var
  SocketConf : TSocketConf;
  i : Integer;
  JS : TJSONObject;
  JSArr : TJSONArray;
begin
  with IdTCPServer1.Contexts.LockList do
  begin
    for I := 0 to count-1 do
    begin
      log.SaveLog(TIdContext(Items[i]).Connection.Socket.Binding.PeerIP);
      SocketConf := TSocketConf(TIdContext(Items[i]).Data);
      if SocketConf.agent_Id = agent_Id then
      if SocketConf.ConnectType = 1 then
      begin
        JS := TJSONObject.Create;
        JSArr := TJSONObject.ParseJSONValue(jobrec.rules) as TJSONArray;

        JS.AddPair('sendto', 'server');
        JS.AddPair('action', 'newJob');

        JS.AddPair('job',  JSArr);

        TIdContext(Items[i]).Connection.Socket.WriteLn(JS.ToJSON);
      //  log.SaveLog( TIdContext(Items[i]).Connection.Socket.ReadLn());
      end;
    end;
  end;
//  TIdContext(IdTCPServer1.Contexts.LockList.Items[0]).Data;
//  SocketConf := TSocketConf(@AContext.Data);

  IdTCPServer1.Contexts.UnlockList;
//  TIdContext(IdTCPServer1.Contexts.LockList.Items[0]).Connection.Socket.WriteLn('Hello', enUTF8);
end;


procedure TDataModule2.Check_NewJob();
var
  AgentsId : TArray<integer>;
  i : Integer;
  SocketConf : TSocketConf;
  jobrec : Tjobrec;
  JS_JobResult  : TJSONObject;
  JS_JobsArray  : TJSONArray;
begin
  if jobsThread.GetJob_toDo(jobrec) = True then
  begin

    AgentsId := Mysql_GetAgentsIdFromTags(jobrec.Tags);
    JS_JobResult  := TJsonObject.create;
    JS_JobsArray  := TJSONArray.Create;
    for i := 0 to Length(AgentsId) -1 do
    begin

      JS_JobResult.AddPair('AgentID',   TJSONNumber.Create(AgentsId[i]));
      JS_JobResult.AddPair('JobResult', TJSONNumber.Create( RunJob(AgentsId[i], jobrec) ));
      JS_JobsArray.Add(JS_JobResult);
    end;
    MySQL_UpdateJobDate(jobrec.ID, JS_JobsArray.ToJSON);


  end;
 { if allSockets.FoundConnect(AgentID, SocketConf) = False then
  begin
    log.SaveLog('');
  end else
  begin
    SocketConf
  end;    }
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
  log := TLogsSaveClasses.Create();
  MyDir         := GetCurrentDir;
//  Localization  := TDictionary<string,string>.Create();
  //Localization  := TDictionary<string, TLangPage>.create;
  Localization1 := TDictionary<string, TDictionary<string, Tlist<TLangKeyAndValue>>>.Create();
  LoadLocalization;
  Event         := TEvent.create;
  HTTPini       := TConfigs.Create('HTTP.ini');

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

  passSalt := ini.GetValue_OrSetDefoult('System', 'salt', GenerateSalt).AsString;
//  ini.GetValue_OrSetDefoult('global', 'dbfileName', 'jobs').AsString,

  MySQLUnit.CreateTables;
  MySQL_Agent_SetOfflineALL();

  secretKey := ini.GetValue_OrSetDefoult('socket', 'key','').AsString;

  allSockets := TSocketsAll.Create;//создаем allSockets из socketUnit
  IdTCPServer1.DefaultPort := ini.GetValue_OrSetDefoult('socket', 'port', '80').AsInteger;
  IdTCPServer1.Active := True;

  jobsThread := TjobsThread.Create;

  repeat
  //    Event.WaitFor(INFINITE);
    Check_NewJob();
//    Event.ResetEvent;
    Sleep(5000);
  until (false);
//  IdTCPServer1
end;

procedure TDataModule2.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  GetHTML(ARequestInfo, AResponseInfo);
end;

procedure TDataModule2.IdTCPServer1Disconnect(AContext: TIdContext);
var
  SocketConf : TSocketConf;
begin
  SocketConf := TSocketConf(@AContext.Data);

  //allSockets

  SocketConf.fileStrim.Free;
 // SocketConf.fileStrim.Destroy;
end;

procedure TDataModule2.IdTCPServer1Execute(AContext: TIdContext);
var
  msg   : string;
  code  : integer;
  js    : TJSONObject;
  SocketConf : TSocketConf;
  boof    : TIdBytes;

  test    : Byte;
  HashMD5 : THashMD5;
begin
  SetLength(boof, 1);
  log.SaveLog(AContext.Connection.Socket.Binding.PeerPort.ToString);
  if allSockets.GetSocketConf(AContext.GetHashCode, SocketConf) = false then
  begin
  //  msg := AContext.Connection.Socket.ReadLn();
    SocketConf    := allSockets.AddNewSocket(AContext.GetHashCode, AContext.Connection.Socket.Binding.PeerIP);
    AContext.Data := SocketConf;
  end;


  case SocketConf.ConnectType of
    0 :
    begin
      msg := AContext.Connection.Socket.ReadLn();
      if newMessage(msg, SocketConf) = 0 then
      begin
        js :=  TJSONObject.Create;
        js.AddPair('action', 'login');
        js.AddPair('result', TJSONNumber.Create(0));

        MySQL_Agent_SetOnline(SocketConf.agent_Id, true);

        AContext.Connection.Socket.WriteLn(js.ToJSON);
        js.Free;
      end else
      begin
     //   AContext.Connection.Socket.Close;
        // послать ошибку авторизации.
      end;
    end;

    1 :
    begin
      msg := AContext.Connection.Socket.ReadLn();
      newMessage(msg, SocketConf);
     // if 'action' = 'sendfile' then SocketConf.ConnectType := 3;
     // js := getNewJob();

    //  msg := js.ToJSON;
    //  msg := '{}';
     // AContext.Connection.Socket.WriteLn(msg);

    end;

    3 :
    begin
      test := AContext.Connection.Socket.ReadByte;//  ReadBytes(boof, SizeOf(Byte));
      SocketConf.fileStrim.Write(test, SizeOf(test));
      if SocketConf.fileStrim.Size = SocketConf.fileSize then
      begin
        SocketConf.fileStrim.Free;
        HashMD5 := THashMD5.Create;
        js :=  TJSONObject.Create;
        js.AddPair('action', 'getRequestOfFileSending');
        if SocketConf.MD5 = HashMD5.GetHashStringFromFile(SocketConf.filedir + '\' + SocketConf.fileName) then
        begin
          js.AddPair('request', 'true');
          AContext.Connection.Socket.WriteLn(js.ToJSON);
        end else
        begin
          js.AddPair('request', 'false');
          AContext.Connection.Socket.WriteLn(js.ToJSON);
        end;
        js.Free;
      end;
    end;

    10 :
    begin
      AContext.Connection.Socket.Close;
    end;

  end;



  //  AContext
    //AContext.Data
end;

end.
