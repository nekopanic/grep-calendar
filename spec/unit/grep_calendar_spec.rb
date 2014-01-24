require 'spec_helper'

describe GrepCalendar do

  subject(:gc) { GrepCalendar.new! }

  let(:calendar) { Icalendar::Calendar.new.to_ical } 

  describe '#grep_calendar' do
    context 'required arguments' do

      it 'requires :url'do
        expect{gc.grep_calendar()}.to raise_error('url required')
      end

      it 'requires :url to be non-blank'do
        expect{gc.grep_calendar(:url => '')}.to raise_error('url required')
        expect{gc.grep_calendar(:url => ' ')}.to raise_error('url required')
      end

      it 'requires :url to be http or webcal'do
        expect{gc.grep_calendar(:url => 'ftp://example.com')}.to raise_error('http or webcal URL required')
      end

      it 'requires :query to be non-blank'do
        expect{gc.grep_calendar(url: 'http://example.com', query: nil)}.to raise_error('query required')
        expect{gc.grep_calendar(url: 'http://example.com', query: '')}.to raise_error('query required')
        expect{gc.grep_calendar(url: 'http://example.com', query: ' ')}.to raise_error('query required')
      end

    end

    context 'url retrieval' do

      it 'accepts HTTP URLs' do
        request = stub_request(:get, "http://example.com/")
          .with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'})
          .to_return(:status => 200, :body => calendar, :headers => {})

        expect(gc.grep_calendar(url: 'http://example.com/').to_ical).to eq(calendar)
        expect(request).to have_been_requested
      end

      it 'converts webcal URLs to HTTP' do
        request = stub_request(:get, "http://example.com/")
          .with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'})
          .to_return(:status => 200, :body => calendar, :headers => {})

        expect(gc.grep_calendar(url: 'webcal://example.com/').to_ical).to eq(calendar)
        expect(request).to have_been_requested
      end
      
    end

    context 'basic calendar parsing' do

      let(:calendar) do
        calendar = Icalendar::Calendar.new
        calendar.event do
          dtstart       Date.new(2005, 04, 29)
          dtend         Date.new(2005, 04, 28)
          summary     "Meeting with the man."
          description "Have a long lunch meeting and decide nothing..."
          klass       "PRIVATE"
        end

        # Need to rinse it to make the parse/to_ical loop symmetrical
        Icalendar.parse(calendar.to_ical).to_ical
      end

      it 'deals with simple calendars' do
        request = stub_request(:get, "http://example.com/")
          .with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'})
          .to_return(:status => 200, :body => calendar, :headers => {})

        expect(gc.grep_calendar(url: 'http://example.com/').to_ical).to eq(calendar)
        expect(request).to have_been_requested
      end

    end

    context 'basic calendar filtering' do

      let(:grepped_calendar) do
        cal = Icalendar::Calendar.new
        cal.event do
          dtstart       Date.new(2005, 04, 29)
          dtend         Date.new(2005, 04, 28)
          summary     "Meeting with Kate."
          description "Have a long lunch meeting and decide nothing..."
          klass       "PRIVATE"
        end
        Icalendar.parse(cal.to_ical).to_ical
      end

      let(:calendar) do
        cal = Icalendar.parse(grepped_calendar)[0]
        cal.event do
          dtstart       Date.new(2005, 04, 29)
          dtend         Date.new(2005, 04, 28)
          summary     "Meeting with the man."
          description "Have a long lunch meeting and decide nothing..."
          klass       "PRIVATE"
        end
        Icalendar.parse(cal.to_ical).to_ical
      end

      it 'does a little filtering' do
        request = stub_request(:get, "http://example.com/")
          .with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate'})
          .to_return(:status => 200, :body => calendar, :headers => {})

        expect(gc.grep_calendar(url: 'http://example.com/', :query => 'kate').to_ical).to eq(grepped_calendar)
        expect(request).to have_been_requested
      end
    end
  end

end
