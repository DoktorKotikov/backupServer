unit messageExecute;

interface

uses System.JSON, varsUnit, SocketUnit, System.SysUtils, System.Classes, MySQLUnit;

function Check_AgentLogin(msg : string; out ID : integer): Integer;
function newMessage(msg : string; Agent : TAgent): Integer;//������� ������ ���������, ������� ����� ����� �������

implementation


function Check_AgentLogin(msg : string; out ID : integer): Integer;
var
  key, name, action : string;
  JS        : TJSONObject;
  ip        : string;

begin
  JS  := nil;
  ID  := -1;
  Result := Error_Socket_IncorrectLoginPas;
  try
    JS := TJSONObject.ParseJSONValue(msg) as TJSONObject;//�������������� js ��� ����������� ��������� msg
    if JS <> nil then
    begin

      if JS.TryGetValue('action', action) = True then //���� � msg ���� action
      begin
        if action = 'login' then
        begin
          if JS.TryGetValue('key',  key) = True then
          if JS.TryGetValue('name', name) = True then
          begin
            Result := MySQL_Agent_CheckLogin(key, ip, name, ID);
          end;
        end;

      end;
    end;

  finally
    if JS <> nil then JS.Free;
  end;
end;



function newMessage(msg : string; Agent : TAgent): Integer;//������� ������ ���������, ������� ����� ����� �������
var
  js : TJSONObject;//����� ���������� js ��� json ������
  action : string;  //���������� action
begin
  Result := 0;  //������ result �������� 0
  js := nil;  //�������� js
  log.SaveLog('new msg : "' + msg + '"');  //��������� � ��� ����� ��������� ���������
  try
    js := TJSONObject.ParseJSONValue(msg) as TJSONObject;//�������������� js ��� ����������� ��������� msg
    if js <> nil then
    begin
      try
        if js.TryGetValue('action', action) = True then //���� � msg ���� action
        begin


          if action = 'newJob2' then Result := 0; {*newFunction*}
          if action = 'newJob3' then Result := 0; {*newFunction*}
          if action = 'newJob4' then Result := 0; {*newFunction*}




        end else
        begin
          Log.SaveLog('Error newMessage : Action not found'); //���� action �� ������, �� ����� � ��� ������
         // Result := notFoundsActions;//�������������� result

        end;
      finally
        js.Free; //����������� js
      end;
    end else
    begin
      Result := Error_Socket_badJson;
      log.SaveLog('Error bad JSON');
    end;

  except
    on E: Exception do
    begin
      Log.SaveLog('Error newMessage :' + E.Message);
      Result := 1;        // �������� ���� ������
    end;
  end;
end;

end.
