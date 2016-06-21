def setup

  boot_params = {'power_handler' => @power_handler}
  @equipment['dut1'].power_cycle(boot_params)

  if !(@equipment['dut1'].respond_to?(:serial_port) && @equipment['dut1'].serial_port != nil)
    raise "You need serial port connectivity to the board to test. Please check your bench file"
  end
  @equipment['dut1'].connect({'type'=>'serial'})
  @equipment['dut1'].log_info("serial setup")
  @equipment['dut1'].wait_for('Motor ready to run') # if reqd., increase default timeout
end

def run

  build_level = "level4"
  loop_type = "closed"
  loop_count = 2
  speed_interval = 60
  position_interval = 25
  speeds = []
  positions = []

  build_level = @test_params.params_control.build_level[0] if @test_params.params_control.instance_variable_defined?(:@build_level)
  loop_type = @test_params.params_control.loop_type[0] if @test_params.params_control.instance_variable_defined?(:@loop_type)
  loop_count = @test_params.params_control.loop_count[0].to_i if @test_params.params_control.instance_variable_defined?(:@loop_count)
  speed_interval = @test_params.params_control.speed_interval[0].to_i if @test_params.params_control.instance_variable_defined?(:@speed_interval)
  position_interval = @test_params.params_control.position_interval[0].to_i if @test_params.params_control.instance_variable_defined?(:@position_interval)
  speeds = @test_params.params_control.speed[0].split(" ").map(&:to_i) if @test_params.params_control.instance_variable_defined?(:@speed)
  positions = @test_params.params_control.position[0].split(" ").map(&:to_i) if @test_params.params_control.instance_variable_defined?(:@position)

  if loop_type.eql? "open"
    loop_type_in_int = 1
  else
    loop_type_in_int = 2
  end

  result = 0
  speed_tol = 0.02 # in pu
  position_tol = 1 # in degree

  config_prompt = ": "
  config_end_prompt = "..."
  config_start = ""
  config_bypass = ""

  timeout = 1

  off = 0 # turn off motor
  on = 2 # for level 5 & 6 position control on
  # for level 6
  speed_control = 0
  position_control = 1

  @equipment['dut1'].log_info("Build Level - #{build_level}")
  @equipment['dut1'].log_info("loop count - #{loop_count}")

  if build_level.eql? "level4"
    @equipment['dut1'].log_info("#{loop_type} loop")
    @equipment['dut1'].log_info("speeds - #{speeds}")
    @equipment['dut1'].log_info("speed interval - #{speed_interval}")
    loop_count.times do |i|
      @equipment['dut1'].log_info("loop #{i + 1}")
      speeds.each do |speed|

        @equipment['dut1'].log_info("speed #{speed} rpm")
        # run at the speed - speed
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout) # configure
        @equipment['dut1'].send_cmd("#{loop_type_in_int}", config_prompt, timeout) # start, set loop type
        @equipment['dut1'].send_cmd("#{speed}", config_prompt, timeout) # speed
        @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout) # position
        sleep(speed_interval)

        # to determine success/failure
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        speed_actual = @equipment['dut1'].response.match(/([0-9]+)(\s*)(rpm)/).captures[0].to_i
        speed_offs = ((speed_actual.abs-speed.abs)/(speed.to_f)).abs
        if speed_offs > speed_tol
          result = 1
        end
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)

      end
    end
    # bring motor to standstill
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{loop_type_in_int}", config_prompt, timeout)
    @equipment['dut1'].send_cmd("0", config_prompt, timeout) # zero speed
    @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
    sleep(speed_interval)
    # turn off motor
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{off}", config_prompt, timeout) # stop
    @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
    @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
  elsif build_level.eql? "level5"
    @equipment['dut1'].log_info("positions - #{positions}")
    @equipment['dut1'].log_info("position interval - #{position_interval}")
    # bring motor to initial position
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout)
    @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
    @equipment['dut1'].send_cmd("0", config_end_prompt, timeout) # initial position
    loop_count.times do |i|
      @equipment['dut1'].log_info("loop #{i + 1}")
      positions.each do |position|

        @equipment['dut1'].log_info("position #{position} degree")
        # bring at position - position
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout) # configure
        @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout) # start
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout) # speed
        @equipment['dut1'].send_cmd("#{position}", config_end_prompt, timeout) # position
        sleep(position_interval)

        # to determine success/failure
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        position_actual = @equipment['dut1'].response.match(/([0-9]+)(\s*)(degree)/).captures[0].to_i
        position_offs = (position_actual.abs-position.abs).abs
        if position_offs > position_tol
          result = 1
        end
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)

      end
    end
    # bring motor to initial position
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout)
    @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
    @equipment['dut1'].send_cmd("0", config_end_prompt, timeout) # initial position
    sleep(position_interval)
    # turn off motor
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{off}", config_prompt, timeout) # stop
    @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
    @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
  elsif build_level.eql? "level6"
    @equipment['dut1'].log_info("#{loop_type} loop")
    @equipment['dut1'].log_info("speeds - #{speeds}")
    @equipment['dut1'].log_info("speed interval - #{speed_interval}")
    @equipment['dut1'].log_info("positions - #{positions}")
    @equipment['dut1'].log_info("position interval - #{position_interval}")
    loop_count.times do |i|
      @equipment['dut1'].log_info("loop #{i + 1}")
      unless speeds.length.eql? 0
        # bring motor to standstill
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        @equipment['dut1'].send_cmd("#{speed_control}", config_prompt, timeout) # speed control
        @equipment['dut1'].send_cmd("#{loop_type_in_int}", config_prompt, timeout)
        @equipment['dut1'].send_cmd("0", config_prompt, timeout) # zero speed
        @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
        sleep(speed_interval)
        speeds.each do |speed|

          @equipment['dut1'].log_info("speed #{speed} rpm")
          # run at the speed - speed
          @equipment['dut1'].send_cmd(config_start, config_prompt, timeout) # configure
          @equipment['dut1'].send_cmd("#{speed_control}", config_prompt, timeout) # speed control
          @equipment['dut1'].send_cmd("#{loop_type_in_int}", config_prompt, timeout) # start, set loop type
          @equipment['dut1'].send_cmd("#{speed}", config_prompt, timeout) # speed
          @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout) # position
          sleep(speed_interval)

          # to determine success/failure
          @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
          speed_actual = @equipment['dut1'].response.match(/([0-9]+)(\s*)(rpm)/).captures[0].to_i
          speed_offs = ((speed_actual.abs-speed.abs)/(speed.to_f)).abs
          if speed_offs > speed_tol
            result = 1
          end
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)

        end
        # bring motor to standstill
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        @equipment['dut1'].send_cmd("#{speed_control}", config_prompt, timeout) # speed control
        @equipment['dut1'].send_cmd("#{loop_type_in_int}", config_prompt, timeout)
        @equipment['dut1'].send_cmd("0", config_prompt, timeout) # zero speed
        @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
        sleep(speed_interval)
      end
      unless positions.length.eql? 0
        # bring motor to initial position
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        @equipment['dut1'].send_cmd("#{position_control}", config_prompt, timeout) # position control
        @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd("0", config_end_prompt, timeout) # initial position
        sleep(position_interval)
        positions.each do |position|

          @equipment['dut1'].log_info("position #{position} degree")
          # bring at position - position
          @equipment['dut1'].send_cmd(config_start, config_prompt, timeout) # configure
          @equipment['dut1'].send_cmd("#{position_control}", config_prompt, timeout) # position control
          @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout) # start
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout) # speed
          @equipment['dut1'].send_cmd("#{position}", config_end_prompt, timeout) # position
          sleep(position_interval)

          # to determine success/failure
          @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
          position_actual = @equipment['dut1'].response.match(/([0-9]+)(\s*)(degree)/).captures[0].to_i
          position_offs = (position_actual.abs-position.abs).abs
          if position_offs > position_tol
            result = 1
          end
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
          @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)

        end
        # bring motor to initial position
        @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
        @equipment['dut1'].send_cmd("#{position_control}", config_prompt, timeout) # position control
        @equipment['dut1'].send_cmd("#{on}", config_prompt, timeout)
        @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
        @equipment['dut1'].send_cmd("0", config_end_prompt, timeout) # initial position
        sleep(position_interval)
      end
    end
    # turn off motor
    @equipment['dut1'].send_cmd(config_start, config_prompt, timeout)
    @equipment['dut1'].send_cmd("#{speed_control}", config_prompt, timeout) # switch to speed control at end
    @equipment['dut1'].send_cmd("#{off}", config_prompt, timeout) # stop
    @equipment['dut1'].send_cmd(config_bypass, config_prompt, timeout)
    @equipment['dut1'].send_cmd(config_bypass, config_end_prompt, timeout)
  else
    @equipment['dut1'].log_info("invalid build level - #{build_level}")
  end

  @equipment['dut1'].log_info("serial run")

  if result == 0
    set_result(FrameworkConstants::Result[:pass], "Test Pass")
  else
    set_result(FrameworkConstants::Result[:fail], "Test Fail")
  end
end

def clean
  @equipment['dut1'].log_info("serial clean")
  @equipment['dut1'].disconnect('serial') if @equipment['dut1'].target.serial
end
