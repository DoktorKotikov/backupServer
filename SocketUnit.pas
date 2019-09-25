unit SocketUnit;

interface

uses System.SyncObjs, System.Generics.Collections, System.Classes, System.SysUtils, system.JSON,
        IdContext, varsUnit, MySQLUnit;

type

  TAgent = class(TThread)
  private
  protected
    CS_Agent    : TCriticalSection;
    Quere       : tqueue<Tjob>;
    fContext    : TIdContext;
    procedure UpdateAContext(AContext_ : TIdContext);
    function  JobToJS(job : Tjob): string;
    function  JobResult(msg : string; job : Tjob): integer;
  public
    agent_Id    : Integer;
    Agent       : TAgentConf;
    lastOnline  : TDateTime;
    Event       : TEvent;

    Property AContext    : TIdContext read fContext write UpdateAContext;

    constructor Create(agent_Id_ : integer; Agent_ : TAgentConf);
    procedure Execute; override;
    function  IsConnect : Boolean;
    function AddNewTask(Job : TJob): integer;
  end;


  TAllAgents = class(TThread)
  private
    CS : TCriticalSection;
    fAllAgents : TDictionary<integer, TAgent>;
  public
    constructor Create();
    function ÑheckAlreadyConnected(agentID : integer): boolean;
    function AddNewSocket(agentID : integer; AContext : TIdContext) : TAgent;
    function GetSocketConf(agentID : integer; out AgentConf : TAgent) : boolean;
    function AgentDisconnect(agentID : integer): Integer;
  //  function AddJob(job : Tjob) : boolean;
    //    function FoundConnect(agentID : Integer; out SocketConf : TSocketConf) : boolean;
//    function getActiveSockets(): string;
    function AddNewTask(Job : TJob): integer;
    procedure Execute; override;
  end;

var
  allAgents : TAllAgents;

implementation



procedure TAllAgents.Execute;
var
  Agent : TAgent;
begin
  repeat
    Sleep(60000);
    try
      CS.Enter;
      for Agent in Self.fAllAgents.Values do
      begin
        Agent.IsConnect;
      end;
    finally
      CS.Leave;
    end;


  until (Terminated);
end;

procedure TAgent.UpdateAContext(AContext_ : TIdContext);
begin
  try
    CS_Agent.Enter;
    fContext := AContext_;
    if AContext_ <> nil then
    begin
      fContext.Data  := Self;
    end;
    Event.SetEvent;
  finally
    CS_Agent.Leave;
  end;
end;


constructor TAgent.Create(agent_Id_ : integer; Agent_ : TAgentConf);
begin
  CS_Agent    := TCriticalSection.Create;
  Quere       := tqueue<Tjob>.Create;
  Event       := TEvent.Create;
  AContext    := nil;
  agent_Id    := agent_Id_;
  Agent       := Agent_;
  inherited Create(false);
 // lastOnline  := Now;
end;

function  TAgent.JobToJS(job : Tjob): string;
var
  s     : string;
  JS, JSSendTo    : TJSONObject;
  JSArr : TJSONArray;
begin
  JS := TJSONObject.Create;
  JSArr := TJSONObject.ParseJSONValue(Job.job_scheduler.rules) as TJSONArray;

//  JS.AddPair('sendto', 'server');
  JS.AddPair('action', 'newJob');
  JSSendTo := TJSONObject.ParseJSONValue(MySQL_SendTo_getConfig(Job.job_scheduler.sendTo)) as TJSONObject;
  JS.AddPair('sendTo', JSSendTo);
  JS.AddPair('job',  JSArr);

  Result := JS.ToJSON;
  JS.Free;
end;

function  TAgent.JobResult(msg : string; job : Tjob): integer;
var
  JS  : TJSONObject;
  resltJob  : integer;
begin
  JS := TJSONObject.ParseJSONValue(msg) as TJSONObject;
  if JS <> nil then
  begin
    if JS.TryGetValue('result',  resltJob) then
    begin
      MySQL_CloseJonb(job.job_scheduler.ID, resltJob);
    end;
  end;
end;


