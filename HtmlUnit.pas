unit HtmlUnit;

interface

uses System.Classes, System.sysutils, System.RegularExpressions,
    varsUnit, IdCustomHTTPServer, jobsUnit, MySQLUnit, IdCookie, myconfig.Logs;

function GetHTML(ARequestInfo: TIdHTTPRequestInfo; {Param, URL, Host : string; }var AResponseInfo: TIdHTTPResponseInfo): string;

implementation

function GenContType(filename : string) : string;
begin
  filename := filename.Substring(filename.IndexOf('.')+1, 10);
  if (filename = 'htm') or (filename = 'html') then Result := 'text/html' else
  if filename = 'ico' then Result := 'image/xicon' else
  if filename = 'mp4' then Result := 'video/mp4' else




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
  ClientCookie  : TIdCookie;

  cook          : TIdCookie;
  Login, pass   : string;
begin
  response    := nil;
  params      := nil;
  RequestPage := ARequestInfo.URI;
  Host        := ARequestInfo.Host.Substring(0, ARequestInfo.Host.IndexOf(':'));
  log         := TLogsSaveClasses.Create();



  try
    log.SaveLog('Try to connect HTTP server: ' + Host);
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
            cook.Value      :=  MySQL_ADDHTTPSession(Login, ARequestInfo.RemoteIP, ARequestInfo.UserAgent);
            cook.Expires    := Now() + 10;
            cook.Domain     := Host;
            cook.Secure     := True;
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
        if RequestPage = '/' then
        begin
          RequestPage := wwwpathSeparator + 'index.html';
        end else
        begin
          RequestPage   := RequestPage.Replace('/', wwwpathSeparator, [rfReplaceAll]);
        end;
        ////
        ///
        ///
      end else
      begin
        log.SaveLog('Cookie check failed');

        AResponseInfo.Cookies.Clear;// Delete(ClientCookie.ID);
        RequestPage := '/auth.html';
      end;
    end;

    filename := wwwpath + Host +RequestPage;

    AResponseInfo.ContentType := GenContType(RequestPage);
    AResponseInfo.ContentStream := TFileStream.Create(filename, fmShareDenyNone);

  finally
    if response <> nil then response.Free;
    if params <> nil then params.Free;
  //  if Reg <> nil then Reg

  end;

end;

end.
