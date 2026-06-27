class TagsController < DashboardsController
  before_action :set_tag, only: [ :destroy ]

  def index
    @tags = Current.account.tags.order(:name)
    @tag = Tag.new
  end

  def create
    @tag = Current.account.tags.new(tag_params)
    if @tag.save
      redirect_to tags_path, notice: "Tag created."
    else
      @tags = Current.account.tags.order(:name)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @tag.destroy
    redirect_to tags_path, notice: "Tag removed."
  end

  private

  def set_tag
    @tag = Current.account.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name)
  end
end
