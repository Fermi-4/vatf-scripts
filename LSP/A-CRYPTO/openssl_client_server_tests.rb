# Test Application to run openssl client server tests
# Depending on the role specified in test case parameter, the test application
# will run dut as client or server and host linux server as server or client, respectively


# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'

# Default Server-Side Test script implementation for LSP releases
   
include LspTestScript
def setup
    super
end

def run
    return_non_zero=1
    dut_timeout = @test_params.params_control.instance_variable_defined?(:@dut_timeout) ? @test_params.params_control.dut_timeout[0].to_i : 600

    test_iterations = @test_params.params_control.instance_variable_defined?(:@iterations) ? @test_params.params_control.iterations[0].to_i : 10

    # Initially, to set time, client will be dut1 and server will be server1 regardless of test 
    # case parameters. It is possible to change dut time to match host linux server time. 
    # Modifying PC time can have unexpected outcome
    client='dut1'
    server='server1'
    set_time_on_client_based_on_server(client, server)

    # Assign client server roles
    role = @test_params.params_control.instance_variable_defined?(:@role) ? @test_params.params_control.role[0].to_s : 'client'

    if (role == 'client')
       client = 'dut1'
       server = 'server1'
    else
       client = 'server1'
       server = 'dut1'
    end

    # Generate certificate with appropriate parameters
    generate_certificate(server)
    
    # Start server
    start_server(server)
    # Allow some time for both client and server time to align
    sleep 60

    # Run client in loop
    i=0
    while (i < test_iterations.to_i) do
       return_non_zero=start_client(client)
       i=i+1
       if (return_non_zero==1)
         break
       end
    end
    
  if (return_non_zero==1)
    set_result(FrameworkConstants::Result[:fail],
            "Openssl Test returned non-zero value. \n")
  else
    set_result(FrameworkConstants::Result[:pass],
            "Openssl Test passed. \n")
  end

end

# Function reads time on server and sets client to a time close to server time
# this is recommended to be used with client as dut and server as host PC always
# regardless of who is client and who is server
# Changing host PC system date can lead to several unforeseen outcomes
# In current form, this function will work with client as 'dut1' and server as 'server1'
# date --rfc-3339=ns -u is not a supported option coresdk version present on duts as of today
 
def set_time_on_client_based_on_server(client='dut1', server='server1')
    client_cmd = "echo `date`"
    # get client time 
    @equipment[client].send_cmd(client_cmd, @equipment[client].prompt, 10)
    client_time = @equipment[client].response
    client_time = client_time.sub(/#{client_cmd}/, "").strip
    # get server time
    @equipment[server].send_cmd("date --rfc-3339=ns -u", @equipment[server].prompt, 10)
    server_time = @equipment[server].response.strip
    # set client time
    @equipment[client].send_cmd("date -s \"#{server_time}\"", @equipment[client].prompt, 10)
end

def generate_certificate(device='server1')
    puts "Entered generate_certificate"
    # kill any existing server process using kill_process
    kill_process('openssl', :this_equipment => @equipment[device],:use_sudo => false)

    subject_parameter = '-subj \'/C=US/ST=Texas/L=Dallas\''

    encryption_type = @test_params.params_control.instance_variable_defined?(:@encryption_type) ? @test_params.params_control.encryption_type[0] : ''

    encryption_length = @test_params.params_control.instance_variable_defined?(:@encryption_length) ? @test_params.params_control.encryption_length[0] : '1024'

    digest_type = @test_params.params_control.instance_variable_defined?(:@digest_type) ? @test_params.params_control.encryption_type[0] : ''

    if (encryption_type != '')
       key_parameter = " -newkey #{encryption_type}:#{encryption_length} "
    else
       key_parameter = ''
    end
    if (digest_type != '')
       digest_parameter = " -#{digest_type} "
    else
       digest_parameter = ''
    end
    create_certificate_cmd = "openssl req -x509 -nodes -days 365 -subj '/C=US/ST=Texas/L=Dallas'#{key_parameter}#{digest_parameter} -keyout mycert.pem -out mycert.pem"
    @equipment[device].send_cmd("#{create_certificate_cmd}", @equipment[device].prompt, 10) 
end

def start_server(device='server1')
    start_server_cmd = "openssl s_server -cert mycert.pem -www &"
    @equipment[device].send_cmd("#{start_server_cmd}", @equipment[device].prompt, 10) 
end

def start_client(device='dut1', server='server1', port=4433)
    return_non_zero = 1
    if (@equipment[device].is_a?(LinuxLocalHostDriver))
       server_ip_address=get_ip_addr
    else
       server_ip_address=@equipment[server].telnet_ip
    end
  
    start_client_cmd = "echo | openssl s_client -connect #{server_ip_address}:#{port} 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > cert.pem"
    @equipment[device].send_cmd("#{start_client_cmd}", @equipment[device].prompt, 10)

    # Send client command with certificate obtained from above
    start_client_cmd = "openssl s_client -connect #{server_ip_address}:#{port} -CAfile cert.pem </dev/null"
    @equipment[device].send_cmd("#{start_client_cmd}", @equipment[device].prompt, 10)
    client_response = @equipment[device].response
    match_string = /return\s*code:\s*0\s*\(ok\)/.match(client_response)
    @equipment['dut1'].log_info("Match String\n #{match_string}\n")
    unless match_string.nil?
       return_non_zero = 0
    end
end
