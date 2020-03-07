# frozen_string_literal: true

require_relative '../../spec_helper'

RSpec.describe RoctoCop::Server do
  def app
    RoctoCop::Server
  end

  describe "GET /is_alive" do
    before(:each) { get "/is_alive" }

    it "returns 200 status code" do
      expect(last_response.status).to eq(200)
    end
  end
end
