require 'http'
require 'json'
require 'logger'
require 'pry'
require 'sinatra'

module MetaScraper
  SOURCE_URI_BASE = 'https://takehome.io/'.freeze
  SOURCES = %w[twitter facebook instagram].freeze

  module Scraper
    DEFAULT_TRY = 3
    DEFAULT_TIMEOUT = 10

    @logger = Logger.new(STDOUT)

    def self.call(url, fallback: :raise, try: DEFAULT_TRY, timeout: DEFAULT_TIMEOUT)
      @logger.info "start(#{try}): #{url}"
      response = HTTP.timeout(timeout).get(url)
      raise "unexpected status code: #{response.code}, '#{response.body.first[0, 100]}...'" unless response.code == 200

      result = JSON.parse(response.to_s)
      @logger.info "success(#{try}): #{url}"
      result
    rescue StandardError => e
      @logger.info "error(#{try}): #{url}: #{e}"
      if try.positive?
        try -= 1
        retry
      end
      fallback == :raise ? raise : fallback
    end
  end

  class App < Sinatra::Base
    get '/' do
      response = SOURCES.map do |x|
        Thread.new do
          [x, Scraper.call(SOURCE_URI_BASE + x, fallback: nil)]
        end
      end.map(&:value).to_h
      JSON.pretty_generate(response)
    end
  end
end
