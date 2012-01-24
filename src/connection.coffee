events = require 'events'

Parser   = require('./parser').Parser
Packet   = require('./packet').Packet
Protocol = require('./protocol')

class exports.Connection extends events.EventEmitter
  constructor: (@socket) ->
    @parser = new Parser()
    @socket.on 'connect', => @emit 'connect'
    @socket.on 'end', => @emit 'end'
    @socket.on 'close', (hadError) => @emit 'close', hadError
    @socket.on 'error', (error) => @emit 'error', error
    @socket.on 'data', (data) => @addData(data)

  end: (msg) ->
    @socket.end()

  writePacket: (header, payload...) ->
    if payload? and typeof(payload[payload.length - 1]) is 'function'
      callback = payload.pop()

    packet = new Packet(header)
    @socket.write packet.build(payload...), callback

  addData: (data) ->
    # If leftover data already exists, concatenate.
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

      # Cut out the packet we parsed
      @packet = if bytesParsed < @packet.length
        @packet.slice(bytesParsed)
      else
        null

      @emit 'data', header, payload

      # Parse the reset of the data if any is remaining.
      @parsePacket() if @packet?

    # An error parsing means the data crosses over two packets and we need to try again when another packet comes in.
    catch e
      @parser.rewind()
