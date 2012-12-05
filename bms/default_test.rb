require File.dirname(__FILE__)+'/default_module'

include BmsDefault

def setup
  self.as(BmsDefault).setup
end

def run
  self.as(BmsDefault).run
end

def clean
  self.as(BmsDefault).clean
end
