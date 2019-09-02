unit HtmlUnit;

interface

uses System.Classes, System.sysutils, System.RegularExpressions, System.Generics.Collections, IdUri, Web.HTTPApp, System.JSON,
    varsUnit, IdCustomHTTPServer, jobsThreadUnit, MySQLUnit, IdCookie, myconfig.Logs, IdSSL, SocketUnit; //, serfHTTPUnit

function GetHTML(ARequestInfo: TIdHTTPRequestInfo; {Param, URL, Host : string; }var AResponseInfo: TIdHTTPResponseInfo): string;
procedure CreateMIMEtypesTabel();

implementation

var
  MIMEtypesTabel  : TDictionary<string, string>;

procedure CreateMIMEtypesTabel();
begin
  MIMEtypesTabel  := TDictionary<string, string>.create;
  MIMEtypesTabel.Add( 'hqx', 'application/mac-binhex40');
  MIMEtypesTabel.Add( 'doc', 'application/msword');
  MIMEtypesTabel.Add( 'bin', 'application/octet-stream');
  MIMEtypesTabel.Add( 'dms', 'application/octet-stream');
  MIMEtypesTabel.Add( 'lha', 'application/octet-stream');
  MIMEtypesTabel.Add( 'lzh', 'application/octet-stream');
  MIMEtypesTabel.Add( 'exe', 'application/octet-stream');
  MIMEtypesTabel.Add( 'class', 'application/octet-stream');
  MIMEtypesTabel.Add( 'pdf', 'application/pdf');
  MIMEtypesTabel.Add( 'ai', 'application/postscript');
  MIMEtypesTabel.Add( 'eps', 'application/postscript');
  MIMEtypesTabel.Add( 'ps', 'application/postscript');
  MIMEtypesTabel.Add( 'smi', 'application/smil');
  MIMEtypesTabel.Add( 'smil', 'application/smil');
  MIMEtypesTabel.Add( 'mif', 'application/vnd.mif');
  MIMEtypesTabel.Add( 'asf', 'application/vnd.ms-asf');
  MIMEtypesTabel.Add( 'xls', 'application/vnd.ms-excel');
  MIMEtypesTabel.Add( 'ppt', 'application/vnd.ms-powerpoint');
  MIMEtypesTabel.Add( 'vcd', 'application/x-cdlink');
  MIMEtypesTabel.Add( 'Z', 'application/x-compress');
  MIMEtypesTabel.Add( 'cpio', 'application/x-cpio');
  MIMEtypesTabel.Add( 'csh', 'application/x-csh');
  MIMEtypesTabel.Add( 'dcr', 'application/x-director');
  MIMEtypesTabel.Add( 'dir', 'application/x-director');
  MIMEtypesTabel.Add( 'dxr', 'application/x-director');
  MIMEtypesTabel.Add( 'dvi', 'application/x-dvi');
  MIMEtypesTabel.Add( 'gtar', 'application/x-gtar');
  MIMEtypesTabel.Add( 'gz', 'application/x-gzip');
  MIMEtypesTabel.Add( 'js', 'application/x-javascript');
  MIMEtypesTabel.Add( 'latex', 'application/x-latex');
  MIMEtypesTabel.Add( 'sh', 'application/x-sh');
  MIMEtypesTabel.Add( 'shar', 'application/x-shar');
  MIMEtypesTabel.Add( 'swf', 'application/x-shockwave-flash');
  MIMEtypesTabel.Add( 'sit', 'application/x-stuffit');
  MIMEtypesTabel.Add( 'tar', 'application/x-tar');
  MIMEtypesTabel.Add( 'tcl', 'application/x-tcl');
  MIMEtypesTabel.Add( 'tex', 'application/x-tex');
  MIMEtypesTabel.Add( 'texinfo', 'application/x-texinfo');
  MIMEtypesTabel.Add( 'texi', 'application/x-texinfo');
  MIMEtypesTabel.Add( 't', 'application/x-troff');
  MIMEtypesTabel.Add( 'tr', 'application/x-troff');
  MIMEtypesTabel.Add( 'roff', 'application/x-troff');
  MIMEtypesTabel.Add( 'man', 'application/x-troff-man');
  MIMEtypesTabel.Add( 'me', 'application/x-troff-me');
  MIMEtypesTabel.Add( 'ms', 'application/x-troff-ms');
  MIMEtypesTabel.Add( 'zip', 'application/zip');
  MIMEtypesTabel.Add( 'wmlc', 'application/vnd.wap.wmlc');
  MIMEtypesTabel.Add( 'au', 'audio/basic');
  MIMEtypesTabel.Add( 'snd', 'audio/basic');
  MIMEtypesTabel.Add( 'mid', 'audio/midi');
  MIMEtypesTabel.Add( 'midi', 'audio/midi');
  MIMEtypesTabel.Add( 'kar', 'audio/midi');
  MIMEtypesTabel.Add( 'mpga', 'audio/mpeg');
  MIMEtypesTabel.Add( 'mp2', 'audio/mpeg');
  MIMEtypesTabel.Add( 'mp3', 'audio/mpeg');
  MIMEtypesTabel.Add( 'aif', 'audio/x-aiff');
  MIMEtypesTabel.Add( 'aiff', 'audio/x-aiff');
  MIMEtypesTabel.Add( 'aifc', 'audio/x-aiff');
  MIMEtypesTabel.Add( 'ram', 'audio/x-pn-realaudio');
  MIMEtypesTabel.Add( 'rm', 'audio/x-pn-realaudio');
  MIMEtypesTabel.Add( 'ra', 'audio/x-realaudio');
  MIMEtypesTabel.Add( 'wav', 'audio/x-wav');
  MIMEtypesTabel.Add( 'bmp', 'image/bmp');
  MIMEtypesTabel.Add( 'gif', 'image/gif');
  MIMEtypesTabel.Add( 'ief', 'image/ief');
  MIMEtypesTabel.Add( 'jpeg', 'image/jpeg');
  MIMEtypesTabel.Add( 'jpg', 'image/jpeg');
  MIMEtypesTabel.Add( 'jpe', 'image/jpeg');
  MIMEtypesTabel.Add( 'png', 'image/png');
  MIMEtypesTabel.Add( 'tiff', 'image/tiff');
  MIMEtypesTabel.Add( 'tif', 'image/tiff');
  MIMEtypesTabel.Add( 'wbmp', 'image/vnd.wap.wbmp');
  MIMEtypesTabel.Add( 'ras', 'image/x-cmu-raster');
  MIMEtypesTabel.Add( 'pnm', 'image/x-portable-anymap');
  MIMEtypesTabel.Add( 'pbm', 'image/x-portable-bitmap');
  MIMEtypesTabel.Add( 'pgm', 'image/x-portable-graymap');
  MIMEtypesTabel.Add( 'ppm', 'image/x-portable-pixmap');
  MIMEtypesTabel.Add( 'rgb', 'image/x-rgb');
  MIMEtypesTabel.Add( 'xbm', 'image/x-xbitmap');
  MIMEtypesTabel.Add( 'xpm', 'image/x-xpixmap');
  MIMEtypesTabel.Add( 'xwd', 'image/x-xwindowdump');
  MIMEtypesTabel.Add( 'ico', 'image/x-icon');
  MIMEtypesTabel.Add( 'igs', 'model/iges');
  MIMEtypesTabel.Add( 'iges', 'model/iges');
  MIMEtypesTabel.Add( 'msh', 'model/mesh');
  MIMEtypesTabel.Add( 'mesh', 'model/mesh');
  MIMEtypesTabel.Add( 'silo', 'model/mesh');
  MIMEtypesTabel.Add( 'wrl', 'model/vrml');
  MIMEtypesTabel.Add( 'vrml', 'model/vrml');
  MIMEtypesTabel.Add( 'css', 'text/css');
  MIMEtypesTabel.Add( 'html', 'text/html; charset=UTF-8');
  MIMEtypesTabel.Add( 'htm', 'text/html; charset=UTF-8');
  MIMEtypesTabel.Add( 'asc', 'text/plain');
  MIMEtypesTabel.Add( 'txt', 'text/plain');
  MIMEtypesTabel.Add( 'rtx', 'text/richtext');
  MIMEtypesTabel.Add( 'rtf', 'text/rtf');
  MIMEtypesTabel.Add( 'sgml', 'text/sgml');
  MIMEtypesTabel.Add( 'sgm', 'text/sgml');
  MIMEtypesTabel.Add( 'tsv', 'text/tab-separated-values');
  MIMEtypesTabel.Add( 'xml', 'text/xml');
  MIMEtypesTabel.Add( 'wml', 'text/vnd.wap.wml');
  MIMEtypesTabel.Add( 'wmls', 'text/vnd.wap.wmlscript');
  MIMEtypesTabel.Add( 'mpeg', 'video/mpeg');
  MIMEtypesTabel.Add( 'mpg', 'video/mpeg');
  MIMEtypesTabel.Add( 'mpe', 'video/mpeg');
  MIMEtypesTabel.Add( 'qt', 'video/quicktime');
  MIMEtypesTabel.Add( 'mov', 'video/quicktime');
  MIMEtypesTabel.Add( 'avi', 'video/x-msvideo');
