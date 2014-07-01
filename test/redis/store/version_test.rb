require 'test_helper'

describe Redis::Store::VERSION do
  it 'returns current version' do
    Redis::Store::VERSION.must_equal '0.0.1'
  end
end
