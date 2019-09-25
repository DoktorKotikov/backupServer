unit MySQLUnit;

interface

uses System.JSON, System.SysUtils, varsUnit, FireDAC, System.Generics.Collections, Data.DB, System.StrUtils, System.Hash, Web.HTTPApp;

procedure CreateTables() ;

function MySQL_JobSave(js : TJSONObject): Integer;

function MySQL_Agent_GetAgentsIDFromJobID(JobID : Integer; out AgentsId  : TArray<integer>): Boolean;
function MySQL_Agent_GetData(name : string; out pass : string; out TAGS : string; out AgentID : integer): boolean;
function MySQL_Agent_SetOfflineALL(): Integer;
function MySQL_Agent_SetOnline(AgentID : integer; lastOnline : TDateTime; Online : boolean): Integer;
function MySQL_Agent_CheckLogin(key, ip, name : string; out ID: integer): Integer;

function MySQL_GetJobsDate_ALL(): TAJob;
function MySQL_GetJob_HTML(jobID : integer; out tags : string; out name : string; out crone : string; out rules : string; out active : integer): integer;
function MySQL_GetAgentTags(agentId : integer): string;
function MySQL_GetTagsListFromJob_HTML(JobID : integer) : string;
function MySQL_GetTagsListHTML() : string;
function MySQL_CreateNextJob(JobId, AgentID : Integer; NextDate : TDateTime): Integer;
function MySQL_CloseJonb(ID : integer; JobResult : integer) : integer;
function MySQL_GetNewJob1(): Integer;
function Mysql_GetAgentsIdFromTags(tags : string): TArray<integer>;
function MySQL_UpdateJobDate(id : Integer; JobResult : string): Integer;

function MySQL_CheckLoginPass(Login, pass : string) : Boolean;
function MySQL_ADDHTTPSession(Login, RemoteIP, UserAgent : string): string;
function Mysql_GetANDCheckHTTPSession(AuthToken, RemoteIP, UserAgent : string): Boolean;

function MySQL_Agents_GetAllAgents(): TAAgentConf;
function MySQL_Agents_GetAllAgents_HTML(): string;

function MySQL_SendTo_getConfig(SendTo_ID : integer): string;


implementation

uses jobsThreadUnit;

function MySQL_JobSave(js : TJSONObject): Integer;
var
  query   : TSQL;
  jobe_id : integer;
  active  : Boolean;
  I       : Integer;
  tags_JS : TJSONArray;
begin
  query := nil;
  try
    if TryStrToInt(js.GetValue('jobe_id').Value, jobe_id) = true then
    begin
      query := SQL.Create_SQL;
    {  query.SQL.Text  := 'SELECT 1 FROM `jobs` WHERE `jobID` = ' + JobID.ToString;
      query.Active;
      if query.RecordCount = 1 then
      begin

      end else }
      begin
        try
      //    query.Transaction.StartTransaction;

          query.SQL.Text  := 'INSERT INTO `jobs` (`jobID`, `JobName`, `rules`, `Crone`, `active`)';
          query.SQL.Add('VALUES');
          query.SQL.Add('(:jobe_id, :job_name, :rules, :cron, :is_activ)');
          query.SQL.Add('on duplicate key update ');
          query.SQL.Add('`JobName` = :job_name,');
          query.SQL.Add('`rules` = :rules,');
          query.SQL.Add('`Crone` = :cron,');
          query.SQL.Add('`active` = :is_activ');


          query.Params.CreateParam(ftInteger, 'jobe_id',    ptInput);
          query.Params.CreateParam(ftString,  'job_name',  ptInput);
          query.Params.CreateParam(ftString,  'rules',    ptInput);
          query.Params.CreateParam(ftString,  'cron',    ptInput);
          query.Params.CreateParam(ftInteger, 'is_activ',   ptInput);

          query.ParamByName('jobe_id').AsInteger    := jobe_id;
          query.ParamByName('job_name').AsString   := js.GetValue('job-name').Value;
          query.ParamByName('rules').AsString     := js.GetValue('rules').Value;
          query.ParamByName('cron').AsString     := js.GetValue('cron').Value;
          if js.TryGetValue('is-activ', active) = True
            then query.ParamByName('is_activ').AsInteger   := 1
            else query.ParamByName('is_activ').AsInteger   := 0;

       //   log.SaveLog(query.SQL.Text);
          query.ExecSQL;

          query.ExecSQL('DELETE FROM `jobs.tags` WHERE `jobID` = ' + jobe_id.ToString);

       {   query.SQL.Text  := 'INSERT INTO `jobs.tags` (`jobID`, `tagID`) VALUES';
          js.TryGetValue('tags', tags_JS);
          log.SaveLog(js.ToString);
          for I := 0 to tags_JS.Count-1 do
          begin
            query.SQL.Add('(' +jobe_id.ToString +',' + tags_JS.Items[i].Value +')');
            if i <> tags_JS.Count then query.SQL.Add(',');
          end;
          query.ExecSQL;   }
    //      query.Transaction.Commit;

        except on E: Exception do
        begin
          log.SaveLog(E.Message);
     //     query.Transaction.Rollback;
        end;
        end;

      end;

    end;
  finally
    if query <> nil then query.Free;
  end;
