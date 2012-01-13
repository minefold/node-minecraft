events = require 'events'
http  = require 'http'
url   = require 'url'
net   = require 'net'
Parser   = require('./parser').Parser
Packet   = require('./packet').Packet
Protocol = require('./protocol')

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
    @parser = new Parser()
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
        @writePacket 0x02, @username

        # Get back the serverId
        @once 'handshake', (serverId) =>

          webAuthClient.verifyServer @username, sessionId, serverId, ->

            @writePacket 0x01, 23, @username, 0, 0, 0, 0, 0, 0
    
  connectOfflineMode: ->
    # Connect to the server
    @createConnection(@port, @host)
        
    @conn.on 'connect', =>
      # Send our username
      @writePacket 0x02, @username

      # Get back the serverId
      @once 'handshake', (serverId) =>
        console.log 'handshake'
        @writePacket 0x01, 23, @username, 0, 0, 0, 0, 0, 0
    
  createConnection: ->
    @conn = net.createConnection(@port, @host)    
    @conn.on 'error', (error) => 
      console.log "connection error: #{error}"
      @emit 'error', error
      
    @conn.on 'data', (data) => @addData(data)
    
    # respond to keepalive packets
    @on 'keepalive', (id) => @writePacket 0x00, id
    
    @once 'login', (@eId, _, seed, mode, dim, difficulty, height, maxPlayers) =>
      console.log 'login'
      @world =
        seed: seed
        mode: mode
        dimension: dim
        difficulty: difficulty
        maxPlayers: maxPlayers

      @emit 'connect', @

    # Echos the 0x0D packet (needs to happen otherwise server fucks out)
    @once 'player position and look', (x, stance, y, z, yaw, pitch, grounded) =>
      @writepacket 0x0D, arguments...

    @on 'end', => @emit 'end'

  writePacket: (header, payload...) ->
    if typeof(payload[payload.length - 1]) is 'function'
      callback = payload.pop()

    packet = new Packet(header)
    @conn.write packet.build(payload...), callback

  addData: (data) ->
    # If data already exists, add this new stuff
    @packet = if @packet?
      p = new Buffer(@packet.length + data.length)
      @packet.copy(p, 0, 0)
      data.copy(p, @packet.length, 0)
      p
    else
      data

    @parsePacket()

  parsePacket: ->
    try
      [bytesParsed, header, payload] = @parser.parse(@packet)

      console.log header

      # Continue parsing left over data
      @packet = if bytesParsed < @packet.length
        @packet.slice(bytesParsed)
      else
        null

      # Human readable event with the payload as args
      event = Protocol.LABELS[header] || 'unhandled'
      @emit event, payload...

      @parsePacket() if @packet?

    # An error parsing means the data crosses over two packets and we need to try again when another packet comes in.
    catch e
      @parser.rewind()


  # Convenience functions

  say: (msg) ->
    msg.split("\n").forEach (line) =>
      if line.length > 100
        line = line.substring(0, 100)

      chatPacket = new Packet(0x03)
      @conn.write chatPacket.build(line)
      
  disconnect: ->
    @conn.write new Packet(0xFF).build('Bye!')
