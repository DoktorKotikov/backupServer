unit HtmlUnit;

interface

uses System.Classes, System.sysutils, System.RegularExpressions, varsUnit, IdCustomHTTPServer, jobsUnit;

function GetHTML(Param, URL, Host : string; var AResponseInfo: TIdHTTPResponseInfo): string;

implementation

function GenContType(filename : string) : string;
begin
  filename := filename.Substring(filename.IndexOf('.')+1, 10);
  if (filename = 'htm') or (filename = 'html') then Result := 'text/html' else
  if filename = 'ico' then Result := 'image/xicon' else
  if filename = 'mp4' then Result := 'video/mp4' else




end;

function GetHTML(Param, URL, Host : string; var AResponseInfo: TIdHTTPResponseInfo): string;
var
  params  : Tstringlist;
  Reg     : TRegEx;
  Match   : TMatchCollection;
  i       : Integer;
  response  : TStringList;
  filename  : string;

  job1      : Tjobrec;
begin
  response  := nil;
  params    := nil;
 // Reg       := nil;
  try
    response  := TStringList.Create;
    params    := Tstringlist.Create;
    params.Text := Param;
    Host  := Host.Substring(0, Host.IndexOf(':'));

 //   if ARequestInfo.Command <> 'GET' then
    begin

      if URL = '/' then
      begin
        URL := wwwpathSeparator + 'index.html';
      end else
      begin
        URL   := URL.Replace('/', wwwpathSeparator, [rfReplaceAll]);
      end;
      job1.rules := params.Values['rules'];
      job1.crone := params.Values['crone'];
      job1.Tags := params.Values['Tags'];

      Jobs.ADDJob(job1);
      filename := wwwpath + Host +URL;
     // StringReplace(URL)
   //   response.LoadFromFile(filename);


    //  AResponseInfo.ResponseNo := 501; // 501 ошибка
//      aFilename := NormalFileName('/501.htm');
      AResponseInfo.ContentType := GenContType(URL);
      AResponseInfo.ContentStream := TFileStream.Create(filename, fmShareDenyNone);

     // Result  := response.Text;








      Reg     := TRegEx.Create('/^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$/');
      Match   := Reg.Matches(URL);
      for I := 0 to Match.Count -1 do
      begin
        log.SaveLog('URL param ' + Match.Item[i].Value);
      end;

    end;

  finally
    if response <> nil then response.Free;
    if params <> nil then params.Free;
  //  if Reg <> nil then Reg

  end;

end;

end.
