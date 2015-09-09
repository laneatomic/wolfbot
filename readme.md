# Wolfbot, an IRC administration bot

This is a (sort of janky-written) IRC bot for managing kicks/bans/ops/admin tasks in #werewolf on irc.coldfront.net. It'd be useful for really any channel that you don't want to have regular ops in (such as our usage: a game of Werewolf where players are voiced and the room is moderated during a game. We don't want unrelated chat, even from ops). Currently it is hard-coded to use #werewolf and #werewolfops for its channels. Configuration coming Soon(tm).

## Setup
1. Copy configs/config.yml.sample to configs/config.yml and edit with the correct parameters (nickname, password, etc.)
2. For now, edit the following two variables in lib/plugins/admin.rb (lines 33-34):  
    @game_channel = '#wolfbot'
    @admin_channel = '#wolfbotops'
2. Run `bundle install` to install the dependencies.
3. Run the bot with `ruby wolfbot.rb`

This logs to stdout/stderr and to \<install_dir\>/logs/pisg.log for pisg stats integration. The log format for pisg configuration is `zcbot`.
