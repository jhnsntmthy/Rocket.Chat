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
    @onReceiveMessage = bind @onReceiveMessage
    @onReceiveMessage message
    return message

  onReceiveMessage: (msg) ->
    channel = msg.visitor_id
    now = new Date
    timestamp = now.getTime()
    visitor = @createUserWhenNotExist msg.name, msg.email
    room = @createRoomWhenNotExist(visitor, channel)
    message =
      msg: msg.text
      ts: now
      from: 'visitor'

    console.log '[pubnub] onReceiveMessage -> '.yellow, 'message:', message
    console.log '[pubnub] onReceiveMessage -> '.yellow, 'visitor:', visitor
    console.log '[pubnub] onReceiveMessage -> '.yellow, 'room:', room
    RocketChat.sendMessage visitor, message, room

  createUserWhenNotExist: (name, email) ->
    user = RocketChat.models.Users.findOneByEmailAddress(email)
    unless user
      console.log '[pubnub] createNotExistUser ->'.yellow, 'email:', email
      Meteor.call 'registerVisitor',
        email: email
        name: name
        username: email
      user = RocketChat.models.Users.findOneByEmailAddress(email)
      console.log '[pubnub] createNotExistUser ->'.yellow, 'user created:', user
    Meteor.users.update user._id,
      $set:
        status: 'online'
        username: email
        name: name
    console.log '[pubnub] createNotExistUser ->'.yellow, 'user found:', user
    return user

  createRoomWhenNotExist: (visitor, channel) ->
    console.log '[pubnub] createRoomWhenNotExist -> '.yellow, 'visitor:', visitor.username, 'channel:', channel
    now = new Date()
    RocketChat.models.Rooms.upsert
      _id: channel
    ,
      $set:
        usernames: [visitor.username]
        t: 'c'
      $setOnInsert:
        name: channel
        msgs: 0
        ts: now

    Meteor.call 'alertAgents', channel

    return {
      t: 'c'
      _id: channel
    }

class PubnubSender
  constructor: (message) ->
    name = message.u.username
    timestamp = message.ts.getTime()
    cacheKey = "#{name}#{timestamp}"
    room = RocketChat.models.Rooms.findOneById message.rid, { fields: { name: 1 } }
    if message.from != "visitor"
      PUBNUB.publish({message: {name: name, text: message.msg, from: "rocket.chat" }, channel: room._id})
    console.log '[pubnub] PubnubSender -> '.yellow, message, message.rid
    # ircClient.sendMessage room, message
    return message

Meteor.startup(() -> 
  PUBNUB.subscribe({
    channel_group: 'tenantID',
    callback: bind (msg) ->
      console.log '[pubnub] PubnubReceiver.raw -> '.yellow, msg
      if msg.from != "rocket.chat"
        rec = new PubnubReceiver msg
    , error: bind (msg) ->
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