object DataModule2: TDataModule2
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 171
  Width = 215
  object IdTCPServer1: TIdTCPServer
    Bindings = <>
    DefaultPort = 0
    OnDisconnect = IdTCPServer1Disconnect
    OnExecute = IdTCPServer1Execute
    Left = 32
    Top = 24
  end
  object IdHTTPServer1: TIdHTTPServer
    Bindings = <>
    MaxConnections = 100
    OnCommandGet = IdHTTPServer1CommandGet
    Left = 32
    Top = 72
  end
  object IdServerIOHandlerSSLOpenSSL1: TIdServerIOHandlerSSLOpenSSL
    SSLOptions.Method = sslvTLSv1_2
    SSLOptions.SSLVersions = [sslvTLSv1_2]
    SSLOptions.Mode = sslmUnassigned
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    Left = 80
    Top = 72
  end
end
