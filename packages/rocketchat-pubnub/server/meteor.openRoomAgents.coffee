Meteor.methods
  openRoomAgents: (rid) ->
    tim = RocketChat.models.Users.findOneByUsername 'tim.johnson'
    RocketChat.models.Subscriptions.openByRoomIdAndUserId rid, tim._id
