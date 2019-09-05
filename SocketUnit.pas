unit SocketUnit;

interface

uses System.SyncObjs, System.Generics.Collections, System.Classes, System.SysUtils;

type
  TSocketConf = class
  private

  public
    agent_Id    : Integer;
    client_IP   : string;
    fHach       : integer;
    ConnectType : integer;
    filedir     : string;
    fileName    : string;
    fileSize    : Int64;
    MD5         : string;
    fileStrim   : TFileStream;
    constructor Create(Hach : integer; ip : string);
  end;


  TSocketsAll = class
  private
    CS : TCriticalSection;
    Sockets : TDictionary<integer, TSocketConf>;
  public
    constructor Create();
    function AddNewSocket(Hach : integer; ip : string) : TSocketConf;
    function GetSocketConf(Hach : integer; out SocketConf : TSocketConf) : boolean;
    function FoundConnect(agentID : Integer; out SocketConf : TSocketConf) : boolean;
    function getActiveSockets(): string;
  end;

var
  allSockets : TSocketsAll;

implementation





constructor TSocketConf.Create(Hach : integer; ip : string);
begin
  fHach       := Hach;
  client_IP   := ip;
  ConnectType := 0;
end;

//////////////////////////////////////////////////
constructor TSocketsAll.Create();
begin
  CS      := TCriticalSection.Create;
  Sockets := TDictionary<integer, TSocketConf>.Create();
end;

function TSocketsAll.AddNewSocket(Hach : integer; ip : string) : TSocketConf;
begin
  try
    CS.Enter;
  //  Sockets.Add(AgentId, result);
  finally
    CS.Leave;
  end;
end;

function TSocketsAll.GetSocketConf(Hach : integer; out SocketConf : TSocketConf) : boolean;
begin
  try
    CS.Enter;
    result := Sockets.TryGetValue(Hach, SocketConf);
  finally
    CS.Leave;
  end;
end;

function TSocketsAll.FoundConnect(agentID : Integer; out SocketConf : TSocketConf) : boolean;
var
  SocketConf1 : TSocketConf;
begin
  try
    CS.Enter;
      Result := True;
      for SocketConf1 in Sockets.Values do
      begin
        if agentID = SocketConf.agent_Id then
        begin
          SocketConf := SocketConf1;
          Exit;
        end;
      end;

      Result := false;

  finally
    CS.Leave;
  end;
end;

function TSocketsAll.getActiveSockets(): string;
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
end;

end.
