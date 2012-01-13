events = require 'events'

Parser   = require('./parser').Parser
Packet   = require('./packet').Packet
Protocol = require('./protocol')


class exports.Connection extends events.EventEmitter
  constructor: (@conn) ->
    @parser = new Parser()
    @conn.on 'connect', => @emit 'connect'
    @conn.on 'data', (data) => @addData(data)
    @conn.on 'error', (error) => 
      console.log "connection error: #{error}"
      @emit 'error', error
    
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
