Meteor.methods
  registerVisitor: (formData) ->

    userData =
      email: formData.email
      password: 'copilot.visitor.secret.password'

    userId = Accounts.createUser userData

    RocketChat.models.Users.setName userId, formData.name

    return userId