module SimpleCalendar
  module ViewHelpers

    def calendar(events, options={}, &block)
      raise 'SimpleCalendar requires a block to be passed in' unless block_given?

      opts = default_options
      options.reverse_merge! opts
      events       ||= []
      selected_month = Date.new(options[:year], options[:month])
      current_date   = Time.zone.now.to_date
      range          = build_range selected_month, options
      month_array    = range.each_slice(7).to_a

      if options.has_key?(:inline) && options[:inline] == true
        draw_inline_calendar(selected_month, month_array, current_date, events, options, block)
      else
        draw_calendar(selected_month, month_array, current_date, events, options, block)
      end
    end

    private
    def default_options
      {
          :year           => (params[:year] || Time.zone.now.year).to_i,
          :month          => (params[:month] || Time.zone.now.month).to_i,
          :day            => (params[:day] || Time.zone.now.day).to_i,
          :prev_text      => raw("&laquo;"),
          :next_text      => raw("&raquo;"),
          :start_day      => :sunday,
          :class          => "table table-bordered table-striped calendar",
          :params         => {},
          :time_selector  => "start_time",
          :inline         => false,
          :one_month_only => false
      }
    end
    # Returns array of dates between start date and end date for selected month
    def build_range(selected_month, options)
      if options.has_key?(:one_month_only) && options[:one_month_only] == true
        start_date = selected_month.beginning_of_month
        end_date   = selected_month.end_of_month
      else 
        start_date = selected_month.beginning_of_month.beginning_of_week(options[:start_day])
        end_date   = selected_month.end_of_month.end_of_week(options[:start_day])
      end

      (start_date..end_date).to_a
    end

    def draw_inline_calendar(selected_month, month, current_date, events, options, block)
      tags = []
      today = Time.zone.now.to_date
      previous_month = selected_month.advance :months => -1
      next_month = selected_month.advance :months => 1

      tags << content_tag(:div, :class => "month-name") do 
        content_tag(:a, "#{I18n.t("date.month_names")[selected_month.month]} #{selected_month.year}", :href=> "/repertuary/szukaj?month=#{selected_month.month.to_i}")
      end

      tags << month_link(options[:prev_text], previous_month, options[:params], {:class => "previous-month"})
      content_tag(:div, :class => "#{options[:class]} inline-calendar") do
        day_names = I18n.t("date.abbr_day_names")
        day_names = day_names.rotate((Date::DAYS_INTO_WEEK[options[:start_day]] + 1) % 7)
        tags << content_tag(:div, :class => "day_names") do
          day_names.collect { |name| content_tag :span, name, :class => (selected_month.month == today.month && today.strftime("%a") == name ? "current-day" : nil) }.join.html_safe
        end
        tags << content_tag(:span, :class => "days_list", :'data-month'=>selected_month.month, :'data-year'=>selected_month.year) do

          month.collect do |week|
            content_tag(:span, :class => (week.include?(today) ? "current-week week" : "week")) do

              week.collect do |date|
                day_class = ["day"]
                day_class << "today" if today == date
                day_class << "not-current-month" if selected_month.month != date.month
                day_class << "past" if today > date
                day_class << "selected" if date.day.to_s == params[:day]
                day_class << "future" if today < date
                day_class << "wday-#{date.wday.to_s}" # <- to enable different styles for weekend, etc

                cur_events = day_events(date, events, options[:time_selector])

                day_class << (cur_events.any? ? "events" : "no-events")

                content_tag(:span, :class => day_class.join(" "), :'data-date-iso'=>date.to_s, 'data-date'=>date.to_s.gsub('-', '/')) do
                    spans = []
                    concat content_tag(:a, date.day.to_s, :href=>"/repertuary/szukaj?year=#{(params[:year].blank?) ? date.year.to_s : params[:year]}&month=#{(params[:month].blank?) ? date.month.to_s : params[:month] }&city=#{params[:city]}&title=#{params[:title]}&day=#{date.day.to_s}", :class=>"day_number")

                    if cur_events.empty? && options[:empty_date]
                      concat options[:empty_date].call(date)
                    else
                      #spans << cur_events.collect{ |event| block.call(event) }
                    end

                    spans.join.html_safe
                end #content_tag :td

              end.join.html_safe
            end #content_tag :tr

          end.join.html_safe
        end #content_tag :tbody

        tags << month_link(options[:next_text], next_month, options[:params], {:class => "next-month"})
        tags.join.html_safe
      end #content_tag :table
    end

    # Renders the calendar table
    def draw_calendar(selected_month, month, current_date, events, options, block)
      tags = []
      today = Time.zone.now.to_date
      content_tag(:table, :class => options[:class]) do
        tags << month_header(selected_month, options)
        day_names = I18n.t("date.abbr_day_names")
        day_names = day_names.rotate((Date::DAYS_INTO_WEEK[options[:start_day]] + 1) % 7)
        tags << content_tag(:thead, content_tag(:tr, day_names.collect { |name| content_tag :th, name, :class => (selected_month.month == today.month && today.strftime("%a") == name ? "current-day" : nil)}.join.html_safe))
        tags << content_tag(:tbody, :'data-month'=>selected_month.month, :'data-year'=>selected_month.year) do

          month.collect do |week|
            content_tag(:tr, :class => (week.include?(today) ? "current-week week" : "week")) do

              week.collect do |date|
                td_class = ["day"]
                td_class << "today" if today == date
                td_class << "not-current-month" if selected_month.month != date.month
                td_class << "past" if today > date
                td_class << "future" if today < date
                td_class << "wday-#{date.wday.to_s}" # <- to enable different styles for weekend, etc

                cur_events = day_events(date, events, options[:time_selector])

                td_class << (cur_events.any? ? "events" : "no-events")

                content_tag(:td, :class => td_class.join(" "), :'data-date-iso'=>date.to_s, 'data-date'=>date.to_s.gsub('-', '/')) do
                  content_tag(:div) do
                    divs = []
                    concat content_tag(:div, date.day.to_s, :class=>"day_number")

                    if cur_events.empty? && options[:empty_date]
                      concat options[:empty_date].call(date)
                    else
                      divs << cur_events.collect{ |event| block.call(event) }
                    end

                    divs.join.html_safe
                  end #content_tag :div
                end #content_tag :td

              end.join.html_safe
            end #content_tag :tr

          end.join.html_safe
        end #content_tag :tbody

        tags.join.html_safe
      end #content_tag :table
    end

    # Returns an array of events for a given day
    def day_events(date, events, time_selector)
      events.select { |e| e.send(time_selector).to_date == date }.sort_by { |e| e.send(time_selector) }
    end

    # Generates the header that includes the month and next and previous months
    def month_header(selected_month, options)
      content_tag :h2 do
        previous_month = selected_month.advance :months => -1
        next_month = selected_month.advance :months => 1
        tags = []

        tags << month_link(options[:prev_text], previous_month, options[:params], {:class => "previous-month"})
        tags << "#{I18n.t("date.month_names")[selected_month.month]} #{selected_month.year}"
        tags << month_link(options[:next_text], next_month, options[:params], {:class => "next-month"})

        tags.join.html_safe
      end
    end

    # Generates the link to next and previous months
    def month_link(text, date, params, opts={})
      link_to(text, params.merge({:month => date.month, :year => date.year}), opts)
    end
  end
end
