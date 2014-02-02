require 'restclient'
require 'addressable/uri'
require 'icalendar'
require 'date'

require 'sinatra/base'
require 'json'

class GrepCalendar < Sinatra::Base
  include Icalendar

  set :public_folder, File.dirname(__FILE__) + '/public'
  set :show_exceptions, false

  get '/' do
    redirect '/index.html'
  end

  get '/calendar.?:format?' do |format|
    args = { url: params[:url] }
    (args[:query] = params[:query]) if params[:query]
    calendars = grep_calendar(args)

    case format
    when 'json'
      response.headers['Content-Type'] = 'application/json'
      url = "#{request.base_url}/calendar.ical?#{request.query_string}"
      c = calendars.map { |cal| cal.events.map { |event| { time: event.dtstamp.strftime('%B %e, %l%P'), summary: event.summary } } }
      { calendars: c, url: url }.to_json
    when 'ical'
      response.headers['Content-Type'] = 'text/calendar'
      calendars.to_ical
    end
  end

  error do
    response.headers['Content-Type'] = 'application/json'
    { exception: env['sinatra.error'] }.to_json
  end

  def grep_calendar(args = {})
    raise 'url required' if !args.include?(:url) || args[:url].nil? || args[:url].strip.empty?
    raise 'http or webcal URL required' unless args[:url].start_with?('http') || args[:url].start_with?('webcal')
    url = args[:url].strip
    raise 'query required' if args.include?(:query) && (args[:query].nil? || args[:query].strip.empty?)
    query = args[:query]

    url = Addressable::URI.parse(url)
    url.scheme = 'http' if url.scheme == 'webcal'
    source = RestClient.get(url.normalize.to_str)

    calendars = Icalendar.parse(source)
    if query.nil? || query.empty?
      calendars
    else
      calendars.map do |src|
        calendar = Calendar.new.tap do |c|
          c.events = src.events.find_all { |e| e.summary.downcase.include?(query.downcase) }
        end
      end
    end
  end
end