end;

function CalcSessionKey(Login, UserAgent, sessionSalt : string): string;
begin
  Result := System.Hash.THashMD5.GetHashString(Login + sessionSalt);
  Result := Result + sessionSalt + UserAgent;
  Result := System.Hash.THashSHA2.GetHashString(Result+ passSalt, System.Hash.SHA512);
  Result := System.Hash.THashSHA2.GetHashString(Result+ sessionSalt, System.Hash.SHA512);
  Result := System.Hash.THashSHA2.GetHashString(Result+ sessionSalt, System.Hash.SHA512);
  Result := System.Hash.THashSHA2.GetHashString(Result+ passSalt+sessionSalt, System.Hash.SHA512);
  Result := System.Hash.THashSHA2.GetHashString(Result, System.Hash.SHA512);
end;

procedure CreateTables() ;
var
  query : TSQL;
begin
  query := nil;
  try
    query := SQL.Create_SQL;
    query.SQL.Text := 'CREATE TABLE IF NOT EXISTS `jobs` (';
    query.SQL.Add('`jobID` INT NOT NULL,');
    query.SQL.Add('  `Tags` VARCHAR(128) NULL,');
    query.SQL.Add('  `DirIN` VARCHAR(256) NULL,');
    query.SQL.Add('  `DirOUT` VARCHAR(256) NULL,');
    query.SQL.Add('  `Pattern` VARCHAR(64) NULL,');
    query.SQL.Add('  `Crone` VARCHAR(18) NULL,');
    query.SQL.Add('  `active` TINYINT NULL,');
    query.SQL.Add('  PRIMARY KEY (`jobID`))');
    query.SQL.Add('ENGINE = InnoDB');

    query.ExecSQL;

    query.SQL.Text := 'CREATE TABLE IF NOT EXISTS `agents` (';
    query.SQL.Add('`ID` INT NOT NULL,');
    query.SQL.Add('`NAME` VARCHAR(128) NULL,');
    query.SQL.Add('`TAGS` VARCHAR(256) NULL,');
    query.SQL.Add('`AUTH_TYPE` INT NULL,');
    query.SQL.Add('`IP` VARCHAR(16) NULL,');
    query.SQL.Add('`KEY` VARCHAR(64) NULL,');
    query.SQL.Add('`STATUS` INT NULL,');
    query.SQL.Add('PRIMARY KEY (`ID`))');
    query.ExecSQL;

    query.SQL.Text := 'CREATE TABLE IF NOT EXISTS `keys` (';
    query.SQL.Add('  `key` varchar(64) NOT NULL,');
    query.SQL.Add('  `tags` varchar(128) DEFAULT NULL, ');
    query.SQL.Add('  `status` int(11) DEFAULT NULL,');
    query.SQL.Add('  PRIMARY KEY (`key`)');
    query.SQL.Add(') ENGINE=InnoDB');
    query.ExecSQL;


  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_Agent_GetAgentsIDFromJobID(JobID : Integer; out AgentsId  : TArray<integer>): Boolean;
