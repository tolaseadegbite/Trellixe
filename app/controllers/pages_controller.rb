class PagesController < ApplicationController
  skip_before_action :authenticate, only: [ :home, :pricing, :documentation, :help, :privacy, :contact ]

  def home
    if user_signed_in?
      redirect_to dashboard_path
    end
  end

  def pricing
  end

  def documentation
  end

  def help
  end

  def privacy
  end

  def contact
  end
end
