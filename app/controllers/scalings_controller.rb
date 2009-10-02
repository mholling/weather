class ScalingsController < ApplicationController
  def index
    @scalings = Scaling.scoped({})
    respond_to do |format|
      format.html
      format.js { render :layout => false }
    end
  end
  
  def show
    @scaling = Scaling.find(params[:id])
    date = Date.parse(params[:date])
    respond_to do |format|
      format.json { render :json => { "data" => @scaling.data(date), "options" => @scaling.options(date) } }
    end
  end
end