var
  query : TSQL;
  i : integer;
begin
  Result := false;
  query   := nil;
  try
    query := SQL.Create_SQL;
    query.SQL.Text := 'SELECT `agentID` FROM `agents.tags` WHERE `tagID` IN (SELECT `tagID` FROM `jobs.tags` WHERE `jobID` = '+JobID.ToString+')';
    query.Active := true;
    SetLength(AgentsId, query.RecordCount);
    Result := True;
    for I := 1 to query.RecordCount do
    begin
      query.RecNo   := i;
      AgentsId[i-1] := query.FieldByName('agentID').AsInteger;
    end;
  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_Agent_GetData(name : string; out pass : string; out TAGS : string; out AgentID : integer): boolean;
var
  query : TSQL;
begin
  Result := false;
  query   := nil;
  try
    query := SQL.Create_SQL;
    query.SQL.Text := 'SELECT * FROM agents WHERE `name` = "' + name + '"'; // переделать на препотготовленный запрос
    query.Active := true;
    if query.RecordCount = 1 then
    begin
      query.RecNo    := 1;
      pass    := query.FieldByName('key').AsString;
      TAGS    := query.FieldByName('TAGS').AsString;
      AgentID := query.FieldByName('ID').AsInteger;
      Result := true;
    end;

  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_Agent_SetOfflineALL(): Integer;
var
  query : TSQL;
begin
  query := nil;
  try
    query := SQL.Create_SQL;
    query.ExecSQL('UPDATE `agents` SET `ONLINE` = false');
  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_Agent_SetOnline(AgentID : integer; lastOnline : TDateTime; Online : boolean): Integer;
var
  query : TSQL;
begin
  query := nil;
  try
    query := SQL.Create_SQL;
    if Online
      then query.SQL.Text := 'UPDATE `agents` SET `ONLINE` = true, `LASTONLINE` = "'+DateTimeToStr(lastOnline, FS)+'"    WHERE `ID` =  ' + AgentID.ToString
      else query.SQL.Text := 'UPDATE `agents` SET `ONLINE` = false  WHERE `ID` =  ' + AgentID.ToString;

    query.ExecSQL;

  finally
    if query <> nil then query.Free;
  end;

end;


function MySQL_GetJob_HTML(jobID : integer; out tags : string; out name : string; out crone : string; out rules : string; out active : integer): integer;
var
  query   : TSQL;
begin
  query := nil;
  try
    tags := #13;
    query := SQL.Create_SQL;

    query.SQL.Text := 'SELECT * FROM `jobs` where `jobID` = ' + jobID.ToString;
    query.Active := true;
    if query.RecordCount = 1 then
    begin
      query.RecNo    := 1;
      tags    := tags +  '<span class="tag-item">'+Web.HTTPApp.HTMLEncode(query.FieldByName('TAGS').AsString)+'</span>' + #13;
      name    := Web.HTTPApp.HTMLEncode(query.FieldByName('JobName').AsString);
      crone   := Web.HTTPApp.HTMLEncode(query.FieldByName('crone').AsString);
      rules   := Web.HTTPApp.HTMLEncode(query.FieldByName('rules').AsString);
      active  := query.FieldByName('active').AsInteger;

    end;
  finally
    if query <> nil then query.Free;
  end;
end;


function MySQL_GetAgentTags(agentId : integer): string;
var
  query   : TSQL;
begin
  query := nil;
  try
    Result := #13;
    query := SQL.Create_SQL;

    query.SQL.Text := 'SELECT * FROM `agents` where `ID` = ' + agentId.ToString;
    query.Active := true;
    if query.RecordCount = 1 then
    begin
      query.RecNo    := 1;
      Result := Result +  '<span class="tag-item">'+query.FieldByName('TAGS').AsString+'</span>' + #13;
    end;
  finally
    if query <> nil then query.Free;
  end;
