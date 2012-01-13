# Runs a proxy server which prints out minecraft packets and raw buffers
# coffee examples/proxy 0.0.0.0 25565 5001

events = require 'events'
net = require 'net'

mc   = require('..')

delay = (ms, func) -> setTimeout func, ms

serviceHost = process.argv[2]
proxyPort = process.argv[3]
servicePort = process.argv[4]

server = net.createServer (proxySocket) ->
  proxyConn = new mc.Connection proxySocket
  
  serviceSocket = new net.Socket()
  serviceSocket.connect servicePort, serviceHost

  proxySocket.on 'data', (data) -> 
    console.log('>| ', data)
    serviceSocket.write(data)

  serviceSocket.on 'data', (data) -> 
    console.log(' |<', data)
    proxySocket.write(data)

  serviceConn = new mc.Connection serviceSocket

  proxyConn.on "packet", (event, header, payload...) ->
    console.log('>| ', event, header, payload...)

  serviceConn.on "packet", (event, header, payload...) ->
    console.log(' |<', event, header, payload...)
    
  proxySocket.on "close", (had_error) ->
    serviceSocket.end()

  serviceSocket.on "close", (had_error) ->
    proxySocket.end()

server.listen proxyPort

