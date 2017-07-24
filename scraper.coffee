async = require 'async'
cheerio = require 'cheerio'
request = require 'request'
crypto = require 'crypto'

# @baseUrl = 'https://www.ebay-kleinanzeigen.de'

# {
#   titel: STRING,
#   insertTime: STRING 'HH:MM',
#   district: STRING,
#   postcode: STRING '\d{5}',
#   netRent: INT,
#   href: STRING 'url'
#   street: STRING,
#   insertDate: STRING 'dd.MM.yyyy',
#   id: INT,
#   rooms: INT,
#   size: INT,
#   description: STRING,
#   signature: STRING 'md5'
# }

md5 = (data) -> crypto.createHash('md5').update(data).digest('hex')

class EbkScraper extends require('events').EventEmitter
  ### STATIC CLASS VARIABLES ###
  # throttle requests in oder aviod to many requests prevention
  @requestQueue = async.queue (url, next) ->
      request.get url, (err, res, body) ->
        return next "request #{url} failed -> #{err}" if err
        unless res.statusCode is 200
          return next "request #{url} failed -> #{res.statusCode}"
        next = next.bind(null, err, res, body)
        # delay callback by configured delay
        setTimeout next, EbkScraper.requestDelay
    , 1

  @requestDelay = 200 # ms

  constructor: ({@baseUrl, @targetPath}) ->

  scrape: ->
    self = @

    EbkScraper.requestQueue.push @baseUrl + @targetPath, (err, header, body) =>
      return @emit 'error', err if err

      $ = cheerio.load body

      $('#srchrslt-adtable > li').each ->
        self.emit 'offer',
          titel: $(this).find('.text-module-begin').text()
          insertTime: $(this).find('.aditem-addon')?.html()?.match(/,(.+)$/)?[1]?.replace(/\s/g, '')
          district: $(this).find('.aditem-details')?.html()?.match(/(\n)([\s\wöäü]+)(<br>\n)/g)[1]?.replace(/[\n\s<br>]/g, '')
          postcode: $(this).find('.aditem-details')?.html()?.match(/\n[\s\d]+/g)[2]?.replace(/[\n\s<br>]/g, '')
          netRent:  $(this).find('.aditem-details > strong')?.html()?.match(/(\d+)/)?[1]
          href: self.baseUrl + $(this).find('.text-module-begin > a')?.attr('href')
          signature: md5($(this).text())

  extOffer: (offer, done) ->
    EbkScraper.requestQueue.push offer.href, (err, header, body) =>
      return done(err) if err

      $ = cheerio.load body

      offer.street = $('#street-address').text()?.replace(/\d/, '')
      offer.insertDate = $($('.attributelist--value')[1]).text()
      offer.id = $($('.attributelist--value')[2]).text()
      offer.rooms = $($('.attributelist--value')[3]).find('span').text().replace(/\s/g, "")
      offer.size = $($('.attributelist--value')[4]).find('span').text().replace(/\s/g, "")
      offer.description =  $('p[itemprop="description"]').text()

      done(null, offer)

module.exports = EbkScraper
