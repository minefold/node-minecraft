events = require 'events'

Parser   = require('./parser').Parser
Packet   = require('./packet').Packet
Protocol = require('./protocol')


class exports.Connection extends events.EventEmitter
  constructor: (@socket) ->
    @parser = new Parser()
    @socket.on 'connect', => @emit 'connect'
    @socket.on 'end',     => @emit 'end'
    @socket.on 'close',   (hadError) => @emit 'close', hadError
    @socket.on 'error',   (error) => @emit 'error', error

    @socket.on 'data',    (data) => @addData(data)
    
  writePacket: (header, payload...) ->
    if typeof(payload[payload.length - 1]) is 'function'
      callback = payload.pop()

    packet = new Packet(header)
    @socket.write packet.build(payload...), callback

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

      # Continue parsing left over data
      @packet = if bytesParsed < @packet.length
        @packet.slice(bytesParsed)
      else
        null

      # Human readable event with the payload as args
      event = Protocol.LABELS[header] || 'unhandled'
      
      @emit event, payload...
      @emit 'packet', event, header, payload...

      @parsePacket() if @packet?

    # An error parsing means the data crosses over two packets and we need to try again when another packet comes in.
    catch e
      @parser.rewind()
