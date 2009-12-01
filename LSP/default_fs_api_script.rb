# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/default_fs_api_module'
include LspFSTestScript

def setup
  self.as(LspFSTestScript).setup
end

def run
  self.as(LspFSTestScript).run
end

def clean
  self.as(LspFSTestScript).clean
end


