# spec/api/metrics_spec.rb
require 'spec_helper'
require 'rack/test'
require_relative '../../lib/api/juicer_api'
require_relative '../../lib/infrastructure/metrics'

RSpec.describe 'Prometheus Metrics' do
  include Rack::Test::Methods

  def app
    JuicerAPI
  end

  before do
    Infrastructure::Metrics.reset!
    JuicerAPI.set :machine, Domain::JuicerMachine.new
  end

  after do
    JuicerAPI.set :machine, Domain::JuicerMachine.new
  end

  describe 'GET /metrics' do
    it 'returns 200 status' do
      get '/metrics'
      expect(last_response.status).to eq(200)
    end

    it 'returns text/plain content type' do
      get '/metrics'
      expect(last_response.content_type).to include('text/plain')
    end

    it 'includes HELP comments' do
      get '/metrics'
      expect(last_response.body).to include('# HELP')
    end

    it 'includes TYPE declarations' do
      get '/metrics'
      expect(last_response.body).to include('# TYPE')
    end

    it 'includes juicer metrics' do
      get '/metrics'
      body = last_response.body
      expect(body).to include('juicer_')
    end

    it 'tracks fruit processing' do
      machine = Domain::JuicerMachine.new
      machine.start
      JuicerAPI.set :machine, machine
      
      post '/feed', JSON.generate({
        type: 'orange',
        size: 'medium',
        ripeness: 'ripe',
        weight: 150
      }), 'CONTENT_TYPE' => 'application/json'
      
      get '/metrics'
      body = last_response.body
      expect(body).to include('juicer_fruits_processed')
    end

    it 'tracks machine state' do
      get '/metrics'
      body = last_response.body
      expect(body).to include('juicer_machine_state')
    end
  end
end