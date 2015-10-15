request = require('request')

class DataHelper
  'fetchDefs': ->
    @fetchStatDefs (error, response, body) =>
      @statDefs = JSON.parse(body)
    @fetchVendorDefs (error, response, body) =>
      @vendorDefs = JSON.parse(body)

  'parseItemsForAttachment': (items) ->
    item.map(item) -> @parseItemAttachment(item)

  'parseItemAttachment': (item) ->
    statFields = @buildStats(item.stats, item.primaryStat) || []

    fallback: item.itemDescription
    title: item.itemName
    title_link: item.itemLink
    color: item.color
    text: item.itemDescription
    thumb_url: item.iconLink
    fields: statFields

  'buildStats': (statsData, primaryData) ->
    defs = @statDefs

    primaryFound = defs[primaryData.statHash] || {}
    primaryStat =
      title: primaryFound.statName
      value: primaryData.value
      short: false

    foundStats = statsData.map(stat) ->
      found = defs[stat.statHash]
      return if not found

      title: found.statName
      value: stat.value
      short: true

    foundStats.unshift primaryStat if primaryFound

    foundStats.filter(x) -> x

  'fetchVendorDefs': (callback) ->
    options =
      method: 'GET'
      url: 'http://destiny.plumbing/raw/mobileWorldContent/en/DestinyStatDefinition.json'
      gzip: true

    request(options, callback)

  'fetchStatDefs': (callback) ->
    options =
      method: 'GET'
      url: 'http://destiny.plumbing/raw/mobileWorldContent/en/DestinyStatDefinition.json'
      gzip: true

    request(options, callback)

module.exports = DataHelper