end;


function MySQL_GetTagsListFromJob_HTML(JobID : integer) : string;
var
  query     : TSQL;
  i         : integer;
  selected  : string;
begin
  query := nil;
  try
    Result := #13;
    query := SQL.Create_SQL;
    query.SQL.Text := 'SELECT `idTags`, `tagname`, ifnull(`jobID`, -1) as `active` FROM tags Left JOIN `jobs.tags` ON (`idTags` = tagID AND jobID = '+JobID.ToString +')';
    query.Active := true;
    for I := 1 to query.RecordCount do
    begin
      query.RecNo    := i;
      if query.FieldByName('active').AsInteger <> -1 then selected := 'selected' else selected := '';
      Result := Result +  '<option value="' + query.FieldByName('idTags').AsString +'"'+ selected +'>'+Web.HTTPApp.HTMLEncode(query.FieldByName('tagname').AsString)+'</option>' + #13;
    end;


  finally
    if query <> nil then query.Free;
  end;
end;


function MySQL_GetTagsListHTML() : string;
var
  query   : TSQL;
  i       : integer;
begin
  query := nil;
  try
    Result := #13;
    query := SQL.Create_SQL;
    query.SQL.Text := 'SELECT `tagname` FROM tags';
    query.Active := true;
    for I := 1 to query.RecordCount do
    begin
      query.RecNo    := i;
      Result := Result +  '<option value="'+i.ToString+'">'+Web.HTTPApp.HTMLEncode(query.FieldByName('tagname').AsString)+'</option>' + #13;
    end;


  finally
    if query <> nil then query.Free;
  end;
end;



function MySQL_Agent_CheckLogin(key, ip, name : string; out ID: integer): Integer;
var
  query : TSQL;
  TAGS  : string;
begin
  Result := 1;
  query := SQL.Create_SQL;
  query.SQL.Text := 'SELECT * FROM `agents` WHERE `STATUS` = 0 AND `AUTH_TYPE` = '+ AUTH_TYPE_AUTH_ByIP.ToString  +' AND `IP` = "'+ip+'"';
  query.Active := true;

  if query.RecordCount = 1 then
  begin
    query.RecNo    := 1;
    ID := query.FieldByName('ID').AsInteger;
    Result := 0;
  end else
  begin
    query.SQL.Text := 'SELECT * FROM `keys` WHERE `STATUS` = 0 AND `key` = "' +key +'"';
    query.Active := true;
    if query.RecordCount = 1 then
    begin
      query.RecNo    := 1;
      TAGS := query.FieldByName('TAGS').AsString;

      query.SQL.Text := 'INSERT INTO `agents`';
      query.SQL.Add('(`NAME`,`TAGS`,`AUTH_TYPE`,`IP`,`KEY`) VALUES');
      query.SQL.Add('("'+ name + '", "' + TAGS + '", ' + AUTH_TYPE_AUTH_Bykey.ToString + ', "' +ip+'","' + KEY +'")');
      query.SQL.Add('ON DUPLICATE KEY UPDATE `IP` = "' +ip+'"');
    //  log.SaveLog(query.SQL.Text);
      query.ExecSQL;
     // query.Free;
     // log.SaveLog(query.SQL.Text);
                                                      // `STATUS` = 0 AND
      query.SQL.Text := 'SELECT * FROM `agents` WHERE  `AUTH_TYPE` = '+ AUTH_TYPE_AUTH_Bykey.ToString  +' AND `name` = "'+name+'"';
      log.SaveLog(query.SQL.Text);
      query.Active := true;
      if query.RecordCount = 1 then
      begin
        query.RecNo    := 1;
        ID := query.FieldByName('ID').AsInteger;
      end;
      Result := 0;
    end;
  end;

  query.Free;
end;

function MySQL_GetJobsDate_ALL(): TAJob;
var
  query   : TSQL;
  i       : Integer;
