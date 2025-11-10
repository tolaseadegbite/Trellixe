module ApplicationHelper
  include Pagy::Frontend

  # returns full title if present, else returns base title
  def full_title(page_title = "")
    base_title = "Trellixe"
    if page_title.blank?
      base_title
    else
      "#{page_title} - #{base_title}"
    end
  end

  def month_offset(date)
    date.beginning_of_month.wday - 1
  end

  def today?(date)
    date == Date.today
  end

  def today_class(date)
    "bg-sky-300" if today?(date)
  end
end
