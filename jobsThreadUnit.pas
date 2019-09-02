unit jobsThreadUnit;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, varsUnit, MySQLUnit, System.RegularExpressions, DateUtils, System.JSON
  , SocketUnit, System.Generics.Collections, System.SyncObjs;

type

  TjobsThread = class(TThread)
  private
    jobs  : array of Tjobrec;
    Quere : tqueue<Tjobrec>;
    CS    : TCriticalSection;
    { Private declarations }
  protected
    procedure Execute; override;
  public
    constructor Create();

    procedure AddJob(job : Tjobrec);
    function  GetJob_toDo(out jobrec : Tjobrec) : boolean;
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

  if Length(values) = 5 then
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
  JS_Jobs       : TJsonObject;
  JS_JobsArray  : TJSONArray;

  needSleep     : Boolean;
begin
  MySQL_GetNewJob();
  AgentsId  := TArray<integer>.create();
  repeat
    needSleep := True;
    GetLocalTime(SystemTime);
    for I := 0 to Length(jobs)-1 do
    begin
      JS_Jobs := TJsonObject.Create;
      JS_JobsArray  := TJSONArray.create;
      if jobs[i].NextJobTime = 0 then
      begin
//
        jobs[i].NextJobTime := SystemTimeToDateTime(FoundNextDate(SystemTime, jobs[i].crone));
        MySQL_CreateNextJob(jobs[i].ID, jobs[i].NextJobTime);
      end else
      begin
        if jobs[i].NextJobTime < now then
        begin
          try
            CS.Enter;
            Quere.Enqueue(jobs[i]);
          finally
            CS.Leave;
          end;

          jobs[i].NextJobTime := SystemTimeToDateTime(FoundNextDate(SystemTime, jobs[i].crone));
          MySQL_CreateNextJob(jobs[i].ID, jobs[i].NextJobTime);
        end;
      end;
    end;
    if needSleep then Sleep(6000);
  until (false);
  { Place thread code here }
end;


constructor TjobsThread.Create();
begin
  CS    := TCriticalSection.Create;
  Quere := tqueue<Tjobrec>.Create;
  inherited Create();
end;

procedure TjobsThread.AddJob(job : Tjobrec);
begin
  SetLength(jobs, Length(jobs)+1);
  jobs[Length(jobs)-1] := job;
end;

function  TjobsThread.GetJob_toDo(out jobrec : Tjobrec) : boolean;
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