begin
  query := nil;
  try
   { query := SQL.Create_SQL;
    query.SQL.Text  := 'SELECT * FROM `jobsDate` WHERE `Status` IN ("new")';
    query.Active    := True;
    SetLength(Result, query.RecordCount);
    for i := 1 to query.RecordCount do
    begin
      query.RecNo    := i;
      Result[i-1].AgentID                 := query.FieldByName('AgentID').AsInteger;
      Result[i-1].job_scheduler.ID        := query.FieldByName('ID').AsInteger;
      Result[i-1].job_scheduler.JobName   := query.FieldByName('ID').AsInteger;
      Result[i-1].job_scheduler.rules     := query.FieldByName('ID').AsInteger;
      Result[i-1].job_scheduler.crone     := query.FieldByName('ID').AsInteger;
      Result[i-1].job_scheduler.Tags      := query.FieldByName('ID').AsInteger;
      Result[i-1].job_scheduler.active    := query.FieldByName('ID').AsInteger;

    end;
             }
  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_GetJobsDate(jodId : integer): TDateTime;     {разобраться если больше одной джоны}
var
  query   : TSQL;
  i       : Integer;
begin
  query := nil;
  try
    query := SQL.Create_SQL;
    query.SQL.Text  := 'SELECT * FROM `jobsDate` WHERE `Status` IN ("new") AND `jobID` = ' + jodId.ToString;
    query.Active    := True;
    if query.RecordCount = 1 then
    begin
      query.RecNo    := 1;
      Result := query.FieldByName('Date').AsDateTime;
    end else
    begin
      if query.RecordCount = 0 then
      begin
        Result := 0;
      end else
      begin
        log.SaveLog('Error found more 1 next jobs');
        query.SQL.Text  := 'DELETE FROM `jobsDate` WHERE `Status` IN ("new") AND `jobID` = ' + jodId.ToString;
        query.ExecSQL;
        Result := 0;
      end;

    end;
  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_CreateNextJob(JobId, AgentID : Integer; NextDate : TDateTime): Integer;
var
  query   : TSQL;
  AFormatSettings: TFormatSettings;
begin
  result       := -1;
  AFormatSettings := FormatSettings;
  AFormatSettings.DecimalSeparator := '.';
  AFormatSettings.TimeSeparator    := ':';
  AFormatSettings.LongDateFormat   := 'yyyy-mm-dd';
  AFormatSettings.ShortDateFormat  := 'yyyy-mm-dd';
  AFormatSettings.LongTimeFormat   := 'hh:nn:ss.zzz';
  AFormatSettings.ShortTimeFormat  := 'hh:nn:ss.zzz';

  query := nil;
  try
    query := SQL.Create_SQL;
    query.SQL.Text  := '  INSERT INTO `jobsDate` (`jobID`, `AgentID`,  `Date`, `Status`, `result`) VALUES ';
    query.SQL.Add('('+JobId.ToString+',' +AgentID.ToString+ ', "' +FormatDateTime('yyyy-mm-dd hh:mm', NextDate, AFormatSettings)+'", "new", 0)');
    query.ExecSQL;

    query.SQL.Text := 'SELECT last_insert_id() as id';
    query.Open;
    query.RecNo  := 1;
    result       :=  query.FieldByName('id').AsInteger;
  finally
    if query <> nil then query.Free;
  end;

end;

function MySQL_CloseJonb(ID : integer; JobResult : integer) : integer;
var
  query   : TSQL;
begin
  query := nil;
  try
    query := SQL.Create_SQL;
    query.ExecSQL('UPDATE `jobsDate` SET `Status` = "close" `result` = '+JobResult.ToString+' WHERE `ID` = ' + ID.ToString)
  finally
    if query <> nil then query.Free;
  end;
end;

function MySQL_GetNewJob1(): Integer;
var
  query   : TSQL;
  i       : Integer;
  job     : Tjob_scheduler;
