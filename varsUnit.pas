unit varsUnit;

interface

uses System.SysUtils, myconfig.ini, myconfig.Logs, FireDAC, System.SyncObjs, System.Generics.Collections;

const
  AUTH_TYPE_AUTH_ByIP = 0;
  AUTH_TYPE_AUTH_Bykey = 1;

   {
type
  AUTH_TYPE =
    (
      AUTH_ByIP = 0,
      AUTH_ByKey = 1
    );    }



//    dirClient, dirout, Pattern : string;
//    sendto : integer;



var
  MyDir   : string; // GetCurrentDir
  HTTPini : TConfigs;
  ini : TConfigs;
  log : TLogsSaveClasses;
  secretKey : string;
  SQL : TFireDAC;

  Event       : TEvent;
  wwwpath     : string;
  wwwpathSeparator  : Char = '\';
  passSalt    : string;

function GenerateSalt(): string;
implementation


function GenerateSalt(): string;
const
  randstr = '1234567890qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM<>?;:][{}()-+*&^%$#@!';
var
  i, maxi : Integer;
begin
  Randomize;

  Result  := '';
  maxi    := Random(32);
  for I := 0 to 64 + maxi do
  begin
    Result := Result + randstr[Random(randstr.Length-2)+1];
  end;

end;

end.
