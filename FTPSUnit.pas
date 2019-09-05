unit FTPSUnit;

interface

uses IdContext, IdFTPServer, System.SyncObjs, System.Generics.Collections, System.Classes, System.SysUtils, MySQLUnit, varsUnit;

type
  TFTPClient = record
    Conect  : TIdFTPServerContext;
    AgentID : integer;

  end;

  TFTPS_AllConnects = class
  private
    CS : TCriticalSection;
    Sockets : TDictionary<integer, TFTPClient>;
  public
    constructor Create();
    function AddNewSocket(AgentId : integer; ASender: TIdFTPServerContext) : boolean;
    function GetSocketConf(AgentId : integer; out SocketConf : TFTPClient) : boolean;
 //   function getActiveSockets(): string;
  end;


procedure IdFTPServer1Connect(AContext: TIdContext);
procedure IdFTPServer1UserLogin(ASender: TIdFTPServerContext; const AUsername, APassword: string; var AAuthenticated: Boolean);

procedure SendData();

var
  allFTTPs   : TFTPS_AllConnects;

implementation


procedure IdFTPServer1Connect(AContext: TIdContext);
begin
 // Glob_AContext := AContext;

end;

procedure IdFTPServer1UserLogin(ASender: TIdFTPServerContext;
  const AUsername, APassword: string; var AAuthenticated: Boolean);
var
  Pass, tags  : string;
  AgentID     : Integer;
begin
  AAuthenticated := false;
  if MySQL_Agent_GetData(AUsername, Pass, tags, AgentID) = true then
  begin
    if Pass = APassword  then
    begin
      AAuthenticated := allFTTPs.AddNewSocket(AgentID, ASender);
      Log.SaveLog('Connetc new client AgentID = ' + AgentID.ToString);
    end;
  end;
end;

procedure SendData();
begin
 // Glob_AContext.Connection.Socket.WriteLn('{}');
end;



constructor TFTPS_AllConnects.Create();
begin
  CS      := TCriticalSection.Create;
  Sockets := TDictionary<integer, TFTPClient>.Create();
end;

function TFTPS_AllConnects.AddNewSocket(AgentId : integer; ASender: TIdFTPServerContext) : boolean;
var
  data : TFTPClient;
begin
  try
    Result := true;
    CS.Enter;
    data.Conect   := ASender;
    data.AgentID  := AgentId;
   // ASender
 //   ASender.Connection.Socket.WriteLn('200');

    if Sockets.ContainsKey(AgentID) = false
      then Sockets.Add(AgentID, data) // тут надо чекнуть не сдох ли старый конект
      else Result := true;
  finally
    CS.Leave;
  end;
end;

function TFTPS_AllConnects.GetSocketConf(AgentId : integer; out SocketConf : TFTPClient) : boolean;
begin
  try
    CS.Enter;
    result := Sockets.TryGetValue(AgentId, SocketConf);
  finally
    CS.Leave;
  end;
end;

         {

function TFTPS_AllConnects.getActiveSockets(): string;
var
  SocketConf1 : TSocketConf;
begin
  try
    CS.Enter;
    Result := '';
      for SocketConf1 in Sockets.Values do
      begin
      Result := Result +  '<tr>';
      Result := Result +  '<td>' + SocketConf1.client_IP + '</td><td>' +inttostr(SocketConf1.ConnectType)+'</td>';
      Result := Result +  '</tr>';
    end;
  finally
    CS.Leave;
  end;
end;      }





end.
