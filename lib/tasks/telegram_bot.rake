require 'open-uri'

namespace :telegram_bot do
  desc 'Sets webhook for telegram bot'

  task :set_webhook => :environment do
    res = open('https://api.telegram.org/bot'+ ENV["token"] +'/setWebhook?url=' + ENV["url"] +'/webhooks/telegram_ZYqi1sRosjp3UPFfKZHp').read
    p res
  end

  task :set_default => :environment do
    res = open('https://api.telegram.org/bot'+ ENV["token"] +'/setWebhook?url=https://mozgvabot.herokuapp.com/webhooks/telegram_ZYqi1sRosjp3UPFfKZHp').read
    p res
  end

end
