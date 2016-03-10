net = Npm.require('net')
Lru = Npm.require('lru-cache')
PUBNUB = Npm.require('pubnub').init({
      publish_key   : 'pub-c-e61388e2-ec2f-4e50-969f-9bd3c956b87b',
      subscribe_key : 'sub-c-4261bec0-e4cf-11e5-b661-0619f8945a4f',
      error: (err) => 
        console.log 'Error:', err
      })

bind = (f) ->
  g = Meteor.bindEnvironment (self, args...) -> f.apply(self, args)
  (args...) -> g @, args...

async = (f, args...) ->
  Meteor.wrapAsync(f)(args...)

class PubnubLoginer
  constructor: (login) ->
    console.log '[pubnub] validateLogin -> '.yellow, login
    return login

class PubnubReceiver
  constructor: (message) ->
    # name = message.u.username
    # timestamp = message.ts.getTime()
    # cacheKey = "#{name}#{timestamp}"
    # room = RocketChat.models.Rooms.findOneById message.rid, { fields: { name: 1, usernames: 1, t: 1 } }
    # console.log '[pubnub] PubnubReceiver -> '.yellow, message

    # ircClient.sendMessage room, message
    return message

class PubnubSender
  constructor: (message) ->
    name = message.u.username
    timestamp = message.ts.getTime()
    cacheKey = "#{name}#{timestamp}"
    room = RocketChat.models.Rooms.findOneById message.rid, { fields: { name: 1, usernames: 1, t: 1 } }
    console.log '[pubnub] PubnubSender.msg -> '.yellow, message
    console.log '[pubnub] PubnubSender.name -> '.yellow, name
    console.log '[pubnub] PubnubSender.room -> '.yellow, room.name
    PUBNUB.publish({message: {name: name, text: message.msg }, channel: room.name})
    # ircClient.sendMessage room, message
    return message

Meteor.startup(() -> 
  PUBNUB.subscribe({
    channel_group: 'tenantID',
    callback: (msg) ->
      console.log '[pubnub] PubnubReceiver.raw -> '.yellow, msg
      rec = new PubnubReceiver msg
    , error: (msg) ->
      console.log 'error subscribing to pubnub', msg
  })

  # return async pubnubclient.connect
)


RocketChat.callbacks.add 'beforeValidateLogin', PubnubLoginer, RocketChat.callbacks.priority.LOW
RocketChat.callbacks.add 'beforeSaveMessage', PubnubSender, RocketChat.callbacks.priority.LOW
# RocketChat.callbacks.add 'beforeJoinRoom', IrcRoomJoiner, RocketChat.callbacks.priority.LOW
# RocketChat.callbacks.add 'beforeCreateChannel', IrcRoomJoiner, RocketChat.callbacks.priority.LOW
# RocketChat.callbacks.add 'beforeLeaveRoom', IrcRoomLeaver, RocketChat.callbacks.priority.LOW
# RocketChat.callbacks.add 'afterLogoutCleanUp', IrcLogoutCleanUper, RocketChat.callbacks.priority.LOW


  # createUserWhenNotExist: (name) ->
  #   user = Meteor.users.findOne {name: name}
  #   unless user
  #     console.log '[irc] createNotExistUser ->'.yellow, 'userName:', name
  #     Meteor.call 'registerUser',
  #       email: "#{name}@rocketchat.org"
  #       pass: 'rocketchat'
  #       name: name
  #     Meteor.users.update {name: name},
  #       $set:
  #         status: 'online'
  #         username: name
  #     user = Meteor.users.findOne {name: name}
  #   return user


  # createDirectRoomWhenNotExist: (source, target) ->
  #   console.log '[irc] createDirectRoomWhenNotExist -> '.yellow, 'source:', source, 'target:', target
  #   rid = [source._id, target._id].sort().join('')
  #   now = new Date()
  #   RocketChat.models.Rooms.upsert
  #     _id: rid
  #   ,
  #     $set:
  #       usernames: [source.username, target.username]
  #     $setOnInsert:
  #       t: 'd'
  #       msgs: 0
  #       ts: now

  #   RocketChat.models.Subscriptions.upsert
  #     rid: rid
  #     $and: [{'u._id': target._id}]
  #   ,
  #     $setOnInsert:
  #       name: source.username
  #       t: 'd'
  #       open: false
  #       alert: false
  #       unread: 0
  #       u:
  #         _id: target._id
  #         username: target.username
  #   return {
  #     t: 'd'
  #     _id: rid
  #   }


# class IrcRoomJoiner
#   constructor: (user, room) ->
#     ircClient = IrcClient.getByUid user._id
#     ircClient.joinRoom room
#     return room


# class IrcRoomLeaver
#   constructor: (user, room) ->
#     ircClient = IrcClient.getByUid user._id
#     ircClient.leaveRoom room
#     return room


# class IrcLogoutCleanUper
#   constructor: (user) ->
#     ircClient = IrcClient.getByUid user._id
#     ircClient.disconnect()
#     return user