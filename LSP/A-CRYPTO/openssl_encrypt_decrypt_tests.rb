# Test Application to run openssl encrypt and decrypt tests
# Runs encrypt and decrypt with randomly generated key and iv values
# on files of varying sizes with random data
# Compares input and decrypted files for a match


# -*- coding: ISO-8859-1 -*-
require File.dirname(__FILE__)+'/../default_test_module'
require File.dirname(__FILE__)+'/../../lib/utils'


include LspTestScript
def setup
    super
end

def run
    return_non_zero=0
    result_string=""

    dut_timeout = @test_params.params_control.instance_variable_defined?(:@dut_timeout) ? @test_params.params_control.dut_timeout[0].to_i : 1200

    encryption_set = ['aes-256-cbc', 'aes-128-cbc', 'aes-192-cbc', 'aes-256-ecb', 'aes-128-ecb', 'aes-192-ecb']

    encryption_type = @test_params.params_control.instance_variable_defined?(:@encryption_type) ? @test_params.params_control.encryption_type[0].to_s : 'aes-256-cbc'

    if !encryption_set.include?(encryption_type)
         set_result(FrameworkConstants::Result[:fail],
                    "Encryption Type #{encryption_type} is not supported. Please review
                     test parameters.")
         return
    end
       
      
    (1..256).each do |file_size|
        create_random_file(file_size, 'dut1', 'input.txt')
        key_value = get_random_value
        iv_value = get_random_value
        encrypt_file('dut1', encryption_type, 'input.txt', 'encrypted.txt', key_value, iv_value)
        decrypt_file('dut1', encryption_type, 'encrypted.txt', 'decrypted.txt', key_value, iv_value)
        if (!compare_initial_final('dut1', 'input.txt', 'decrypted.txt'))
          return_non_zero=1
          result_string << "Failure at file_size #{file_size} bytes\n"
        end
    end
  
    
    if return_non_zero
       set_result(FrameworkConstants::Result[:fail],
                  "Openssl Test returned non-zero value. \n #{result_string}")
    else
       set_result(FrameworkConstants::Result[:pass],
                  "Openssl Test passed. \n")
    end

end

def get_random_value(device='server1')
    @equipment[device].send_cmd("echo $RANDOM", @equipment[device].prompt, 10)
    random_value = @equipment[device].response
    random_value.to_i
end

def create_random_file(size=1024, device='dut1', filename='input.txt')
    @equipment[device].send_cmd("rm #{filename}", @equipment[device].prompt, 10)
    @equipment[device].send_cmd("dd if=/dev/urandom of=#{filename} bs=#{size} count=1", 
                                @equipment[device].prompt, 10)
end

def encrypt_file(device='dut1', encrypt_algorithm='aes-256-cbc', in_file='input.txt', 
                 out_file='encrypted.txt', key_value, iv_value)
    openssl_cmd = "openssl #{encrypt_algorithm} -k #{key_value} -iv #{iv_value} -in #{in_file} -out #{out_file}"
    @equipment[device].send_cmd(openssl_cmd, @equipment[device].prompt, 10)
end

def decrypt_file(device='dut1', encrypt_algorithm='aes-256-cbc', in_file='encrypted.txt', 
                 out_file='decrypted.txt', key_value, iv_value)
    openssl_cmd = "openssl #{encrypt_algorithm} -k #{key_value} -iv #{iv_value} -d -in #{in_file} -out #{out_file}"
    @equipment[device].send_cmd(openssl_cmd, @equipment[device].prompt, 10)
    # cleanup here
    @equipment[device].send_cmd("rm #{in_file}", @equipment[device].prompt, 10)

end

def compare_initial_final(device='dut1', input_file='input.txt', output_file='decrypted.txt')
    equal=false
    compare_cmd = "diff #{input_file} #{output_file}>diff_file.txt"
    @equipment[device].send_cmd(compare_cmd, @equipment[device].prompt, 10)
    @equipment[device].send_cmd("echo $?", @equipment[device].prompt, 10)
    response = @equipment[device].response.sub("echo $?", '').strip.to_i
    if (response == 0)
       equal=true
    end
    # cleanup here
    @equipment[device].send_cmd("rm #{input_file}", @equipment[device].prompt, 10)
    @equipment[device].send_cmd("rm #{output_file}", @equipment[device].prompt, 10)
    equal
end
