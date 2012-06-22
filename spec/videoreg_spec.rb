require 'spec_helper'

describe Videoreg::Registrar do

  it "should be configurable" do

    subject.configure do |c|
      c.resolution = '640x480'
      c.command = 'test command #{resolution}'
    end

    subject.resolution.should == '640x480'
    subject.cmd.should == 'test command 640x480'

  end
end