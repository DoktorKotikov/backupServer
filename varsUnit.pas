unit varsUnit;

interface

uses System.SysUtils, myconfig.ini, myconfig.Logs, FireDAC, System.SyncObjs, System.Generics.Collections;


type
  TAgentConf = record
    agentID     : integer;
    Name        : string;
    Auth_type   : integer;
    Key         : string;
    status      : integer;
    LastOnline  : TDateTime;
  end;
  TAAgentConf = array of TAgentConf;

  Tjob_scheduler = record
    ID      : integer;
    JobName : string;
    rules   : string;
    crone   : string;
    Tags    : string;
    active  : Integer;
    NextJobTime : TDateTime;
  end;

  TJob = record
    job_scheduler : Tjob_scheduler;
    job_schedulerID : integer;
    AgentID : integer;
    result  : boolean;
  end;

  TAJob = array of TJob;

const
  AUTH_TYPE_AUTH_ByIP = 0;
  AUTH_TYPE_AUTH_Bykey = 1;

//  ErrorCodes
  Error_Socket_IncorrectLoginPas  = 1001;
  Error_Socket_badJson            = 1002;



   {
type
  AUTH_TYPE =
    (
      AUTH_ByIP = 0,
      AUTH_ByKey = 1
    );    }



//    dirClient, dirout, Pattern : string;
//    sendto : integer;


type
  TLangKeyAndValue = array [0 .. 1] of string;
//  TLangPage = Tlist<TLangKeyAndValue>;



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

  FS : TFormatSettings;

  enableSSL     : Boolean;
//  Localization  : TDictionary<string, TLangPage>;


  Localization1 : TDictionary<string, TDictionary<string, Tlist<TLangKeyAndValue>>>;
  //Localization : TDictionary<string,string>;
  TjobsThread_dead : Boolean = False;
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
