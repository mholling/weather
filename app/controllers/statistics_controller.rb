class StatisticsController < ApplicationController
  def show
    @scaling = Scaling.for(Statistic).find(params[:scaling_id])
    date = Date.parse(params[:date])
    respond_to do |format|
      format.json { render :json => { :message => @scaling.statistic.name } }
    end
  end
end
