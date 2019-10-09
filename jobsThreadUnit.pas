unit jobsThreadUnit;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, varsUnit, MySQLUnit, System.RegularExpressions, DateUtils, System.JSON
  , SocketUnit, System.Generics.Collections, System.SyncObjs;

type

  TjobsThread = class(TThread)
  private
    jobs  : array of Tjob_scheduler;
    Quere : tqueue<Tjob>;
    CS    : TCriticalSection;
    { Private declarations }
  protected
    procedure Execute; override;
  public
    constructor Create();

    procedure AddJob(job : Tjob_scheduler);
    function  GetJob_toDo(out jobrec : Tjob) : boolean;
    function  getAllJobs_HTML(): string;

  end;

var
  jobsThread : TjobsThread;

implementation


function Equal(format : string; value: Word) : Boolean;
var
  Exp, Exp2  : TRegEx;
  i,j,k, fmt : integer;
  res : TMatch;
begin


  Result := false;
  Exp  := TRegEx.Create('(\d)-(\d{1,2})');
  Exp2 := TRegEx.Create('\*\/(\d{1,2})');

  if format = '*' then
    Result := true
  else if Exp.IsMatch(format) then
  begin
    res := Exp.Match(format);

    i := StrToInt(res.Groups.Item[1].Value);
    j := StrToInt(res.Groups.Item[2].Value);
    if (i <= value) and (value <= j) then Result := true;
  end
  else if Exp2.IsMatch(format) then
  begin
    res := Exp2.Match(format);
    k := StrToInt(res.Groups.Item[1].Value);
    if (k > 0) and (value mod k = 0) then Result := true;
  end
  else if TryStrToInt(format, fmt) then
  begin
    if fmt = value then Result := true;
  end;
end;

function Crone(SystemTime: TSystemTime; value : string) : Boolean;
var
  values : TArray<string>;
begin

  Result := False;

  values := value.Split([' ']);

  if Length(values) = 5 then
  begin
    if Equal(values[0], SystemTime.wMinute) and
       Equal(values[1], SystemTime.wHour) and
       Equal(values[2], SystemTime.wDay) and
       Equal(values[3], SystemTime.wMonth) and
       Equal(values[4], SystemTime.wDayOfWeek) then
    Result := true;
  end;
end;

function FoundNextDate(TimeStart: TSystemTime; value : string): TSystemTime;
var
  values : TArray<string>;
begin
//  DateTimeToSystemTime(TimeStart, Result);
  Result := TimeStart;
  values := value.Split([' ']);

  if Length(values) = 6 then
  begin
    DateTimeToSystemTime(IncMinute(SystemTimeToDateTime(Result)), Result);

    while (Equal(values[3], Result.wMonth) = false) and (Equal(values[4], Result.wDayOfWeek) = False) do
    begin
      DateTimeToSystemTime(IncMonth(SystemTimeToDateTime(Result)), Result);
      Result.wHour    := 0;
      Result.wMinute  := 0;
      Result.wDay     := 1;
    end;

    while (Equal(values[2], Result.wDay) = false) and (Equal(values[4], Result.wDayOfWeek) = False) do
    begin
      DateTimeToSystemTime(IncDay(SystemTimeToDateTime(Result)), Result);
      Result.wHour    := 0;
      Result.wMinute  := 0;
    end;

    while Equal(values[1], Result.wHour) = false do
    begin
      DateTimeToSystemTime(IncHour(SystemTimeToDateTime(Result)), Result);
      Result.wMinute := 0;
    end;

    while Equal(values[0], Result.wMinute) = false do
    begin
      DateTimeToSystemTime(IncMinute(SystemTimeToDateTime(Result)), Result);
    end;

  end;


end;



procedure TjobsThread.Execute;
var
  SystemTime : TSystemTime;
  i, j  : Integer;
  AgentsId  : TArray<integer>;

  JS_JobResult  : TJsonObject;
  needSleep     : Boolean;
  Job : Tjob;
begin
  try
    MySQL_GetNewJob1();
    AgentsId  := TArray<integer>.create();
    repeat
      needSleep := True;
      GetLocalTime(SystemTime);
      for I := 0 to Length(jobs)-1 do
      begin


        if jobs[i].NextJobTime < now then
        begin
          if jobs[i].NextJobTime <> 0 then
          begin

            if MySQL_Agent_GetAgentsIDFromJobID(jobs[i].ID, AgentsId) = True then
            begin
              jobs[i].NextJobTime := SystemTimeToDateTime(FoundNextDate(SystemTime, jobs[i].crone));
              for j := 0 to Length(AgentsId)-1 do
              begin
                Job.job_schedulerID := MySQL_CreateNextJob(jobs[i].ID, AgentsId[j], jobs[i].NextJobTime);
                try
                  CS.Enter;
                    Job.job_scheduler := jobs[i];
                    Job.AgentID       := AgentsId[j];
                    Job.result        := 0;
                   // Quere.Enqueue(Job);
                    AllAgents.AddNewTask(Job);
                    Log.SaveLog('New Job ADD in Quere');
                finally
                  CS.Leave;
                end;
              end;


            end;
          end;

          jobs[i].NextJobTime := SystemTimeToDateTime(FoundNextDate(SystemTime, jobs[i].crone));
        end;
      end;
      if needSleep then Sleep(6000);
    until (false);
    { Place thread code here }
  except on E: Exception do
    begin
      TjobsThread_dead := True;
      log.SaveLog('Error TjobsThread dead ' + E.Message);
    end;
  end;
  log.SaveLog('Error TjobsThread dead 1');
end;


constructor TjobsThread.Create();
begin
  CS    := TCriticalSection.Create;
  Quere := tqueue<Tjob>.Create;
//  inherited Create();
  inherited Create(false);
end;

procedure TjobsThread.AddJob(job : Tjob_scheduler);
begin
  SetLength(jobs, Length(jobs)+1);
  jobs[Length(jobs)-1] := job;
end;

function  TjobsThread.GetJob_toDo(out jobrec : Tjob) : boolean;
begin
  Result := true;
  try
    CS.Enter;
    if Quere.Count > 0
      then jobrec := Quere.Dequeue
      else Result := false;

  finally
    CS.Leave;
  end;
end;


function TjobsThread.getAllJobs_HTML(): string;
var
  i : integer;
  suite: string;
begin
  try
    CS.Enter;
    Result := '';
    suite := '/jobs.html' ;
    for I := 0 to Length(jobs)-1 do
    begin
      Result := Result +  '<tr>';
      Result := Result +  '<td><a href="'+suite+'?jobnumber='+jobs[i].ID.ToString+'">' + jobs[i].ID.ToString + '</a></td><td>' +jobs[i].Tags+ '</td><td>' + jobs[i].JobName + '</td><td>' + jobs[i].rules + '</td><td>' +jobs[i].crone+'</td><td>'+DateTimeToStr(jobs[i].NextJobTime)+ '</td>';
      Result := Result +  '</tr>';
    end;



  finally
    CS.Leave;
  end;
end;

end.
