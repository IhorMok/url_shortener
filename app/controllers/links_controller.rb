class LinksController < ApplicationController
  skip_forgery_protection

  before_action :set_link, only: %i[show edit update destroy]
  before_action :check_if_editable, only: %i[edit update destroy]

  def index
    @pagy, @links = pagy Link.recent_first
    @link ||= Link.new
    respond_to do |format|
      format.html
      format.json do
        mapped_links = @links.map do |link|
          {
            id: link.to_param,
            url: link.url,
            title: link.title,
            description: link.description
          }
        end
        render json: mapped_links
      end
    end
  rescue Pagy::OverflowError
    redirect_to root_path
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @link }
    end
  end

  def create
    @link = Link.new(link_params.with_defaults(user: current_user))
    if @link.save
      respond_to do |format|
        format.html { redirect_to root_path }
        format.turbo_stream { render turbo_stream: turbo_stream.prepend('links', @link) }
        format.json { render json: @link }
      end
    else
      index
      render :index, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @link.update(link_params)
      respond_to do |format|
        format.html { redirect_to @link }
        format.json { render json: @link }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @link.errors, status: :bad_request }
      end
    end
  end

  def destroy
    @link.destroy!
    respond_to do |format|
      format.html { redirect_to root_path, notice: 'Link has been deleted.' }
      format.json { head :no_content }
    end
  end

  private

  def link_params
    params.require(:link).permit(:url)
  end

  def check_if_editable
    return if @link.editable_by?(current_user)

    redirect_to @link, alert: "You aren't allowed to do that."
  end
end
