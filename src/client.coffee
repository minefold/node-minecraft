events = require 'events'
net = require 'net'
Connection = require('./connection').Connection
Protocol = require('./protocol')

class exports.Client extends events.EventEmitter
  @PORT = 25565
  @PROTOCOL_VERSION = 23

  @createConnection: (host, port, username, password, callback) ->
    new @(host, port, username, password, callback)

  constructor: (@host, @port, @username, @password, callback) ->
    if callback? and typeof(callback) is 'function'
      @on 'connect', callback

    @conn = new Connection(net.createConnection(@port, @host))

    @conn.on 'end', => @emit 'end'
    @conn.on 'close', (hadError) => @emit 'close', hadError
    @conn.on 'error', (error) => @emit 'error', error

    # Emits a human readable event with the payload as args
    @conn.on 'data', (header, payload) =>
      eventName = Protocol.LABELS[header] || 'unhandled'
      @emit eventName, payload...

    # Echo keepalives to keep the socket open
    @on 'keepalive', =>
      @write 'keepalive', arguments...

    # Echos the 0x0D packet (needs to happen otherwise server fucks out)
    @once 'player position and look', =>
      @write 'player position and look', arguments...

    # Kick things off once when we get the login
    @once 'login', (@eId, _, seed, levelType, mode, dim, difficulty, height, maxPlayers) ->
      @world =
        seed: seed
        levelType: levelType
        mode: mode
        dimension: dim
        difficulty: difficulty
        maxPlayers: maxPlayers

      @emit 'connect', @


  write: (packetName, payload...) ->
    packet = Protocol.HEADERS[packetName]
    @conn.writePacket packet, payload...

  end: (msg) ->
    @write 'kick', msg || 'Bye!', =>
      @conn.end()

  say: (msg, callback) ->
    console.assert 0 < msg.length <= 100
    @write 'chat', msg, callback

