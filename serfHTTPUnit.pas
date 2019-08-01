unit serfHTTPUnit;

interface

uses System.Classes, System.sysutils, System.RegularExpressions,
    varsUnit, IdCustomHTTPServer, jobsUnit, MySQLUnit, IdCookie, myconfig.Logs;

//function refreshIndex();

implementation
{
function refreshIndex();
var
  list    : tStrings;
  MyDir   : string;
  i       : Integer;

begin
  MyDir    := GetCurrentDir + 'www\localhost\index.html';
  try
    list.LoadFromFile(mydir);
    for i := 0 to list.Count - 1  do
      begin
       if list.Strings[i] = 'FSDWEF#$WR#W_TASCk' then
        begin
          list.Strings[i] := '77777#####' ;
          Break;
        end;
      end;
      list.SaveToFile(mydir);
  finally
    list.Free;
  end;
  }
end.
