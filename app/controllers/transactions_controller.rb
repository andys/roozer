class PathsController < ApplicationController
  respond_to :json
  before_filter :cleanup_path
  
  def show
    path = Path.find(@path)
    respond_with(path)
  end
  
  def create
    path = Path.create(params.merge(name: @path))
    respond_with(path)
  end

  def update
    path = Path.find(@path)
    path.update_attributes(params)
    respond_with(path)
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
    @path = '/' + params[:path].to_s.split(/\/+/).select(&:present?).join('/')
  end
end
