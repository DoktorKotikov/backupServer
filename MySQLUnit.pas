unit MySQLUnit;

interface

uses System.SysUtils, varsUnit, FireDAC, System.Generics.Collections, jobsUnit;

procedure CreateTables() ;
function MySQL_CheckLogin(key, ip, name : string; out ID: integer): Integer;
function MySQL_CreateNextJob(JobId : Integer; NextDate : TDateTime): Integer;
function MySQL_GetNewJob(): Integer;
function Mysql_GetAgentsIdFromTags(tags : string): TArray<integer>;
function MySQL_UpdateJobDate(id : Integer; JobResult : string): Integer;

function MySQL_CheckLoginPass(Login, pass : string) : Boolean;
function MySQL_GetHTTPSession(AuthToken : string): Boolean;

implementation

uses jobsThreadUnit;

procedure CreateTables() ;
var
  query : TSQL;
begin
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


  query.Free;
end;

function MySQL_CheckLogin(key, ip, name : string; out ID: integer): Integer;
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
      log.SaveLog(query.SQL.Text);
      query.ExecSQL;
     // query.Free;
      log.SaveLog(query.SQL.Text);
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

function MySQL_GetJobsDate(jodId : integer): TDateTime;
var
  query   : TSQL;
  i       : Integer;
begin
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
  query.Free;
end;

function MySQL_CreateNextJob(JobId : Integer; NextDate : TDateTime): Integer;
var
  query   : TSQL;
  AFormatSettings: TFormatSettings;
begin
  AFormatSettings := FormatSettings;
  AFormatSettings.DecimalSeparator := '.';
  AFormatSettings.TimeSeparator    := ':';
  AFormatSettings.LongDateFormat   := 'yyyy-mm-dd';
  AFormatSettings.ShortDateFormat  := 'yyyy-mm-dd';
  AFormatSettings.LongTimeFormat   := 'hh:nn:ss.zzz';
  AFormatSettings.ShortTimeFormat  := 'hh:nn:ss.zzz';

  query := SQL.Create_SQL;
  query.SQL.Text  := '  INSERT INTO `jobsDate` (`jobID`,  `Date`, `Status`, `result`) VALUES ';
  query.SQL.Add('('+JobId.ToString+', "'+FormatDateTime('yyyy-mm-dd hh:mm', NextDate, AFormatSettings)+'", "new", 0)');
  query.ExecSQL;

 { query.SQL.Text := 'SELECT last_insert_id()  as `id`;';
  query.Active  := True;
  query.RecNo   := 1;
  jobsDate_ID   := query.FieldByName('id').AsInteger;
        }
  query.Free;
end;

function MySQL_GetNewJob(): Integer;
var
  query   : TSQL;
  i       : Integer;
  job     : Tjobrec;
begin
  query := SQL.Create_SQL;
  query.SQL.Text := 'SELECT * FROM `jobs` WHERE `active` = 0';
  query.Active := True;
  if query.RecordCount > 0 then
  for I := 1 to query.RecordCount do
  begin
    query.RecNo     := i;
    job.ID          := query.FieldByName('jobID').AsInteger;
    job.rules       := query.FieldByName('rules').AsString;
    job.crone       := query.FieldByName('crone').AsString;
    job.Tags        := query.FieldByName('Tags').AsString;

    job.NextJobTime := MySQL_GetJobsDate(job.ID);
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

function MySQL_UpdateJobDate(id : Integer; JobResult : string): Integer;
var
  query   : TSQL;
begin
  query := SQL.Create_SQL;
  query.SQL.Text := 'UPDATE `jobsDate` SET `Status` = "done", `result` = "true' {+JobResult} +'" WHERE `Status` = "new" AND `jobID` = ' + id.ToString;
  query.ExecSQL;

  query.Free;
end;

function MySQL_CheckLoginPass(Login, pass : string) : Boolean;
begin
  Result := True;
end;

function MySQL_GetHTTPSession(AuthToken : string): Boolean;
begin

end;

end.


