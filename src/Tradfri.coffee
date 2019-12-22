NodeTradfri = require 'node-tradfri-client'
require('promise.prototype.finally').shim()

Client              = NodeTradfri.TradfriClient
Types               = NodeTradfri.AccessoryTypes
TradfriError        = NodeTradfri.TradfriError
TradfriErrorCodes   = NodeTradfri.TradfriErrorCodes

Accessory = require './Accessory'
Group     = require './Group'
Property  = require './Property'

Debug = require 'debug'

class Tradfri extends Property

  # This should be called with either a securityId string
  # or an object containing the keys: identity & psk
  constructor: (@hub, @securityId, customLogger) ->
    super()
    @debug = customLogger ? Debug 'ikea-tradfri'
    params =
      watchConnection: true
    params.customLogger = customLogger if customLogger
    @client = new Client @hub, params

  connect: ->
    credentials = undefined
    (
      if typeof @securityId is 'string'
        @client.authenticate  @securityId
      else
        Promise.resolve
          identity: @securityId.identity
          psk:      @securityId.psk
    )
    .then (result) =>
      credentials = result
      @client.removeAllListeners()
      @client.connect result.identity, result.psk
    .then (ans) =>
      unless ans
        throw new TradfriError "Failed to connect (response was empty)", TradfriErrorCodes.ConnectionFailed
      @client.on 'error', (err) =>
        if err instanceof TradfriError
          switch err.code
            when TradfriErrorCodes.NetworkReset, TradfriErrorCodes.ConnectionTimedOut
              @debug err.message, "warn"
            when TradfriErrorCodes.AuthenticationFailed, TradfriErrorCodes.ConnectionFailed
              @debug err.message, "error"
              throw err
        else
          @debug err.message, "error"
          throw err
      .on "device updated", (device) =>
        newdev = Accessory.update device
        @debug "device updated: #{device.name} (type=#{device.type} [#{newdev.type}])", "debug"
      .on "device removed", (id) =>
        Accessory.delete id
        @debug "device removed: #{id}", "debug"
      .on "group updated", (group) =>
        Group.update group
        @debug "group updated: #{group.name}", "debug"
      .on "group removed", (groupID) =>
        group = Group.delete groupID
        @debug "group removed: #{group?.name}", "debug"
      .on "scene updated", (groupID, scene) =>
        group = Group.byID groupID
        if group?
          group.addScene scene
          @debug "scene updated: #{group.name}: #{scene.name}", "debug"
        else
          @debug "scene updated: Missing group #{groupID}", "warn"
      .on "scene removed", (groupID, sceneID) =>
        group = Group.byID groupID
        if group?
          group.delScene sceneID
          @debug "scene removed from group.name: #{sceneID}", "debug"
        else
          @debug "scene removed: Missing group #{groupID}", "warn"
      @client.observeDevices()
    .then =>      # Need the devices in place so not Promise.all()
      @debug "observeDevices resolved", "debug"
      @client.observeGroupsAndScenes()
    .then =>
      @debug "observeGroupsAndScenes resolved", "debug"
    .catch (err) =>
      if err instanceof TradfriError
        switch err.code
          when TradfriErrorCodes.NetworkReset, TradfriErrorCodes.ConnectionTimedOut
            return @debug err.message, "warn"
          when TradfriErrorCodes.AuthenticationFailed, TradfriErrorCodes.ConnectionFailed
            @debug err.message, "error"
      throw err
    .finally =>
      credentials


  reset: ->
    @client.reset()
    .then =>
      @connect()

  close: ->
    @client.destroy()
    Group.close()
    Accessory.close()
    delete @client

  @property 'devices',
    get: ->
      Accessory.listDevices()

  @property 'groups',
    get: ->
      Group.listGroups()

  device: (name) ->
    Accessory.get name

  group: (name) ->
    Group.get name

module.exports = Tradfri
