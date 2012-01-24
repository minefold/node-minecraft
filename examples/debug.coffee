# Inspects packets between a client and a server. This is really useful for inspecting the packet stream between a client and a server.
# $ coffee examples/proxy 0.0.0.0 25565 5001

net = require 'net'
url = require 'url'
mc = require('..')

[_, _, serverPort, clientPort] = process.argv

proxy = net.createServer()
proxy.on 'connection', (client) ->
  console.log '-| ', client.address()

  server = new net.Socket()
  server.connect serverPort, ->
    console.log ' |-', server.address()

  client.on 'close', (had_error) ->
    console.log 'x| '
    server.end()

  server.on 'close', (had_error) ->
    console.log ' |x'
    client.end()

  serverConn = new mc.Connection(server)
  clientConn = new mc.Connection(client)

  clientConn.on "data", (header, payload) ->
    console.log '>| ', "[0x#{header.toString(16)}]", payload...

  client.on 'data', (data) ->
    server.write(data)

  serverConn.on "data", (header, payload) ->
    console.log ' |<', "[0x#{header.toString(16)}]", payload...

  server.on 'data', (data) ->
    client.write(data)

proxy.listen clientPort, ->
  console.log "listening on #{clientPort} (proxying to #{serverPort})"
