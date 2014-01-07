require "find"
require "rexml/document"
require File.dirname(__FILE__)+'/SKIP_TESTCASES'

include REXML

class TestImporter
  attr_reader :rootDir, :pURL
  def initialize
    @time = Time.new
    @pURL = "http://arago-project.org/git/projects/test-automation/ltp-ddt.git"
    @rootDir
  end
  
  def clone_project
    d = `pwd`
    d.strip!
    puts "Root directory is: #{d}"
    new_dir = @time.strftime("%Y-%m-%d_%H:%M:%S")
    @rootDir = File.join(d, new_dir)
    puts "Cloning repo at #{@pURL}"
    `mkdir -p #{@rootDir}`
    `cd #{@rootDir}; git clone #{@pURL}`
    if $?.to_i != 0
      puts "failed to clone #{@pURL}"
      exit
    end
  end
  
  def find_test_scenarios
    find_files(File.join(@rootDir,'ltp-ddt', 'runtest', 'ddt'))
  end
  
  def find_files(dir, name=/[^\.].+/)
    list =[]
    Find.find(dir) do |path|
      if FileTest.directory?(path)
        if File.basename(path)[0] == ?.
          Find.prune       # Don't look any further into this directory
        else
          next
        end
      else
        
        case name
          when String
            list << path if File.basename(path) == name
          when Regexp
            list << path if (File.basename(path) =~ name and !(File.basename(path) =~ /TEMPLATE/) and !(File.basename(path) =~ /Makefile/i) and !(File.basename(path) =~ /^\./))   
        else
          raise ArgumentError
        end
      end
    end
    list
  end
  
  def exec_cmd(cmd) 
    x = `cmd`
    if $?.to_i != 0
      puts "#{cmd} returned error."
      puts "#{cmd} stdout:\n#{x}"
    end
  end
  
  # Process test scenario file and returns array of Hash
  # Each Hash represents a test case
  def process_test_scenario(file)
    common = {}
    data = File.open(file, 'r').read
    begin
      if /^\s*#\s*@name\s+(.+?)#/m =~ data
        common['name'] = $1
      else
        raise "Invalid test scenario file #{file}"
      end
      if /^\s*#\s*@desc\s+(.+?)(?=\s*^#\s*@|^\w+)/m =~ data
        common['desc'] = $1.gsub(/#/,'\n')
      else
        raise "Invalid test scenario file #{file}"
      end
    rescue Exception 
      puts "**** WARNING ****"
      puts "Test scenario file #{File.basename(file)} does not have mandatory @name and @desc annotations"
      return []
    end
  
    if /^\s*#\s*@setup_requires\s+([-\w]+)$/ =~ data
      common['setup_requires'] = $1.strip
    end
    testcases = []
    data.scan(/^\s*(\w+_\w+_[\w\-]+)/) {|tag|
      next if skip_test?(tag[0])
      begin
        scenario_file = file.match(/.+ltp-ddt\/runtest\/(.+)$/).captures[0]
        tag_data = tag[0].match(/^(\w+?)_(\w+?)_([a-zA-Z]+)/).captures
        raise "Invalid tag. Scope is not S, M or L" if !(tag_data[1].match(/[SML]/))
        testcase = {
          'name' => tag[0],
          'desc' => tag[0] + '<br/>' + common['name'] + '<br/>' + common['desc'],
          'testsuite' => tag_data[0],
          'scope' => tag_data[1],
          'type' => tag_data[2],
          'file' => scenario_file
        }
        if common.has_key?('setup_requires')
          testcase['hw_caps'] = common['setup_requires']
        end
        testcases << testcase
      rescue Exception 
        puts "**** WARNING ****"
        puts "Test scenario file #{scenario_file} contains error. Please ensure test case tags follows naming convention"
      end
    }
    testcases
  end
  
  # Do not include testcases in the skip list 
  # The list is defined in SKIP_TESTCASES.rb
  def skip_test?(tag)
    $FILTER_TAGS.each{|r|
      if r.match(tag)
        puts "Skipping testcase: #{tag}"
        return true
      end
    }
    return false
  end
  
  # Takes Testsuites map and creates xml file suitable for Testlink's import
  # at filepath location
  def write_testcases_xml(testsuites, filepath)
    doc = Document.new('<?xml version="1.0" encoding="UTF-8"?>')
    root  = doc.add_element "testsuite", {'name' => ''}
    testsuites.each{|k,v|
      ts  = root.add_element "testsuite", {'name' => k}
      tsl = ts.add_element "testsuite", {'name' => "ltp"}
      v.each{|t|
        tc = tsl.add_element "testcase", {'name' => t['name']}
        et = tc.add_element "execution_type"
        et.text = "2"
        summary = tc.add_element "summary"
        CData.new( t['desc'], true, summary )
        cfs = tc.add_element "custom_fields"
        add_custom_field(cfs, "tee", "vatf")
        add_custom_field(cfs, "scripts", "LSP/TARGET/dev_test2.rb")
        dut_caps = t.has_key?('hw_caps') ? "linux_#{t['hw_caps']}" : 'linux'
        add_custom_field(cfs, "hw_assets_config", "dut1=[\"<platform>\",#{dut_caps}];server1=[\"linux_server\"]")
        if k == 'SPI'
          bootargs_append = 'spi'
          add_custom_field(cfs, "params_control", "script=cd /opt/ltp;./runltp -P \#{@equipment['dut1'].name} -f #{t['file']} -s \"#{t['name']} \",timeout=#{get_timeout(t['scope'], t['type'])},bootargs_append=#{bootargs_append}")
        else
          add_custom_field(cfs, "params_control", "script=cd /opt/ltp;./runltp -P \#{@equipment['dut1'].name} -f #{t['file']} -s \"#{t['name']} \",timeout=#{get_timeout(t['scope'], t['type'])}")
        end
        kws = tc.add_element "keywords"
        kws.add_element "keyword", {'name' => "s_#{t['scope']}"}
        kws.add_element "keyword", {'name' => "t_#{t['type']}"}
      }
    }
    f = File.new(filepath, "w")
    doc.write(f)
    f.close
  end
  
  def get_timeout(scope, type)
    scope.upcase!
    case scope
      when 'XS'
        return '60'
      when 'S'
        return (60*10).to_s
      when 'M'
        return (60*60).to_s
      when 'L'
        return (60*60*8).to_s
      when 'XL'
        return (60*60*24).to_s
      when 'XXL'
        return (60*60*24*7).to_s
      else
        raise "Invalid test scope #{scope}"
    end     
  end
  
  def add_custom_field(parent, name, value)
    cf = parent.add_element "custom_field"
    cfn = cf.add_element "name"
    cfv = cf.add_element "value"
    CData.new(name, true, cfn)
    CData.new(value, true, cfv)
  end
  
  def set_root_dir(dir)
    @rootDir = dir
  end
end

t = TestImporter.new
t.clone_project()
#t.set_root_dir('/home/a0850405local/workspace/TestsImporter/2011-06-14_11:46:00')
scenarios = t.find_test_scenarios()
x = 0
testcases = []
scenarios.each {|scenario|
  x+=1
  testcases << t.process_test_scenario(scenario)
}
testcases.flatten!
puts "There are #{x} scenario files"
puts "There are #{testcases.length} testcases"
testcasesMap={}
while testcases.length > 0
  key=testcases[0]['testsuite']
  testcasesMap[key] = testcases.select {|tc| tc['testsuite'] == key }
  testcases = testcases - testcasesMap[key]
end
testcasesMap.each {|k, v| puts "Area #{k} has #{v.length} tests. file=#{v[0]['file']}"}
t.write_testcases_xml(testcasesMap, "testcases.xml")
puts "Done!!!"

