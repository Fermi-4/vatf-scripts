require File.dirname(__FILE__)+'/../../LSP/default_test_module'
require File.dirname(__FILE__)+'/../../LSP/A-PCI/test_pcie'

# common function to boot b2b setup
def bootup_b2b(boards_to_setup = 2)
  if boards_to_setup > 1
    for dut_num in 2..boards_to_setup
      # dut x board setup
      add_equipment("dut#{dut_num}", @equipment["dut1"].params["dut#{dut_num}"]) do |e_class, log_path|
        e_class.new(@equipment["dut1"].params["dut#{dut_num}"], log_path)
      end
      @equipment["dut#{dut_num}"].set_api("psp")
      @power_handler.load_power_ports(@equipment["dut#{dut_num}"].power_port)
      # boot x EVM
      # check if both dut1 and dut x not same
      if @equipment["dut1"].name != @equipment["dut#{dut_num}"].name
        setup_boards("dut#{dut_num}", {'dut_idx' => "#{dut_num}"})
      else
        setup_boards("dut#{dut_num}")
      end
    end
  end
  # boot 1st EVM
  setup_boards("dut1")
end
