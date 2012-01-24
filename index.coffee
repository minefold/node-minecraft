mc =
  Client:        require('./src/client').Client
  OnlineClient:  require('./src/online_client').OnlineClient
  OfflineClient: require('./src/offline_client').OfflineClient
  Parser:        require('./src/parser').Parser
  Packet:        require('./src/packet').Packet
  Protocol:      require('./src/protocol')
  Connection:    require('./src/connection').Connection

mc.createOnlineClient = ->
  mc.OnlineClient.createConnection(arguments...)

mc.createOfflineClient = ->
  mc.OfflineClient.createConnection(arguments...)

# Playing nice with Mojang :)
mc.createClient = mc.createOnlineClient

module.exports = mc
