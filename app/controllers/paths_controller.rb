class PathsController < ApplicationController
  skip_before_filter :verify_authenticity_token
  respond_to :json
  before_filter :cleanup_path
  rescue_from Exception, :with => :render_error
  rescue_from ActiveRecord::RecordNotFound, :with => :render_not_found
  rescue_from ActionController::RoutingError, :with => :render_not_found
  rescue_from ActionController::UnknownController, :with => :render_not_found
  rescue_from ActionController::UnknownAction, :with => :render_not_found

  
  def show
    path = Path.find(@path)
    respond_with(path)
  end

  def create
    path = Path.create(params.merge(name: @path))
    respond_with(path)
  end

  def update
    begin
      path = Path.find(@path)
      path.update_attributes(params)
      respond_with(path)
    rescue ActiveRecord::RecordNotFound
      create
    end
  end
  
  def destroy
    path = Path.find(@path)
    path.destroy
    
    respond_to do |format|
      format.json { head :ok }
    end
  end

protected
  def cleanup_path
    @path = '/' + params[:p].to_s.split(/\/+/).select(&:present?).join('/')
  end
    

  private

  def render_not_found(exception)
    #logger.info(exception) # for logging 
    render json: {:error => "404"}, status: 404
  end

  def render_error(exception)
    #logger.info(exception) # for logging
    respond_to do |format|
      render json: {:error => "500"}, status: 500
    end
  end
                      
end
