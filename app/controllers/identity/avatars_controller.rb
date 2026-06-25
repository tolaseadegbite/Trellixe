class Identity::AvatarsController < DashboardsController
  before_action :set_user

  def edit
  end

  def update
    if params[:avatar].blank?
      redirect_back fallback_location: edit_identity_avatar_path, alert: "Please select an image to upload."
      return
    end

    respond_to do |format|
      if @user.update(avatar: params[:avatar])
        flash.now[:notice] = "Avatar updated."
        format.turbo_stream
      else
        flash.now[:alert] = @user.errors.full_messages.to_sentence
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages", partial: "shared/flash"),
                 status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @user.avatar.purge
    redirect_to edit_identity_avatar_path, notice: "Avatar removed."
  end

  private

  def set_user
    @user = Current.user
  end
end
