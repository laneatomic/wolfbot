# Wolfbot, an IRC administration bot

This is a (sort of janky-written) IRC bot for managing kicks/bans/ops/admin tasks in #werewolf on irc.coldfront.net. It'd be useful for really any channel that you don't want to have regular ops in (such as our usage: a game of Werewolf where players are voiced and the room is moderated during a game. We don't want unrelated chat, even from ops).

## Setup
1. Copy configs/config.yml.sample to configs/config.yml and edit with the correct parameters (nickname, password, etc.)
  - **Note:** The bot needs to join both channels as specified in admin.yml (see step 2), or else none of this will work. This bot does **not** manage permissions inside of a channel - for that, use ChanServ!
2. Copy configs/admin.yml.sample to configs/admin.yml and customize
2. Run `bundle install` to install the dependencies.
3. Run the bot with `ruby wolfbot.rb`

This logs to stdout/stderr and to \<install_dir\>/logs/pisg.log for pisg stats integration. The log format for pisg configuration is `zcbot`.

## How to use
Wolfbot joins two separate channels: The game channel and the admin channel.

### Game Channel
Wolfbot requires Ops in the game channel in order to function correctly. Wolfbot needs to be able to set/remove Op on users.

### Admin channel
Wolfbot doesn't require any special permissions in the Admin channel, however notices must be enabled for the channel (for the :report command). Wolfbot allows certain commands dependant on the access level of the user in the Admin channel.

## Commands

##### Admin/Owner (+a/+q):
Admins and Owners on the channel have access to all commands, including the following special commands:
* `:enforce_opdown`: Removes all ops and halfops from users in the game channel
* `:restart`: Restarts the bot (after configuration changes, code update, etc)

##### Op (+o):
In addition to all Halfop commands, Ops have the following:
* `:opup`: Give ops to self in game channel
* `:opdown`: Remove ops from self in game channel

##### Halfop (+h):
* `:warn <user>[ <message>]`: Sends a signed warning to the game channel, highlighting the warned user, with optional message. This defaults to 'You are being warned for rules violations. Continue and we will take further action.' This prepends the targeted user and appends the warning Op.
* `:kick <user>[ <reason>]`: Kicks a user from the game channel with optional reason.
* `:ban <user>[ <hostmask>]`: Kicks and bans a user from the game channel with optional hostmask. Hostmask will default to full hostmask of the user. Ban mask becomes `*<user>*:*@<hostmask>`.
* `:listbans`: List all bans currently in place in the game channel.

##### All users:
* `:report <username>`: This will report <username>, sending a notice to the admin channel. This command is ratelimited to once every 30 seconds per user to avoid abuse/spam.

All commands can be used anywhere the bot can hear (either channel or via query).
