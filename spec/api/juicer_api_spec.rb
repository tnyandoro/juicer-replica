# spec/api/juicer_api_spec.rb
require 'spec_helper'
require 'rack/test'
require_relative '../../lib/api/juicer_api'

RSpec.describe JuicerAPI do
  include Rack::Test::Methods

  def app
    JuicerAPI
  end

  let(:machine) { Domain::JuicerMachine.new }

  before do
    JuicerAPI.set :machine, machine
  end

  after do
    JuicerAPI.set :machine, Domain::JuicerMachine.new
  end

  describe 'GET /health' do
    it 'returns healthy status' do
      get '/health'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)['status']).to eq('healthy')
    end
  end

  describe 'GET /status' do
    it 'returns machine status' do
      get '/status'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body).to include('state', 'metrics', 'juice_tank', 'waste_bin')
    end
  end

  describe 'GET /metrics' do
    it 'returns metrics with efficiency' do
      get '/metrics'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be true
      expect(body).to include('efficiency', 'metrics')
    end
  end

  describe 'POST /start' do
    it 'starts the machine' do
      post '/start'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be true
      expect(machine.running?).to be true
    end
  end

  describe 'POST /feed' do
    it 'processes fruit when machine is running' do
      machine.start
      post '/feed', JSON.generate({
        type: 'orange',
        size: 'medium',
        ripeness: 'ripe',
        weight: 150
      }), 'CONTENT_TYPE' => 'application/json'
      
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be true
      expect(body['juice']).to include('ml')
    end

    it 'fails when machine is not running' do
      post '/feed', JSON.generate({
        type: 'orange',
        size: 'medium',
        ripeness: 'ripe'
      }), 'CONTENT_TYPE' => 'application/json'
      
      expect(last_response.status).to eq(400)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be false
    end
  end

  describe 'POST /clean' do
    it 'cleans the machine' do
      post '/clean'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be true
    end
  end

  describe 'POST /reset' do
    it 'resets the machine to idle' do
      machine.start
      post '/reset'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body['success']).to be true
      expect(body['state']).to eq('idle')
    end
  end
end