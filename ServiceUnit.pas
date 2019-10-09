unit ServiceUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs;

type
  TBackup4you = class(TService)
    procedure ServiceCreate(Sender: TObject);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Backup4you: TBackup4you;

implementation

{$R *.dfm}

uses mainUnit;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Backup4you.Controller(CtrlCode);
end;

function TBackup4you.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TBackup4you.ServiceCreate(Sender: TObject);
begin
  DataModule2:= TDataModule2.Create(nil);
end;

end.