begin
  query := SQL.Create_SQL;
  query.SQL.Text := 'SELECT * FROM `jobs` WHERE `active` = 0';
  query.Active := True;
  if query.RecordCount > 0 then
  for I := 1 to query.RecordCount do
  begin
    query.RecNo     := i;
    job.ID          := query.FieldByName('jobID').AsInteger;
    job.JobName     := query.FieldByName('JobName').AsString;

    job.rules       := query.FieldByName('rules').AsString;
    job.sendTo      := query.FieldByName('sendTo').AsInteger;
    job.crone       := query.FieldByName('crone').AsString;
    job.Tags        := query.FieldByName('Tags').AsString;
    job.active      := query.FieldByName('active').AsInteger;
  //  job.NextJobTime := MySQL_GetJobsDate(job.ID);
    jobsThread.AddJob(job);
  //  sender as TjobsThread.AddJob(job);
  end;


  query.Free;
end;


function Mysql_GetAgentsIdFromTags(tags : string): TArray<integer>;
var
  query   : TSQL;
  i       : Integer;

begin
  Result := TArray<integer>.Create();
  tags := tags.Replace(' ', '","');
  query := SQL.Create_SQL;
  query.SQL.Text := 'SELECT `ID` FROM `agents` WHERE `TAGS` in ("'+tags+'")';
  query.Active := True;
  SetLength(Result, query.RecordCount);
  if query.RecordCount > 0 then
  for I := 1 to query.RecordCount do
  begin
    query.RecNo    := i;
    Result[i-1] := query.FieldByName('ID').AsInteger;
  end;

  query.Free;
end;

function MySQL_UpdateJobDate(id : Integer; JobResult : string): Integer; // Переделать, добавилось AgentID
var
  query   : TSQL;
begin
  query := SQL.Create_SQL;
  query.SQL.Text := 'UPDATE `jobsDate` SET `Status` = "done", `result` = "true' {+JobResult} +'" WHERE `Status` = "new" AND `jobID` = ' + id.ToString;
  query.ExecSQL;

  query.Free;
end;

function MySQL_CheckLoginPass(Login, pass : string) : Boolean;
var
  query   : TSQL;
begin
  Result  := false;
  query   := SQL.Create_SQL;
  query.Params.Clear;

  query.SQL.Text := 'SELECT * FROM `users` WHERE `enabled` = 1 AND `LOGIN` = :login AND `pass` = SHA1(:pass)';
  query.Params.CreateParam(ftString, 'login', ptInput);
  query.Params.CreateParam(ftString, 'pass', ptInput);

  query.ParamByName('login').AsString := Login;
  query.ParamByName('pass').AsString  := pass;


  query.Open;

  if query.RecordCount = 1 then
  begin
    query.RecNo := 1;
    if query.FieldByName('pass').AsString = System.Hash.THashSHA1.GetHashString(pass) then
    begin
      Result := True;
    end;
  end;
  query.Free;
end;

function MySQL_ADDHTTPSession(Login, RemoteIP, UserAgent : string): string;
var
  query   : TSQL;
  sessionSalt : string;
begin
  query := SQL.Create_SQL;
  query.Params.Clear;
  query.SQL.Text := 'INSERT INTO `session` (`login`,`RemoteIP`,`UserAgent`, `sessionKey`, `sessionSalt`) VALUES (:Login, :RemoteIP, :UserAgent, :sessionKey, :sessionSalt)';

  query.Params.CreateParam(ftString, 'login', ptInput);
  query.Params.CreateParam(ftString, 'RemoteIP', ptInput);
  query.Params.CreateParam(ftString, 'UserAgent', ptInput);
  query.Params.CreateParam(ftString, 'sessionKey', ptInput);
  query.Params.CreateParam(ftString, 'sessionSalt', ptInput);


  sessionSalt := System.Hash.THashSHA2.GetHashString(GenerateSalt, System.Hash.SHA512);
  Result := CalcSessionKey(Login, UserAgent, sessionSalt);

  query.ParamByName('login').AsString         := Login;
  query.ParamByName('RemoteIP').AsString      := RemoteIP;
  query.ParamByName('UserAgent').AsString     := UserAgent;
  query.ParamByName('sessionKey').AsString    := Result;
  query.ParamByName('sessionSalt').AsString   := sessionSalt;
  query.ExecSQL;

  query.Free;

