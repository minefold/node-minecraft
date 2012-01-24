# Pings a Minecraft server
#
# $ coffee examples/ping.coffee pluto.minefold.com
# ping: 194ms

net = require 'net'
mc = require('..')

[_, _, hostname, port] = process.argv
port or= mc.Client.PORT

# Start the timer
console.time('ping')

# Open a connection to the server
socket = net.createConnection port, hostname
socket.on 'connect', ->
  c = new mc.Connection(socket)

  # Write out the ping packet
  c.writePacket(0xFE)

  # Stop the timer when we get a response
  c.once 'data', (header, payload) ->
    [msg, players, max] = payload[0].split('§', 3)
    console.log "msg:", msg
    console.log "players:", players
    console.log "max:", max

    console.timeEnd('ping')
