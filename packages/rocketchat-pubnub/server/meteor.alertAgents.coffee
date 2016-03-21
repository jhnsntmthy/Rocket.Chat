Meteor.methods
  alertAgents: (channel) ->

    room = RocketChat.models.Rooms.findOneById channel

    admins = RocketChat.models.Users.find {emails: {$elemMatch: {address: {$regex: new RegExp("@copilotplatform.com$","i") }}}} 
    admins.forEach (admin) -> 
      
      RocketChat.callbacks.run 'beforeJoinRoom', admin, room
      RocketChat.models.Subscriptions.upsert
        rid: channel
        $and: [{'u._id': admin._id}]
      ,
        $setOnInsert:
          name: channel
          t: 'c'
          open: true
          alert: true
          u:
            _id: admin._id
            username: admin.username

      Meteor.defer ->
        RocketChat.callbacks.run 'afterJoinRoom', admin, room

    return true