end;


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
var
  symbol        : Char;
  LastPosition  : integer;
begin
  LastPosition := filename.Length;
  repeat
    symbol := filename[LastPosition];
    Dec(LastPosition);
  until (LastPosition = 0) OR (symbol = '.');

  filename := filename.Substring(LastPosition+1, 10);
  if MIMEtypesTabel.TryGetValue(filename, Result) = false then Result := 'application/octet-stream';
  {

  if (filename = 'htm') or (filename = 'html') then Result := 'text/html; charset=UTF-8' else
  if filename = 'ico' then Result := 'image/xicon' else
  if filename = 'mp4' then Result := 'video/mp4' else
  if filename = 'css' then Result := 'text/css; charset=UTF-8' else
  if filename = 'min.js' then
  begin
  Result := 'text/javascript; charset=UTF-8'
  end;

         }

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


function refreshIndex(filename : string; Params : TStrings): string;
var
  list    : TStringList;
  tempInt : Integer;
  jobName : string;
  JobTags : string;
  crone   : string;
  rules   : string;
  active  : integer;
begin
 // crone := TIdUri.URLEncode('lê');

  list     := TStringList.Create;
  try
    list.LoadFromFile(filename);
    Result:=list.text;
  finally
    list.Free;
  end;

  Result := StringReplace(Result, '[BackupServer_TASCkList]',  jobsThread.getAllJobs_HTML, [rfReplaceAll]);
  Result := StringReplace(Result, '[socketConfTable_Active]',  MySQL_Agents_GetAllAgents_HTML, [rfReplaceAll]);
  if Params.IndexOf('jobnumber') <> 0 then
  begin
    if TryStrToInt(Params.Values['jobnumber'], tempInt) = true then
    begin

      Result := StringReplace(Result, '[All_tagsList]', MySQL_GetTagsListFromJob_HTML(tempInt), [rfReplaceAll]);

      MySQL_GetJob_HTML(tempInt, JobTags, jobName, crone, rules, active);
      Result := StringReplace(Result, '[Job_tagsList]',  JobTags, [rfReplaceAll]);
      Result := StringReplace(Result, '[Job_Name]',  jobName, [rfReplaceAll]);

      Result := StringReplace(Result, '[jobe_Cron]',  crone, [rfReplaceAll]);
      Result := StringReplace(Result, '[jobe_Rules]',  rules, [rfReplaceAll]);
      if active = 0
      then Result := StringReplace(Result, '[jobe_Active]', 'checked', [rfReplaceAll])
      else Result := StringReplace(Result, '[jobe_Active]', '', [rfReplaceAll]);


    end;
  end;

end;

function PostJS(param : string): Integer;
var
  js      : TJSONObject;
  action  : string;
begin
  try
    js := TJSONObject.ParseJSONValue(param) as TJSONObject;//переопределяем js как распаршеное сообщение msg
    if js.TryGetValue('action', action) then
    begin
      if action = 'job_save' then
      begin
        MySQL_JobSave(js); 
      end;      
    end;
  except on E: Exception do
  end;
  
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
      PostJS(ARequestInfo.Params.Text);
      

      filename := wwwpath + Host + RequestPage;
      AResponseInfo.ContentText := refreshIndex(filename, ARequestInfo.Params);
      AResponseInfo.ContentType := GenContType(RequestPage);

  //    AResponseInfo.ContentStream := TFileStream.Create(filename, fmShareDenyNone);
    end else
    begin
      HTML  := TStringList.Create;
      HTML.WriteBOM := false;
      filename := wwwpath + Host +RequestPage;
      HTML.LoadFromFile(filename);
      AResponseInfo.ContentEncoding := 'utf-8';
      HTML.Text := Localization_HTML(RequestPage, HTML.Text);
      AResponseInfo.ContentType := GenContType(RequestPage);
      AResponseInfo.CharSet := 'utf-8';
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
