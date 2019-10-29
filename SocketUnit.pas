unit SocketUnit;

interface

uses System.SyncObjs, System.Generics.Collections, System.Classes, System.SysUtils, Web.HTTPApp, system.JSON,
        IdContext, varsUnit, MySQLUnit;

type
  TAgent = class(TThread)
  private
  protected
    CS_Agent        : TCriticalSection;
    Quere           : tqueue<Tjob>;
    fContext        : TIdContext;
    fLastActivTime  : TDateTime;
    fWStatus        : Boolean;
    procedure UpdateAContext(AContext_ : TIdContext);
    function  JobToJS(job : Tjob): string;
    function  JobResult(msg : string; job : Tjob): integer;
  public
    agent_Id    : Integer;
    Agent       : TAgentConf;
    lastOnline  : TDateTime;
    Event       : TEvent;
    fAgent_Tags  : TArray<TTagIDName>;

    Property AContext    : TIdContext read fContext write UpdateAContext;

    constructor Create(agent_Id_ : integer; Agent_ : TAgentConf; Agent_Tags  : TArray<TTagIDName>);
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
    function Agent_AddorUpdate(agentID : integer; AgentName : string; Agent_Tags : TArray<integer>) : Boolean;

    function GetAllAgents_HTML(): string;
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
    if AContext_ = nil then log.SaveLog('UpdateAContext new NIL');

    if AContext_ <> nil then
    begin
      fContext.Data  := Self;
    end else
    begin
      log.SaveLog('AContext = nil');
    end;
    Event.SetEvent;
  finally
    CS_Agent.Leave;
  end;
end;


constructor TAgent.Create(agent_Id_ : integer; Agent_ : TAgentConf; Agent_Tags  : TArray<TTagIDName>);
begin
  inherited Create(false);

  fWStatus    := False;
  CS_Agent    := TCriticalSection.Create;
  Quere       := tqueue<Tjob>.Create;
  Event       := TEvent.Create;
  AContext    := nil;
  agent_Id    := agent_Id_;
  Agent       := Agent_;
  fLastActivTime  := 0;
  fAgent_Tags := Agent_Tags;

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
      MySQL_CloseJonb(job.job_schedulerID, resltJob);
    end else
    begin
      MySQL_CloseJonb(job.job_schedulerID, 10001);
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
    log.SaveLog('Agent '+ Self.agent_Id.ToString + ' Execute new Event ');
    if fContext <> nil then
    begin
      while Quere.Count > 0 do
      begin
        if IsConnect then
        begin
          try
            CS_Agent.Enter;
            s := JobToJS(Quere.Peek);
            log.SaveLog('Agent '+ Self.agent_Id.ToString + ' ==>> ' +s);
            Self.fContext.Connection.Socket.WriteLn(s);
            s := Self.fContext.Connection.Socket.ReadLn({#10, 5000, 1024});
            log.SaveLog('Agent '+ Self.agent_Id.ToString + ' <<== ' +s);
  //          s := Self.fContext.Connection.Socket.ReadLn(#10, 5000, 1024);
  //          log.SaveLog('Agent '+ Self.agent_Id.ToString + ' <<== ' +s);

            JobResult(s, Quere.Extract);
          finally
            CS_Agent.Leave;
          end;
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
    CS_Agent.Enter;
    try
      if AContext <> nil then
     // if assigned(AContext) then
      begin
        log.SaveLog('Agent '+ Self.agent_Id.ToString + ' ==>> ' + JS_ping);
        AContext.Connection.Socket.WriteLn(JS_ping);
        s := AContext.Connection.Socket.ReadLn(#10, 5000).Trim;
        log.SaveLog('Agent '+ Self.agent_Id.ToString + ' <<== ' +s);
        if s <> '' then
        begin
          Result := true;
        end else
        begin
          log.SaveLog('Agent Connection.Socket.Close');
          AContext.Connection.Socket.Close;
          AContext := nil;
          Result := False;
        end;
      end else
      begin
        Result := False;
      end;

    except on E: Exception do
      begin
        log.SaveLog('Agent '+ Self.agent_Id.ToString + ' TAgent.IsConnect Exception : ' + E.Message);
        Result    := False;
        AContext  := nil;
      end;
    end;
  finally
    CS_Agent.Leave;
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
  SocketConf : TAgent;
  Jobs       : TAJob;
  j: Integer;
//  Agent_ : TAgentConf;
  Agent_Tags  : TArray<TTagIDName>;
begin
  CS        := TCriticalSection.Create;
  fAllAgents := TDictionary<integer, TAgent>.Create();
  Agents    := MySQL_Agents_GetAllAgents();
  MySQL_GetJobsDate_ALL();
  for I := 0 to Length(Agents)-1 do
  begin
    Agent_Tags  := MySQL_GetAgentTagsFromID(Agents[i].agentID);
    SocketConf  := TAgent.Create(Agents[i].agentID, Agents[i], Agent_Tags);
    fAllAgents.Add(Agents[i].agentID, SocketConf);
    Jobs := MySQL_Get_JobsDate_GetNewJobfromAgent(Agents[i].agentID);
    for j := 0 to Length(Jobs)-1 do
    begin
      SocketConf.AddNewTask(Jobs[j]);
    end;


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
    //  Agent.fContext := nil;
      Agent.UpdateAContext(nil);
      MySQL_Agent_SetOnline(agentID, Now, false);
  finally
    CS.Leave;
  end;
end;

function TAllAgents.GetAllAgents_HTML(): string;
var
  Agent : TAgent;
  i : Integer;
  tags : string;
begin
  try
    CS.Enter;
    Result  := '';
    for Agent in fAllAgents.Values do
    begin
      Result  := Result +  #13+ '<tr>'+#13 + '<td>';

      if Agent.fContext <> nil
        then Result  := Result + '<span class="status-icon status-icon-online"></span>'
        else Result  := Result + '<span class="status-icon status-icon-offline"></span>';

      tags := '';
      for I := 0 to length(Agent.fAgent_Tags) -1 do
      begin
        tags := tags + '#'+Agent.fAgent_Tags[i].Name +' ';
      end;
      Result  := Result + ' <a href="/agent.html?agent_id=' + Web.HTTPApp.HTMLEncode(Agent.agent_Id.ToString)+'">'+Web.HTTPApp.HTMLEncode(Agent.Agent.Name)+'</a>'
                        + '<p class="tag">' + Web.HTTPApp.HTMLEncode(tags) + '</p></td>'
      ;



      Result := Result + #13+'</tr>'+#10#13;
    end;

  finally
    CS.Leave;
  end;
end;

function TAllAgents.Agent_AddorUpdate(agentID : integer; AgentName : string; Agent_Tags : TArray<integer>) : Boolean;
var
  Agent : TAgent;
  AgentConf : TAgentConf;
begin
  try
    CS.Enter;
    if agentID = -1 then
    begin
      agentID               := MySQL_Agent_Add(agentID, AgentName, Agent_Tags);
      AgentConf.agentID     := agentID;
      AgentConf.Name        := AgentName;
      AgentConf.LastOnline  := 0;
      Agent := TAgent.Create(agentID, AgentConf, MySQL_GetAgentTagsFromID(agentID));
      fAllAgents.Add(agentID, Agent);
    end else
    begin
      if fAllAgents.TryGetValue(agentID, Agent) = True then
      begin
        Agent.Agent.Name      := AgentName;
        Agent.fAgent_Tags     := MySQL_GetTagsList_FromTagIDList(Agent_Tags);
        MySQL_Agent_Update(agentID, AgentName, Agent_Tags);

      end else
      begin
        // Error;
      end;
    end;




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
