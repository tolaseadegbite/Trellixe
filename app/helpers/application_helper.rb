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

  # Permitted, non-blank Ransack params for filter readouts and counts.
  # A cleared search submits q[field]="" which matches everything but must
  # not render as an active filter.
  def present_filter_params(*keys)
    q = params[:q]
    return {}.with_indifferent_access unless q.is_a?(ActionController::Parameters)

    q.permit(*keys).to_h.reject { |_, v| v.blank? }.with_indifferent_access
  end

  def month_offset(date)
    date.beginning_of_month.wday - 1
  end

  def today?(date)
    date == Date.today
  end

  def today_class(date)
    "bg-algae-300" if today?(date)
  end

  def vapid_public_key
    Rails.application.credentials.dig(:vapid, :public_key) || ENV["VAPID_PUBLIC_KEY"].to_s
  end

  def user_avatar_url(user, size: 80)
    if user.avatar.attached? && user.avatar.attachment&.persisted?
      url_for(user.avatar)
    else
      user.gravatar_url(size: size)
    end
  end

  def gravatar_url(email, size: 80)
    hash = Digest::MD5.hexdigest(email.strip.downcase)
    "https://www.gravatar.com/avatar/#{hash}?s=#{size}&d=mp"
  end
end
