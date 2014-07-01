require 'test_helper'

describe "Redis::Store::Strategy::Json" do
  def setup
    @store = Redis::Store.new :strategy => :json
    @rabbit = OpenStruct.new :name => "bunny"
    @white_rabbit = OpenStruct.new :color => "white"
    @store.set "rabbit", @rabbit
    @store.del "rabbit2"
  end

  def teardown
    @store.quit
  end

  it "unjsons on get" do
    @store.get("rabbit").must_equal(@rabbit)
  end

  it "jsons on set" do
    @store.set "rabbit", @white_rabbit
    @store.get("rabbit").must_equal(@white_rabbit)
  end

  it "doesn't unjson on get if raw option is true" do
    @store.get("rabbit", :raw => true).must_equal("{\"^o\":\"OpenStruct\",\"table\":{\":name\":\"bunny\"}}")
  end

  it "doesn't json set if raw option is true" do
    @store.set "rabbit", @white_rabbit, :raw => true
    @store.get("rabbit", :raw => true).must_equal(%(#<OpenStruct color="white">))
  end

  it "doesn't unjson if get returns an empty string" do
    @store.set "empty_string", ""
    @store.get("empty_string").must_equal("")
    # TODO use a meaningful Exception
    # lambda { @store.get("empty_string").must_equal("") }.wont_raise Exception
  end

  it "doesn't set an object if already exist" do
    @store.setnx "rabbit", @white_rabbit
    @store.get("rabbit").must_equal(@rabbit)
  end

  it "jsons on set unless exists" do
    @store.setnx "rabbit2", @white_rabbit
    @store.get("rabbit2").must_equal(@white_rabbit)
  end

  it "doesn't json on set unless exists if raw option is true" do
    @store.setnx "rabbit2", @white_rabbit, :raw => true
    @store.get("rabbit2", :raw => true).must_equal(%(#<OpenStruct color="white">))
  end

  it "jsons on set expire" do
    @store.setex "rabbit2", 1, @white_rabbit
    @store.get("rabbit2").must_equal(@white_rabbit)
    sleep 2
    @store.get("rabbit2").must_be_nil
  end

  it "doesn't unjson on multi get" do
    @store.set "rabbit2", @white_rabbit
    rabbit, rabbit2 = @store.mget "rabbit", "rabbit2"
    rabbit.must_equal(@rabbit)
    rabbit2.must_equal(@white_rabbit)
  end

  it "doesn't unjson on multi get if raw option is true" do
    @store.set "rabbit2", @white_rabbit
    rabbit, rabbit2 = @store.mget "rabbit", "rabbit2", :raw => true
    rabbit.must_equal("{\"^o\":\"OpenStruct\",\"table\":{\":name\":\"bunny\"}}")
    rabbit2.must_equal("{\"^o\":\"OpenStruct\",\"table\":{\":color\":\"white\"}}")
  end

  describe "binary safety" do
    it "jsons objects" do
      utf8_key = [51339].pack("U*")
      ascii_rabbit = OpenStruct.new(:name => [128].pack("C*"))

      @store.set(utf8_key, ascii_rabbit)
      @store.get(utf8_key).inspect.must_equal(ascii_rabbit.inspect)
    end

    it "gets and sets raw values" do
      utf8_key = [51339].pack("U*")
      ascii_string = [128].pack("C*")

      @store.set(utf8_key, ascii_string, :raw => true)
      @store.get(utf8_key, :raw => true).bytes.to_a.must_equal(ascii_string.bytes.to_a)
    end

    it "jsons objects on setnx" do
      utf8_key = [51339].pack("U*")
      ascii_rabbit = OpenStruct.new(:name => [128].pack("C*"))

      @store.del(utf8_key)
      @store.setnx(utf8_key, ascii_rabbit)
      @store.get(utf8_key).inspect.must_equal(ascii_rabbit.inspect)
    end

    it "gets and sets raw values on setnx" do
      utf8_key = [51339].pack("U*")
      ascii_string = [128].pack("C*")

      @store.del(utf8_key)
      @store.setnx(utf8_key, ascii_string, :raw => true)
      @store.get(utf8_key, :raw => true).bytes.to_a.must_equal(ascii_string.bytes.to_a)
    end
  end if defined?(Encoding)
end
