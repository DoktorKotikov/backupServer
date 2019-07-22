object DataModule2: TDataModule2
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 215
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnDisconnect = IdTCPServer1Disconnect
    OnExecute = IdTCPServer1Execute
    Left = 32
    Top = 24
  end
end
