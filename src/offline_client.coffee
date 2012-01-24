Client = require('./client').Client

class exports.OfflineClient extends Client

  @createConnection: ->
    client = super(arguments...)

    # Start things off by initializing the handshake
    client.write 'handshake', client.username

    # Once the server handshake is compelted, initiate a login.
    client.once 'handshake', (serverId) =>
      client.write 'login', Client.PROTOCOL_VERSION, client.username, 0, '', 0, 0, 0, 0, 0

    client
