=begin
If the bench file has a usb mulitplexer, it will select the board requested by
DUT parameters in testlink.
=end
def autoSelectBoard()
    retBoard = nil

    if (@test_params.params_chan.instance_variable_defined?(:@board))
        board = @test_params.params_chan.instance_variable_get(:@board)
        @equipment['dut1'].log_info("Selecting #{board}")
        selectBoard(board[0])
        retBoard = board[0]
    else
        @equipment['dut1'].log_info("No \"board\" DUT parameter defined; continuing test")
        selectBoard()
    end
    retBoard
end

=begin
If the bench file uses a usb multiplexer, it will deselect all boards
=end
def autoDeselectBoard()
    @equipment['dut1'].log_info("Powering down board")
    deselectBoard()
end

def autoResetBoard()
    @equipment['dut1'].log_info("Power-cycling board")
    deselectBoard()
    sleep(2)
    autoSelectBoard()
    sleep(10)
    @equipment['dut1'].log_info("Power-cycling done")
end

=begin
This function selects the proper development board on the USB multiplexer if
one was found in the bench file. It returns the physica USB port index location
at which the board was found. If the board was not found or if no USB
multiplexer was found it returns 0
=end
def selectBoard(name = nil)
    returnValue = 0

    # Get the handle to communicate with the usb switch. If it doesn't respond
    # to serial commands, assume there is no usb_switch configured in the bench
    # file and just return 0 which is the same a being diconnected.
    if (@equipment['dut1'].params.key?('usb0_port'))
        usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb0_port'].keys[0]]
        if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
            usb_switch.connect({'type'=>'serial'})
            if @equipment['dut1'].params.key?(name)
                usb_switch.select_input(@equipment['dut1'].params[name])
                sleep(5)
                returnValue = @equipment['dut1'].params[name]
                @equipment['dut1'].log_info("Selected USB #{returnValue}")

            elsif @equipment['dut1'].params.key?('default')
                @equipment['dut1'].log_info("There is no \"dut.params[\'#{name}\'] entry in the bench file, using default port")
                usb_switch.select_input(@equipment['dut1'].params['default'])

            else
                @equipment['dut1'].log_info("There is no \"dut.params[\'#{name}\'] entry in the bench file")
            end
        else
            puts "Did not connect to a usb switch #{usb0_port}"
        end
    end
    # Return returnValue
    returnValue
end

=begin
If a USB multiplexer exists, it select 0 to disable the board.
=end
def deselectBoard()
    if (@equipment['dut1'].params.key?('usb0_port'))
        usb_switch = @usb_switch_handler.usb_switch_controller[@equipment['dut1'].params['usb0_port'].keys[0]]
        if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
            usb_switch.disconnect()
        end
    end
end