procedure TAgent.Execute;
var
  s   : string;
  job : Tjob;
begin
//  JS := TJSONObject.Create;
  repeat
    Event.WaitFor(INFINITE);
    Event.ResetEvent;
    if IsConnect then
    begin
      if fContext <> nil then
      begin
        try
          CS_Agent.Enter;

          Self.fContext.Connection.Socket.WriteLn(JobToJS(Quere.Peek));
          s := Self.fContext.Connection.Socket.ReadLn();
          JobResult(s, Quere.Extract);
        finally
          CS_Agent.Leave;
        end;
      end;
    end;
  until (Terminated);
end;

function  TAgent.IsConnect : Boolean;
const
  JS_ping = '{"action":"ping"}';
var
  s : string;
begin
  Result := False;
  try
    if AContext <> nil then
    begin
      AContext.Connection.Socket.WriteLn(JS_ping);
      s := AContext.Connection.Socket.ReadLn(#13, 5000);
      if s <> '' then Result := true else
      begin
        AContext.Connection.Socket.Close;
        AContext := nil;
      end;
    end else
    begin
      Result := False;
    end;

  except on E: Exception do
    begin
      Result    := False;
      AContext  := nil;
    end;
  end;
end;

function  TAgent.AddNewTask(Job : TJob): integer;
begin
  try
    CS_Agent.Enter;
      Quere.Enqueue(Job);
      Self.Event.SetEvent;
  finally
    CS_Agent.Leave;
  end;
end;


//////////////////////////////////////////////////
constructor TAllAgents.Create();
var
  Agents : TAAgentConf;
  i : Integer;
  SocketConf :  TAgent;
//  Agent_ : TAgentConf;
begin
  CS        := TCriticalSection.Create;
  fAllAgents := TDictionary<integer, TAgent>.Create();
  Agents    := MySQL_Agents_GetAllAgents();
  MySQL_GetJobsDate_ALL();
  for I := 0 to Length(Agents)-1 do
  begin
    SocketConf := TAgent.Create(Agents[i].agentID, Agents[i]);
    fAllAgents.Add(Agents[i].agentID, SocketConf);
  end;
  inherited Create(false);
end;

function TAllAgents.ÑheckAlreadyConnected(agentID : integer): boolean;
var
  Agent : TAgent;
  s     : string;
begin
  try
    CS.Enter;
//    if Agent := AllAgents.ExtractPair(agentID), Agent) then
    Agent := fAllAgents.Items[agentID];
    begin
      if Agent.AContext <> nil then
      begin
        try
          Result := Agent.IsConnect;
        except on E: Exception do
          begin
            Agent.AContext := nil;
            Result := False;
          end;
        end;
      end else Result := False;
    end;

 //   Result := AllAgents.ContainsKey(agentID);
  finally
    CS.Leave;
  end;

end;

function TAllAgents.AddNewSocket(agentID : integer; AContext : TIdContext) : TAgent;
begin
  try
    CS.Enter;
    if fAllAgents.TryGetValue(agentID, result) = True then
    begin
      result.AContext         := AContext;
    //  result.Agent.LastOnline := Now;
      MySQL_Agent_SetOnline(agentID, result.Agent.LastOnline, true);
    end;
  finally
    CS.Leave;
  end;
end;

function TAllAgents.GetSocketConf(agentID : integer; out AgentConf : TAgent) : boolean;
begin
  try
    CS.Enter;
    result := fAllAgents.TryGetValue(agentID, AgentConf);
  finally
    CS.Leave;
  end;
end;

function TAllAgents.AgentDisconnect(agentID : integer): Integer;
var
  Agent : TAgent;
begin
  try
    CS.Enter;
      Agent := fAllAgents.Items[agentID];
      Agent.fContext := nil;
      Agent.UpdateAContext(nil);
      MySQL_Agent_SetOnline(agentID, Now, false);
  finally
    CS.Leave;
  end;
end;


function TAllAgents.AddNewTask(Job : TJob): integer;
var
  Agent : TAgent;
begin
  Agent := fAllAgents.Items[Job.AgentID];
  Agent.AddNewTask(Job);
end;


end.
