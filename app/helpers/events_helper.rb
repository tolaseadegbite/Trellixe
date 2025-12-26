module EventsHelper
  def format_full_event_datetime_range(event)
    start_dt = event.starts_at
    end_dt = event.ends_at

    # Format the date part
    start_date_str = start_dt.strftime("%A, %B %d, %Y")

    # Format the time part (with a more robust, zero-stripping method)
    start_time_str = start_dt.strftime("%l:%M %p").strip
    end_time_str = end_dt.strftime("%l:%M %p").strip

    # CASE 1: The event starts and ends on the same day.
    if start_dt.to_date == end_dt.to_date
      "#{start_date_str} • #{start_time_str} - #{end_time_str}"

    # CASE 2: The event spans multiple days.
    else
      end_date_str = end_dt.strftime("%A, %B %d, %Y")
      "From #{start_date_str} at #{start_time_str} to #{end_date_str} at #{end_time_str}"
    end
  end
end
