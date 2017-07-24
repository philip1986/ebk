# redis = require 'redis'
bunyan = require 'bunyan'

config = require './config/dev'

Scraper = require './scraper'
Mailer = require './mailer'
mailer = new Mailer(config.mailer)

# redisClient = redis.createClient()
log = bunyan.createLogger name: 'scraper'

scrapers = []
signatures = {}

config.targets.forEach (target) ->
  log.info "create scraper for #{target.area}"
  scraper = new Scraper target
  scrapers.push scraper

  scraper.on 'error', (err) -> log.error err

  scraper.on 'offer', (offer) ->
    # redisClient.set offer.signature, '1', 'NX', 'EX', config.offerTTL * 60 * 1000, (err, res) ->
      # return log.error err if err
      # check if entry is already scraped
      # return unless res is 'OK'

      return if signatures[offer.signature]
      signatures[offer.signature] = true

      scraper.extOffer offer, (err, extOfffer) ->
        return log.error err if err

        ### IMPLEMENT MATCHING LOGIC HERE ###
        # e.g: return unless extOfffer.size > 100
        ### ###

        subject = "#{extOfffer.district} - #{extOfffer.size} qm - #{extOfffer.titel}"
        mailer.send subject, JSON.stringify(extOfffer, null, 2), (err, info) ->
          log.error err if err
          log.info info

  # scrape right after start
  scraper.scrape()
  # scrap in the configured interval
  setInterval scraper.scrape.bind(scraper), config.scrapInterval * 60 * 1000
