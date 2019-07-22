unit messageExecute;

interface

uses System.JSON, varsUnit, SocketUnit, System.SysUtils, System.Classes, MySQLUnit;

function newMessage(msg : string; SocketConf : TSocketConf): Integer;//функция нового сообщения, которая видна всему проекту

implementation


function CheckLogin(JS : TJSONObject; ip : string; out ID: integer): Integer;
var
  key, name : string;
begin
  JS.TryGetValue('key', key);
  JS.TryGetValue('name', name);

  Result := MySQL_CheckLogin(key, ip, name, ID);
//  Result  := 0;
end;

function Recivefile(JS : TJSONObject; SocketConf : TSocketConf): Integer;
begin
  Result  := 0;
  JS.TryGetValue('outDir', SocketConf.filedir);
  JS.TryGetValue('fileName', SocketConf.fileName);
  JS.TryGetValue('fileSize', SocketConf.fileSize);
  JS.TryGetValue('MD5',       SocketConf.MD5);
  if DirectoryExists(SocketConf.filedir) = False then
  begin
    ForceDirectories(SocketConf.filedir);
  end;

  SocketConf.fileStrim := TFileStream.Create(SocketConf.filedir +'\'+ SocketConf.fileName, fmOpenWrite or fmCreate);


end;


function newMessage(msg : string; SocketConf : TSocketConf): Integer;//функция нового сообщения, которая видна всему проекту
var
  js : TJSONObject;//новая переменная js как json объект
  action : string;  //переменная action
begin
  Result := 0;  //задаем result значение 0
  js := nil;  //обнуляем js
  log.SaveLog('new msg : ' + msg);  //сохраняем в лог новое пришедшее сообщение
  try
    js := TJSONObject.ParseJSONValue(msg) as TJSONObject;//переопределяем js как распаршеное сообщение msg
    try
      if js.TryGetValue('action', action) = True then //если в msg есть action
      begin
        if action = 'login' then
        begin
          Result := CheckLogin(js, SocketConf.client_IP, SocketConf.agent_Id); //если action ссылается на newJob, то выполняем функцию newJob
          if Result = 0
            then SocketConf.ConnectType := 1
            else SocketConf.ConnectType := 10;

        end;
        if action = 'sendfile' then
        begin
          Result := Recivefile(js, SocketConf);//если action ссылается на login, то выполняем функцию checkLoginAnswer
          if Result = 0 then SocketConf.ConnectType := 3;

        end;


        if action = 'newJob2' then Result := 0; {*newFunction*}
        if action = 'newJob3' then Result := 0; {*newFunction*}
        if action = 'newJob4' then Result := 0; {*newFunction*}




      end else
      begin
        Log.SaveLog('Error newMessage : Action not found'); //усли action не найдет, то пишем в лог ошибку
       // Result := notFoundsActions;//переопределяем result

      end;
    finally
      js.Free; //освобождаем js
    end;

  except
    on E: Exception do
    begin
      Log.SaveLog('Error newMessage :' + E.Message);
     // Result := errorExcept;
    end;
  end;
end;

end.
