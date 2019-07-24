unit jobsUnit;

interface

uses System.Generics.Collections, System.classes, System.SysUtils,

    varsUnit,
    System.JSON;

type
  Tjobrec = record
    //jobsDate_ID : Integer;
    ID    : integer;
    rules : string;
    crone : string;
    Tags  : string;
    NextJobTime : TDateTime;

//    constructor Create();
//    destructor Free();
  end;

  TAJobs = class
  private
    jobsList : TList<Tjobrec>;
    function SafeJobsInFile() : integer;
  public
    function ADDJob(job : Tjobrec) : integer;
    constructor Create();
    destructor Free();
  end;

var
  Jobs :  TAJobs;

function getNewJob1() : TJSONObject;

implementation

function TAJobs.ADDJob(job : Tjobrec) : integer;
begin
  job.ID := jobsList.Count;
  jobsList.Add(job);
  Self.SafeJobsInFile;
end;

function TAJobs.SafeJobsInFile() : integer;
var
  filjobs : TFileStream;
  i : Integer;
  Job1 : Tjobrec;
begin
  filjobs := TFileStream.Create(mydir+'\jobs.db', fmOpenReadWrite OR fmCreate);
  for I := 0 to jobsList.Count-1 do
  begin
    Job1 := jobsList.Items[i];
    filjobs.Write(Job1, SizeOf(Tjobrec));
  end;

  filjobs.Free;
end;

constructor TAJobs.Create();
var
  filjobs : TFileStream;
  Job1 : Tjobrec;
begin
  jobsList := TList<Tjobrec>.Create();
  filjobs := TFileStream.Create(mydir+'\jobs.db', fmOpenReadWrite OR fmCreate);
  filjobs.Position := 0;

  while filjobs.Position > filjobs.Size do
  begin
    filjobs.Read(Job1, SizeOf(Tjobrec));
    jobsList.Add(Job1);
  end;

 // SetLength(jobs, 0);
  filjobs.Free;
end;

destructor TAJobs.Free();
begin

end;


function getNewJob1() : TJSONObject;
var
  JSArray : TJSONArray;
  job     : TJSONObject;
  i       : integer;
begin
  Result := TJSONObject.Create;
  JSArray := TJSONArray.Create;

  for I := 0 to 0 do
  begin
    job     := TJSONObject.Create;
    job.AddPair('dir', 'C:\test');
    job.AddPair('Pattern', '(\d{4})(\d{2}).*');
    job.AddPair('dirout', 'C:\test\offline\($1)\($2)\');
    JSArray.AddElement(job);
  end;

  Result.AddPair('sendto', 'server');
  Result.AddPair('action', 'newJob');
  Result.AddPair('job', JSArray);

end;


////////////////////////////////////////////////////////////////////////////////
{
constructor Tjobrec.Create();
begin
 //
end;

destructor Tjobrec.Free();
begin
 //
end;
 }
end.
