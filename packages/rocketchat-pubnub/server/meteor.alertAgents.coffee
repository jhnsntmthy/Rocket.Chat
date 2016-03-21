Meteor.methods
  alertAgents: (rid) ->

    room = RocketChat.models.Rooms.findOneById rid

    if not room?
      console.log 'No channel with this id'.red
      return

    now = new Date()

    # Check if user is already in room
    # subscription = RocketChat.models.Subscriptions.findOneByRoomIdAndUserId rid, Meteor.userId()
    # if subscription?
    #   return

    user = RocketChat.models.Users.findOne {username: 'tim.johnson'}

    RocketChat.callbacks.run 'beforeJoinRoom', user, room

    RocketChat.models.Rooms.addUsernameById rid, user.username

    RocketChat.models.Subscriptions.createWithRoomAndUser room, user,
      ts: now
      open: true
      alert: true
      unread: 1

    RocketChat.models.Messages.createUserJoinWithRoomIdAndUser rid, user,
      ts: now

    Meteor.defer ->
      RocketChat.callbacks.run 'afterJoinRoom', user, room

    return true
