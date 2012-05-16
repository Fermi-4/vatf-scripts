require File.dirname(__FILE__)+'/default_module'

include StarterwareDefault

def setup
  self.as(StarterwareDefault).setup
end

def run
  self.as(StarterwareDefault).run
end

def clean
  self.as(StarterwareDefault).clean
end
