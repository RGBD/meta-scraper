require_relative './main'

Rack::Handler.default.run(MetaScraper::App.new, Port: 3000)
