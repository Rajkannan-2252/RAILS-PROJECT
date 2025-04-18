class UptimeController < ApplicationController
    def index
      render json: { status: "Uptime Controller is working!" }
    end
  end
  