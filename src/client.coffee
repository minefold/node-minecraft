events = require 'events'
http  = require 'http'
url   = require 'url'
net   = require 'net'
Connection = require('./connection').Connection

delay = (ms, func) -> setTimeout func, ms

class WebAuthClient extends events.EventEmitter
  getSessionId: (username, password, callback) ->
    loginPath = url.format
      pathname: '/'
      query:
        user: username
        password: password
        version: 12

    req = http.get {hostname: 'login.minecraft.net', path: loginPath}, (resp) =>
      resp.on 'data', (data) =>
        body = data.toString()

        if body is 'Bad login'
          @emit 'error', body
        else
          callback body.split(':', 4)[3]
            
  verifyServer: (username, sessionId, serverId, callback) ->
    sessionPath = url.format
      pathname: '/game/joinserver.jsp'
      query:
        user: username
        sessionId: sessionId
        serverId: serverId

    vreq = http.get {hostname: 'session.minecraft.net', path: sessionPath}, (vresp) =>

      vresp.on 'data', (data) =>
        body = data.toString()

        if body isnt 'OK'
          @emit 'error', body
        else
          callback
    

class exports.Client extends events.EventEmitter
  constructor: (@port, @host, @username, @password) ->
    if @password
      @connectOnlineMode()
    else
      @connectOfflineMode()
      
  connectOnlineMode: ->
    webAuthClient = new WebAuthClient()
    webAuthClient.on 'error', ->
      console.error(body)
      process.exit(1)
      
    webAuthClient.getSessionId @username, @password,  (sessionId) =>
      # Connect to the server
      @createConnection(@port, @host)
        
      @conn.on 'connect', =>
        # Send our username
        @conn.writePacket 0x02, @username

        # Get back the serverId
        @conn.once 'handshake', (serverId) =>

          webAuthClient.verifyServer @username, sessionId, serverId, ->

            @conn.writePacket 0x01, 23, @username, 0, '', 0, 0, 0, 0, 0
    
  connectOfflineMode: ->
    # Connect to the server
    @createConnection(@port, @host)
        
    @conn.on 'connect', =>
      # Send our username
      @conn.writePacket 0x02, @username

      # Get back the serverId
      @conn.once 'handshake', (serverId) =>
        @conn.writePacket 0x01, 23, @username, 0, '', 0, 0, 0, 0, 0
    
  createConnection: ->
    @conn = new Connection net.createConnection(@port, @host)    
    
    # respond to keepalive packets
    @conn.on 'keepalive', (id) => @conn.writePacket 0x00, id
    
    @conn.once 'login', (@eId, _, seed, levelType, mode, dim, difficulty, height, maxPlayers) =>
      @world =
        seed: seed
        levelType: levelType
        mode: mode
        dimension: dim
        difficulty: difficulty
        maxPlayers: maxPlayers

      @emit 'connect', @

    # Echos the 0x0D packet (needs to happen otherwise server fucks out)
    @conn.once 'player position and look', (x, stance, y, z, yaw, pitch, grounded) =>
      @conn.writePacket 0x0D, arguments...

    @conn.on 'end', => @emit 'end'


  # Convenience functions
  say: (msg) ->
    msg.split("\n").forEach (line) =>
      if line.length > 100
        line = line.substring(0, 100)

      @conn.writePacket 0x03, line
      
  disconnect: ->
    @conn.writePacket 0xFF, 'Bye!'
