require 'spec_helper'

describe Videoreg do
  it "should instantiates" do
    lambda { Videoreg.new }.should_not raise_error
  end
end