emailer = require 'nodemailer'

class Mailer
  constructor: (@opts) ->

  send: (subject, message, cb) ->
    messageData = {
      to: @opts.mailto
      subject: subject
      html: message
      generateTextFromHTML: false
    }
    transport = @getTransport()
    transport.sendMail messageData, cb

  getTransport: () ->
    emailer.createTransport {
      service: 'Gmail'
      auth:
        user: @opts.user
        pass: @opts.password
    },
    {
      from: 'EBK-Scraper <no-reply@horst.schimanski>'
    }

exports = module.exports = Mailer
