module PageEventTags
  include Radiant::Taggable
  include PageEvent::CalendarSupport
  

	desc %{
    Will conditionally output its content if the current page has an event.
    
    *Usage:*
    <pre><code><r:event>...</r:event></code></pre>
  }
	tag "event" do |tag|
		tag.expand if tag.locals.page.event_datetime
	end

	desc %{
	  Will output the current event's date. The format attribute accepts the same patterns
	  as Ruby's @strftime@ function (default is @%m/%d/%Y@)
	  
	  *Usage:*
	  <pre><code><r:event:date [format="%m/%d/%Y"]/></code></pre>
	}
	tag "event:date" do |tag|
	  format = (tag.attr['format'] || '%m/%d/%Y')
		tag.locals.page.event_datetime.strftime(format) if tag.locals.page.event_datetime
	end
	
	desc %{
	  Will output the current event's time. The format attribute accepts the same patterns
	  as Ruby's @strftime@ function (default is @%I:%M %p@). 
	  
	  *Usage:*
	  <pre><code><r:event:time [format="%I:%M %p"]/></code></pre>
	}  
	tag "event:time" do |tag|
	  format = (tag.attr['format'] || '%I:%M %p')
	  if tag.locals.page.event_all_day?
	    "All day"
    elsif tag.locals.page.event_datetime
		  tag.locals.page.event_datetime.strftime(format)
	  end
	end
	
	tag "events" do |tag|
		tag.expand
	end
	
  desc %{
    Returns the page with the next occurring event. Inside this tag all page attribute tags are mapped to
    the this page. 
    
    *Usage:*
    <pre><code><r:events:next>...</r:events:next></code></pre>
  }	
	tag "events:next" do |tag|
		if next_event = Page.next_event
      tag.locals.page = next_event
      tag.expand
    end
	end	

  desc %{
    Gives access to next three upcoming events' pages.
    
    *Usage:*
    <pre><code><r:events:upcoming>...</r:events:upcoming></code></pre>
  }
	tag "events:upcoming" do |tag|
    tag.expand
	end

  desc %{
    Cycles through each of the upcoming events. Inside this tag all page attribute tags
    are mapped to the current event's page.
    
    *Usage:*
    <pre><code><r:events:upcoming:each>
     ...
    </r:events:upcoming:each>
    </code></pre>
  }
	tag "events:upcoming:each" do |tag|
	  limit = tag.attr['limit'] || 3
    events = Page.upcoming_events(limit)
		result = []
    events.each do |event|
      tag.locals.event = event
      tag.locals.page = event
      result << tag.expand
    end
    result
	end
	
  tag 'events:upcoming:each:event' do |tag|
    tag.locals.page = tag.locals.event
    tag.expand
  end	
	
  desc %{
    Displays a monthly calendar with any published events displayed on the date the event occurs
    
    *Usage:*
    <pre><code><r:events:upcoming:each>
     ...
    </r:events:upcoming:each>
    </code></pre>
  }
	tag	"events:calendar" do |tag|
		params = tag.locals.page.request.parameters

		begin
			selected_date = params["date"].to_time if params["date"]
		rescue
			logger.error "Date param, #{params["date"]}, did not parse correctly" 
		end
		
		selected_date ||= Time.now
		
		prev_month = selected_date - 1.month
		next_month = selected_date + 1.month		
		events_by_date = events_for(selected_date)
		
		Date::MONTHNAMES[selected_date.mon]

    html = Builder::XmlMarkup.new
    table = html.table(:class => "calendar", :border => 0, :cellspacing => 0, :cellpadding => 0) do
      html.thead do
      	html.tr(:class => "monthHeader") do
      		html.th(:class => "monthLink") do
      			html.a(:href => "", :title => Date::MONTHNAMES[prev_month.mon], :onclick => date_onclick(prev_month.to_s(:db))) { |x| x << "&#171;"}
      		end
					html.th("#{Date::MONTHNAMES[selected_date.mon]} #{selected_date.year}", :class => "monthName", :colspan => 5) 
	      		html.th(:class => "monthLink") do
	      			html.a(:href => "", :title => Date::MONTHNAMES[next_month.mon], :onclick => date_onclick(next_month.to_s(:db))) { |x| x << "&#187;" }
	      		end
	      	end
				html.tr(:class => "dayName") do
					# This calendar currently only supports starting on Sunday and ending on Saturday
					Date::DAYNAMES.each do |day|
						html.th(:scope => "col") do
							html.abbr(day[0..1], :title => day) 
						end						
					end
				end
			end

			html.tbody do
				calendar_weeks(selected_date).each do |week|
					html.tr do
						week.each do |day|
							html_classes = ""
							add_html_class(html_classes,"otherMonth") unless day.month == selected_date.month
							add_html_class(html_classes,"weekend") if weekend?(day) 
							add_html_class(html_classes,"today") if today?(day)

							html.td(:class => html_classes) do
								html.div(:class => "day") do
									html.div(day.mday, :class => "date")
									
									if events_by_date.has_key?(day)
										html.div(:class => "eventContainer") do
											events_by_date[day].each do |event|
												html.p(:class => "event") do
													html.span(event.event_datetime.strftime("%I:%M %p"), :class => "time") 
													html.a(event.title, :href => event.url) 	
												end
											end
										end						
									end			 
								end
							end	
						end						
					end
				end
			end
    end		
	end
end