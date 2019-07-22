unit varsUnit;

interface

uses myconfig.ini, myconfig.Logs, FireDAC, System.SyncObjs, System.Generics.Collections;

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

type
  Tjobrec = record
    //jobsDate_ID : Integer;
    ID    : integer;
    rules : string;
    crone : string;
    Tags  : string;
    NextJobTime : TDateTime;

//    dirClient, dirout, Pattern : string;
//    sendto : integer;

  end;


var
  HTTPini : TConfigs;
  ini : TConfigs;
  log : TLogsSaveClasses;
  secretKey : string;
  SQL : TFireDAC;

  Event       : TEvent;
  wwwpath     : string;

implementation



end.
