class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :search, :show]
  before_action :set_comment, only: [:show, :edit, :update, :destroy]
  before_action :authorize_owner!, only: [:edit, :update, :destroy]

  def index
    @comments = Comment.includes(:user).recent.limit(100)
    @comment = Comment.new
    @query = nil
  end

  def search
    @query = params[:q].to_s.strip
    @comments =
      if @query.present?
        results = Comment.search(@query)
        Comment.where(id: results.map(&:id)).includes(:user).recent
      else
        Comment.includes(:user).recent.limit(100)
      end
    @comment = Comment.new
    render :index
  end

  def show
  end

  def create
    @comment = current_user.comments.build(comment_params)
    if @comment.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to root_path, notice: "Comment posted." }
      end
    else
      @comments = Comment.includes(:user).recent.limit(100)
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      redirect_to root_path, notice: "Comment updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path, notice: "Comment deleted." }
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def authorize_owner!
    return if @comment.user_id == current_user.id

    redirect_to root_path, alert: "Not allowed."
  end

  def comment_params
    params.require(:comment).permit(:body)
  end
end
