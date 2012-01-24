http = require 'http'
url = require 'url'
Client = require('./client').Client

class exports.OnlineClient extends Client
  @LAUNCHER_VERSION = 12

  @createConnection: ->
    client = super(arguments...)

    # Get the session token
    client.getSessionId (sessionId) ->

      # Start the handshake
      client.write 'handshake', client.username

      # Once the handshake is complete
      client.once 'handshake', (serverId) ->
        # Verify the server with our session token
        client.verifyServer sessionId, serverId, ->

          # If everything is kosher, login
          client.write 'login', Client.PROTOCOL_VERSION, client.username, 0, '', 0, 0, 0, 0, 0

    client

  getSessionId: (callback) ->
    query = {user: @username, password: @password, version: @constructor.LAUNCHER_VERSION}

    options =
      hostname: 'login.minecraft.net'
      path: url.format(pathname: '/', query: query)

    http.get options, (rep) ->
      rep.on 'data', (data) ->
        body = data.toString()

        if body is 'Bad login'
          @emit 'error', body
        else
          callback body.split(':', 4)[3]

  verifyServer: (sessionId, serverId, callback) ->
    query = {user: @username, sessionId: sessionId, serverId: serverId}

    options =
      hostname: 'session.minecraft.net'
      path: url.format(pathname: '/game/joinserver.jsp', query: query)

    http.get options, (rep) ->
      rep.on 'data', (data) ->
        body = data.toString()

        if body isnt 'OK'
          @emit 'error', body
        else
          callback()
