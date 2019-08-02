unit HtmlUnit;

interface

uses System.Classes, System.sysutils, System.RegularExpressions, System.Generics.Collections,
    varsUnit, IdCustomHTTPServer, jobsThreadUnit, MySQLUnit, IdCookie, myconfig.Logs, IdSSL, SocketUnit; //, serfHTTPUnit

function GetHTML(ARequestInfo: TIdHTTPRequestInfo; {Param, URL, Host : string; }var AResponseInfo: TIdHTTPResponseInfo): string;

implementation


function Localization_HTML(URL, html : string): string;
var
  i : integer;
  UrlsList :  TDictionary<string, Tlist<TLangKeyAndValue>>;
  KeyAndValue : Tlist<TLangKeyAndValue>;
begin
  Result := html;
  Delete(URL, 1, 1);

  if Localization1.TryGetValue('ENG.ini', UrlsList) = true then
  if UrlsList.TryGetValue(URL, KeyAndValue) = true then
  for I := 0 to KeyAndValue.Count-1 do
  begin
    Result := StringReplace(Result, '['+KeyAndValue.Items[i][0]+']',  KeyAndValue.Items[i][1], [rfReplaceAll]);
  end;
end;

function GenContType(filename : string) : string;
begin
  filename := filename.Substring(filename.IndexOf('.')+1, 10);
  if (filename = 'htm') or (filename = 'html') then Result := 'text/html; charset=UTF-8' else
  if filename = 'ico' then Result := 'image/xicon' else
  if filename = 'mp4' then Result := 'video/mp4' else
  if filename = 'css' then Result := 'text/css; charset=UTF-8' else




end;


function CheckAccessPage(RequestPage : string): boolean;
var
  i : integer;
begin
  Result := false;
  if Pos('/assets/', RequestPage) = 1 then Result := true;
  if RequestPage = '/favicon.ico'   then Result := true;



end;

function authClient(ARequestInfo :TIdHTTPRequestInfo; var AResponseInfo: TIdHTTPResponseInfo;
                                      var RequestPage   : string; var Host: string): Boolean;
var
  ClientCookie  : TIdCookie;
  cook          : TIdCookie;
  Login, pass   : string;
begin
  Result := False;
  if CheckAccessPage(RequestPage) = false then
    begin
      ClientCookie := ARequestInfo.Cookies.Cookie['AuthToken', ''];
      if ClientCookie = nil then
      begin
        if RequestPage <> '/auth.html' then
        begin
          AResponseInfo.Redirect('/auth.html');
          RequestPage :=  '/auth.html';
        end else
        begin
          Login := ARequestInfo.Params.Values['par1'];
          pass  := ARequestInfo.Params.Values['par2'];
          if (Login <> '') AND (pass <> '') then
          begin
            if MySQL_CheckLoginPass(Login, pass) = true  then
            begin
              cook := AResponseInfo.Cookies.Add;
              cook.CookieName := 'AuthToken';
              cook.Value      := MySQL_ADDHTTPSession(Login, ARequestInfo.RemoteIP, ARequestInfo.UserAgent);
              cook.Expires    := Now() + 10;
              cook.Domain     := Host;
              cook.Secure     := enableSSL;


              RequestPage := wwwpathSeparator + 'index.html';
              AResponseInfo.Redirect('/index.html');
              log.SaveLog('MySql verification successful');


            end else
            begin
              log.SaveLog('Error: Failed check MySQL');
            end;
          end else
          begin
            log.SaveLog('Error: login or password field is empty');
          end;
        end;
      end else
      begin
        if ClientCookie.IsExpired then
        begin

        end;
        if Mysql_GetANDCheckHTTPSession(ClientCookie.Value, ARequestInfo.RemoteIP, ARequestInfo.UserAgent) = True then
        begin
          if (RequestPage = '/') OR (RequestPage = '/auth.html') then
          begin
            RequestPage := wwwpathSeparator + 'index.html';
            AResponseInfo.Redirect('/index.html');
          end else
          begin
            RequestPage   := RequestPage.Replace('/', wwwpathSeparator, [rfReplaceAll]);
          end;
          Result := True;
        end else
        begin
          log.SaveLog('Cookie check failed');

          AResponseInfo.Cookies.Clear;// Delete(ClientCookie.ID);
          RequestPage := '/auth.html';
        end;
      end;
    end;
end;


function refreshIndex(filename : string): string;
var
  list    : TStringList;
begin

  list     := TStringList.Create;
  try
    list.LoadFromFile(filename);
    Result:=list.text;
  finally
    list.Free;
  end;

  Result := StringReplace(Result, '[BackupServer_TASCkList]', jobsThread.getAllJobs_HTML, [rfReplaceAll]);
  Result := StringReplace(Result, '[socketConfTable_Active]', MySQL_Agents_GetAllAgents_HTML, [rfReplaceAll]);

  //  result := StringReplace(result, 'FSDWEF#$WR#W_TASCk', '77777#####', [rfReplaceAll]);
//  result := StringReplace(result, 'FSDWEF#$WR#W_TASCk', '77777#####', [rfReplaceAll]);
//  result := StringReplace(result, 'FSDWEF#$WR#W_TASCk', '77777#####', [rfReplaceAll]);
end;


function GetHTML(ARequestInfo: TIdHTTPRequestInfo; {Param, URL, Host : string; }var AResponseInfo: TIdHTTPResponseInfo): string;
var
  params  : Tstringlist;
  Reg     : TRegEx;
  Match   : TMatchCollection;
  i       : Integer;
  response  : TStringList;
  filename  : string;

  Host      : string;
  job1      : Tjobrec;


////////////////////////////
  AuthToken     : string;
  IndexValue    : integer;
  RequestPage   : string;

  HTML  : TStringList;
begin
  response    := nil;
  params      := nil;
  RequestPage := ARequestInfo.URI;
  Host := ARequestInfo.Host;
  if ARequestInfo.Host.Contains(':') then
  begin
    Host        := ARequestInfo.Host.Substring(0, ARequestInfo.Host.IndexOf(':'));
  end;

  //log.SaveLog('Try to connect HTTP server: ' + Host);
  try
    if  authClient(ARequestInfo, AResponseInfo, RequestPage, Host) then
    begin
      filename := wwwpath + Host +RequestPage;
      AResponseInfo.ContentText := refreshIndex(filename);
      AResponseInfo.ContentType := GenContType(RequestPage);

  //    AResponseInfo.ContentStream := TFileStream.Create(filename, fmShareDenyNone);
    end else
    begin
      HTML  := TStringList.Create;
      filename := wwwpath + Host +RequestPage;
      HTML.LoadFromFile(filename);
      HTML.Text := Localization_HTML(RequestPage, HTML.Text);
      AResponseInfo.ContentType := GenContType(RequestPage);
      AResponseInfo.ContentText := HTML.Text;
      HTML.Free;
//      AResponseInfo.ContentStream := TFileStream.Create(filename, fmShareDenyNone);
    end;
  finally
    if response <> nil then response.Free;
    if params <> nil then params.Free;
  //  if Reg <> nil then Reg

  end;

end;

end.
