class ChartsController < ApplicationController
  def show
    @scaling = Scaling.find(params[:scaling_id])
    date = Date.parse(params[:date])
    respond_to do |format|
      format.json { render :json => { "data" => @scaling.data(date), "options" => @scaling.options(date) } }
    end
  end
end
