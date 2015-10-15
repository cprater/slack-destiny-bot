slack-destiny-bot
==============

A slack-specific hubot integration to interact (readonly) with the Bungie Destiny API.

A hubot slack adapter is needed to operate.

This is mostly practice in me learning coffeescript and messing around with a hubot integration for my friends slack domain. So, no pull requests or comments.

There are a few commands that return information about players, at this point it's mostly gear lookups by a gamertag (only for xbox one at this time).

COMMANDS
---

* `<bot-name> armory <gamertag>` - Returns that players Grimoire Score.
* `<bot-name> played <gamertag>` - Returns that players Last played character and lightlevel
* `<bot-name> inventory <gamertag>` - Returns that players Last played character's equipped inventory
* `<bot-name> vendor xur` - Returns Xur's Inventory or a warning when he isn't available

## Installation
You will need to have [hubot](https://hubot.github.com/) setup with the [slack-adapter](https://github.com/slackhq/hubot-slack)

Run the following command 

    $ npm install slack-destiny-bot

Then to make sure the dependencies are installed:

    $ npm install

To enable the script, add a `slack-destiny-bot` entry to the `external-scripts.json`
file (you may need to create this file).

    ["slack-destiny-bot"]

You will need to get a `BUNGIE_API_KEY` which you can get [here](https://www.bungie.net/en/User/API)

You will need to set the key as a config variable wherever you plan to host your hubot
Mine is hosted on heroku so I use the following command

    heroku config:set BUNGIE_API_KEY=<your-key>
