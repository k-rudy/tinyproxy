require 'spec_helper'
require_relative '../../tiny_proxy/cache'

describe TinyProxy::Cache do
  before do
    @cache = TinyProxy::Cache
  end

  describe "lazy initialization" do
    it "should initialize uri_history with empty array" do
      @cache.send(:uri_history).must_equal([])
    end

    it "should initialize headers with empty hash" do
      @cache.send(:headers).must_equal({})
    end

    it "should initialize bodies with empty hash" do
      @cache.send(:bodies).must_equal({})
    end
  end
end
