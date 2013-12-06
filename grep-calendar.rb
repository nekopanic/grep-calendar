require 'sinatra/base'
require 'restclient'
require 'icalendar'
require 'date'

class GrepCalendar < Sinatra::Base
  include Icalendar

  get '/grep.ical' do
    raise "Usage: /search?ical=http://foo/bar&query=term" unless params[:ical] && params[:query]

    source = RestClient.get(params[:ical])

    calendars = Icalendar.parse(source).map do |src|
      calendar = Calendar.new.tap do |c|
        c.events = src.events.find_all { |e| e.summary.include? params[:query] }
      end
    end

    response.headers['Content-Type'] = 'text/calendar'
    calendars.to_ical		
  end

end
