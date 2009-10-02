class ObservationRangesController < ApplicationController
  def show
    first = Observation.chronological.first.created_at
    last = Observation.chronological.last.created_at
    respond_to do |format|
      format.json { render :json => { "minDate" => first.to_js, "maxDate" => last.to_js } }
    end
  end
end
