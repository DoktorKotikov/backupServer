unit mainUnit;

interface

uses
  System.SysUtils, System.Classes, IdBaseComponent, IdComponent, SocketUnit, HtmlUnit,
  IdCustomTCPServer, IdTCPServer, IdContext, jobsUnit, System.JSON, messageExecute, System.SyncObjs, System.Generics.Collections,
  myconfig.Logs, myconfig.ini, varsUnit, IdGlobal, System.Hash, FireDAC, MySQLUnit, jobsThreadUnit,
  IdCustomHTTPServer, IdHTTPServer, IdCookie

  ;


type
  TDataModule2 = class(TDataModule)
    IdTCPServer1: TIdTCPServer;
    IdHTTPServer1: TIdHTTPServer;
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

procedure TDataModule2.DataModuleCreate(Sender: TObject);
var
 test : TSQL;
begin
  MyDir   := GetCurrentDir;
  Jobs :=  TAJobs.Create;
  Event       := TEvent.create;
  HTTPini := TConfigs.Create('HTTP.ini');

  wwwpath := HTTPini.GetValue_OrSetDefoult('Server', 'path', GetCurrentDir+'\www\').AsString;
  IdHTTPServer1.DefaultPort := HTTPini.GetValue_OrSetDefoult('Server', 'port', '80').AsInteger;

  IdHTTPServer1.Active := True;

//  IdTCPServer1 := TIdTCPServer.Create();
  ini := TConfigs.Create('config.ini');
  log := TLogsSaveClasses.Create();
  SQL := TFireDAC.Create(TFireDAC.DataBaseType.Mysql,
  ini.GetValue_OrSetDefoult('Mysql', 'IP', '127.0.0.1').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'login', 'admin').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'pass', '12345').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'DB', 'backup').AsString,
  ini.GetValue_OrSetDefoult('Mysql', 'port', '3306').AsInteger,
  ini.GetValue_OrSetDefoult('Mysql', 'Pool_Maximum', '123').AsInteger);

//  ini.GetValue_OrSetDefoult('global', 'dbfileName', 'jobs').AsString,

  MySQLUnit.CreateTables;

  secretKey := ini.GetValue('socket', 'key').AsString;

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
