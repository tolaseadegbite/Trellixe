class Identity::NamesController < DashboardsController
  before_action :set_user

  def edit
  end

  def update
    respond_to do |format|
      if @user.update(user_params)

        flash.now[:notice] = "Name was successfully updated."
        format.turbo_stream
        # redirect_to root_path, notice: "Your password has been changed"
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash"),
                 status: :unprocessable_entity
        end
      end
    end
  end

  private
    def set_user
      @user = Current.user
    end

    def user_params
      params.permit(:name)
    end
end
