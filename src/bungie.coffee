# Description:
#   Interacts with the Bungie Destiny API.
#
# Commands:
#   dinklebot armory <gamertag> - Returns that players Grimoire Score.
#   dinklebot played <gamertag> - Returns that players Last played character and lightlevel
#   dinklebot inventory <gamertag> - Returns that players Last played character's equipped inventory
#   dinklebot vendor xur - Returns Xur's Inventory or a warning when he isn't available
#
require('dotenv').load()
Deferred = require('promise.coffee').Deferred
DataHelper = require('./bungie-data-helper.coffee')

module.exports = (robot) ->
  dataHelper = new DataHelper
  dataHelper.fetchDefs()

  # Returns a grimoire score for a gamertag
  robot.respond /armory (.*)/i, (res) =>
    playerName = res.match[1]

    getPlayerId(res, playerName).then (playerId) ->
      getGrimoireScore(res, playerId).then (grimoireScore) ->
        res.send playerName+'\'s Grimoire Score is: '+grimoireScore

  # Returns an inventory object of last played character for a gamertag
  robot.respond /played (.*)/i, (res) ->
    playerName = res.match[1]

    getPlayerId(res, playerName).then (playerId) ->
      getLastCharacter(res, playerId).then (response) ->
        res.send 'Guardian '+playerName+' last played on their '+response

  # Returns a list of images equipped on the last character for a gamertag
  robot.respond /inventory (.*)/i, (res) ->
    playerName = res.match[1]

    getPlayerId(res, playerName).then (playerId) ->
      getCharacterId(res, playerId).then (characterId) ->
        getCharacterInventory(res, playerId, characterId).then (response) ->
          items = response.map (item) -> dataHelper.parseItemAttachment(item)

          payload =
            message: res.message
            attachments: items

          robot.emit 'slack-attachment', payload

  # Returns a list of items for xur
  robot.respond /vendor xur/i, (res) ->
    getXurInventory(res).then (response) ->
      if not response.data
        res.send 'Xur isn\'t available yet and i gotta wait til he gets here to build it out'
      else
        # Process Xur's stuffs


# Gets general player information from a players gamertag
getPlayerId = (bot, name) ->
  deferred = new Deferred()
  endpoint = 'SearchDestinyPlayer/1/'+name

  makeRequest bot, endpoint, (response) ->
    foundData = response[0]

    if !foundData
      bot.send 'Guardian '+name+' not found :('
      deferred.reject()
      return

    playerId = foundData.membershipId
    deferred.resolve(playerId)

  deferred.promise

# Gets characterId for last character played
getCharacterId = (bot, playerId) ->
  deferred = new Deferred()
  endpoint = '1/Account/'+playerId

  makeRequest bot, endpoint, (response) ->
    data = response.data
    chars = data.characters
    recentChar = chars[0]

    characterId = recentChar.characterBase.characterId
    deferred.resolve(characterId)

  deferred.promise

# Gets Inventory of last played character
getCharacterInventory = (bot, playerId, characterId) ->
  deferred = new Deferred()
  endpoint = '1/Account/'+playerId+'/Character/'+characterId+'/Inventory'
  params = 'definitions=true'
  rarityColor =
    Uncommon: '#f5f5f5'
    Common: '#2f6b3c'
    Rare: '#557f9e'
    Legendary: '#4e3263'
    Exotic: '#ceae32'

  callback = (response) ->
    definitions = response.definitions.items
    equippable = response.data.buckets.Equippable

    validItems = equippable.map (x) ->
      x.items.filter (item) ->
        item.isEquipped and item.primaryStat

    itemsData = [].concat validItems...

    items = itemsData.map (item) ->
      hash = item.itemHash
      defData = definitions[hash]

      prefix = 'http://www.bungie.net'
      iconSuffix = defData.icon
      itemSuffix = '/en/Armory/Detail?item='+hash

      itemName: defData.itemName
      itemDescription: defData.itemDescription
      itemTypeName: defData.itemTypeName
      rarity: defData.tierTypeName
      color: rarityColor[defData.tierTypeName]
      iconLink: prefix + iconSuffix
      itemLink: prefix + itemSuffix
      primaryStat: item.primaryStat
      stats: item.stats

    deferred.resolve(items)

  makeRequest(bot, endpoint, callback, params)
  deferred.promise

# Gets genral information about last played character
getLastCharacter = (bot, playerId) ->
  deferred = new Deferred()
  endpoint = '/1/Account/'+playerId
  genderTypes = ['Male', 'Female', 'Unknown']
  raceTypes = ['Human', 'Awoken', 'Exo', 'Unknown']
  classTypes = ['Titan', 'Hunter', 'Warlock', 'Unknown']

  makeRequest bot, endpoint, (response) ->
    data = response.data
    chars = data.characters
    recentChar = chars[0]
    charData = recentChar.characterBase
    levelData = recentChar.levelProgression

    level = levelData.level
    lightLevel = charData.powerLevel
    gender = genderTypes[charData.genderType]
    charClass = classTypes[charData.classType]

    phrase = 'level '+level+' '+gender+' '+charClass+', with a light level of: '+lightLevel
    deferred.resolve(phrase)

  deferred.promise

# Gets a players vendors
getXurInventory = (bot) ->
  deferred = new Deferred()
  endpoint = 'Advisors/Xur'
  params = 'definitions=true'
  callback = (response) ->
    deferred.resolve(response)

  makeRequest(bot, endpoint, callback, params)
  deferred.promise

# Gets a players Grimoire Score from their membershipId
getGrimoireScore = (bot, memberId) ->
  deferred = new Deferred()
  endpoint = '/Vanguard/Grimoire/1/'+memberId

  makeRequest bot, endpoint, (response) ->
    score = response.data.score
    deferred.resolve(score)

  deferred.promise

# Sends GET request from an endpoint, needs a success callback
makeRequest = (bot, endpoint, callback, params) ->
  BUNGIE_API_KEY = process.env.BUNGIE_API_KEY
  baseUrl = 'https://www.bungie.net/Platform/Destiny/'
  trailing = '/'
  queryParams = if params then '?'+params else ''
  url = baseUrl+endpoint+trailing+queryParams

  console.log("url")
  console.log(url)

  bot.http(url)
    .header('X-API-Key', BUNGIE_API_KEY)
    .get() (err, response, body) ->
      object = JSON.parse(body)
      callback(object.Response)
