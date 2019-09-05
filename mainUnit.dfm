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
    Left = 104
    Top = 72
  end
  object IdFTPServer1: TIdFTPServer
    Bindings = <>
    CommandHandlers = <>
    ExceptionReply.Code = '500'
    ExceptionReply.Text.Strings = (
      'Unknown Internal Error')
    Greeting.Code = '220'
    Greeting.Text.Strings = (
      'Indy FTP Server ready.')
    MaxConnectionReply.Code = '300'
    MaxConnectionReply.Text.Strings = (
      'Too many connections. Try again later.')
    ReplyTexts = <>
    ReplyUnknownCommand.Code = '500'
    ReplyUnknownCommand.Text.Strings = (
      'Unknown Command')
    AnonymousAccounts.Strings = (
      'anonymous'
      'ftp'
      'guest')
    OnUserLogin = IdFTPServer1UserLogin
    OnUserAccount = IdFTPServer1UserAccount
    SITECommands = <>
    MLSDFacts = []
    ReplyUnknownSITCommand.Code = '500'
    ReplyUnknownSITCommand.Text.Strings = (
      'Invalid SITE command.')
    Left = 104
    Top = 24
  end
end
