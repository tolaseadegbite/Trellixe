class TagsController < DashboardsController
  before_action :set_tag, only: [ :destroy ]

  def index
    @tags = Current.account.tags.order(:name)
    @tag = Tag.new
  end

  def create
    @tag = Current.account.tags.new(tag_params)
    respond_to do |format|
      if @tag.save
        flash.now[:notice] = "Tag created."
        format.turbo_stream
        format.html { redirect_to tags_path, notice: "Tag created." }
      else
        @tags = Current.account.tags.order(:name)
        flash.now[:alert] = @tag.errors.full_messages.to_sentence
        format.turbo_stream { render :create, status: :unprocessable_entity }
        format.html { render :index, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @tag.destroy
    @tags_empty = Current.account.tags.none?
    respond_to do |format|
      flash.now[:notice] = "Tag removed."
      format.turbo_stream
      format.html { redirect_to tags_path, notice: "Tag removed." }
    end
  end

  private

  def set_tag
    @tag = Current.account.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