end;


function Mysql_GetANDCheckHTTPSession(AuthToken, RemoteIP, UserAgent : string): Boolean;
var
  query   : TSQL;
begin
  Result := False;
  try

    query := SQL.Create_SQL;
    query.Params.Clear;
    query.SQL.Text := 'SELECT `id`,`login`, `RemoteIP`,`UserAgent`,`sessionKey`, `sessionSalt`, `dead`,`CreateTime`FROM `session` WHERE `sessionKey` = :AuthToken AND `dead` = 0';
    query.Params.CreateParam(ftString, 'AuthToken', ptInput);
    query.ParamByName('AuthToken').AsString  := AuthToken;
    query.Open;

    if query.RecordCount = 1 then
    begin
      query.RecNo := 1;
      if query.FieldByName('sessionKey').AsString = AuthToken then
      if query.FieldByName('dead').AsInteger = 0 then
      begin
        if CalcSessionKey(query.FieldByName('Login').AsString, UserAgent , query.FieldByName('sessionSalt').AsString) = AuthToken then
        begin
          Result := True;

        end;
      end;
    end;

  finally
    query.Free;
  end;
end;

function MySQL_Agents_GetAllAgents(): TAAgentConf;
var
  query   : TSQL;
  i       : integer;
begin
  try
    query := SQL.Create_SQL;
    query.Open('SELECT * FROM `agents`');
    SetLength(Result, query.RecordCount);
    for I := 1 to query.RecordCount do
    begin
      query.RecNo := i;
      Result[i-1].agentID       := query.FieldByName('ID').AsInteger;
      Result[i-1].Name          := query.FieldByName('Name').AsString;
      Result[i-1].Auth_type     := query.FieldByName('Auth_type').AsInteger;
      Result[i-1].Key           := query.FieldByName('Key').AsString;
      Result[i-1].status        := query.FieldByName('status').AsInteger;
      Result[i-1].LastOnline    := query.FieldByName('LastOnline').AsDateTime;
    end;

  finally
    query.Free;
  end;
end;

function MySQL_Agents_GetAllAgents_HTML(): string;
var
  query   : TSQL;
  i       : integer;
begin
  try
    query := SQL.Create_SQL;
    query.Open('SELECT * FROM `agents`');
    Result  := '';
    for I := 1 to query.RecordCount do
    begin
      query.RecNo := i;
      Result  := Result +  #13+ '<tr>'+#13 + '<td>';

      if query.FieldByName('ONLINE').AsInteger <> 0
        then Result  := Result + '<span class="status-icon status-icon-online"></span>'
        else Result  := Result + '<span class="status-icon status-icon-offline"></span>';


      Result  := Result + ' <a href="/agent.html?number=' + Web.HTTPApp.HTMLEncode(query.FieldByName('ID').AsString)+'">'+Web.HTTPApp.HTMLEncode(query.FieldByName('NAME').AsString)+'</a>'
                      //  + '<td>' + query.FieldByName('NAME').AsString + '</td>'
                        + '<p class="tag">' + Web.HTTPApp.HTMLEncode(query.FieldByName('TAGS').AsString) + '</p></td>'
                     //   + '<td>' + query.FieldByName('STATUS').AsString + '</td>'
//                        + '<td>' + query.FieldByName('TAGS').AsString + '</td>'
      ;



      Result := Result + #13+'</tr>'+#10#13;
    end;

  finally
    query.Free;
  end;
end;




function MySQL_SendTo_getConfig(SendTo_ID : integer): string;
var
  query   : TSQL;
begin
  query := SQL.Create_SQL;
  query.SQL.Text := 'SELECT * FROM `sendTo` WHERE `idSend` = ' + SendTo_ID.ToString;
  query.Active := True;
  if query.RecordCount = 1 then
  begin
    query.RecNo     := 1;
    Result          := query.FieldByName('sendConfig').AsString;
  end;
  query.Free;
end;


end.


