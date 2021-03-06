class Admin::CategoriesController < AdminController

  def index

  end

  def show
    @category = @categories.find(params[:id])
    @posts = current_user.posts.where(category: @category)
    @posts = @posts.page(params[:page])
  end

  def edit
    @category = @categories.find(params[:id])
    render :index
  end

  def update
    @category = @categories.find(params[:id])
    category_name = @category.name

    if @category.update_attributes(category_params)
      flash[:notice] = "你已经成功修改了分类 #{category_name}。"
      redirect_to action: :index
    else
      flash[:error] = "修改分类 #{category_name} 失败。"
      render :index
    end
  end

  def create
    @category = Category.new(category_params)
    @category.user = current_user

    respond_to do |format|
      if @category.save
        format.json { head :no_content }
      else
        format.json { render json: draw_errors_message(@category), status: 403 }
      end
    end
  end

  def destroy
    @category = @categories.find(params[:id])
    category_name = @category.name
    if @category.posts.size > 0
      js_alert("分类 #{category_name} 下还有文章，请先转移到其它分类！")
    elsif @category.codes.size > 0
      js_alert("分类 #{category_name} 下还有代码收藏，请先转移到其它分类！")
    else
      @category.destroy
      flash[:notice] = "成功删除分类 #{category_name}。"
      js_reload
    end
  end

  private
  def category_params
    params.require(:category).permit(:user_id, :name, :description)
  end


end
