Common = require './Common'
EventEmitter = require 'events'
IsEqual = require 'deep-equal'

INTERVAL = 1000 / 2     # 5 times a second

class Device extends Common

  startPoll: ->
    console.log "Starting device poll: #{@id}"
    @polling = setInterval =>
      @coap.deviceRaw @id
      .then (raw) =>
        unless IsEqual @raw, raw
          dev = new Device raw
          changed = id: @id
          changed.ison = [@ison, dev.ison] if dev.ison isnt @ison
          changed.colour = [@colour, dev.colour] if dev.colour isnt @colour
          changed.brightness = [@brightness, dev.brightness] if dev.brightness isnt @brightness
          @raw = raw
          @emit 'changed', changed
      .catch (err) =>
        console.log "ERROR in #{@id}", err.toString()
    , INTERVAL

  @property 'type',
    get: -> @raw[3][1]

  @property 'manufacturer',
    get: -> @raw[3][0]

  @property 'ison',
    get: ->
      ison = @raw[3311]?[0][5850]
      ison is 1 if ison?

  switch: (onoff) ->
    value = if onoff then 1 else 0
    job =
      '3311': [
        '5850' : value
      ]
    @coap.updateDevice @id, job
    .then =>
      @raw[3311]?[0][5850] = value
      @

  @property 'colour',
    get: -> @raw[3311]?[0][5706]

  @property 'color',
    get: -> @colour

  @property 'brightness',
    get: ->
      bright = @raw[3311]?[0][5851]
      Math.round bright * 100 / 254 if bright?

module.exports = Device
