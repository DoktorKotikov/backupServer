unit jobsUnit;

interface

uses System.JSON;

function getNewJob() : TJSONObject;

implementation

function getNewJob() : TJSONObject;
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

end.
