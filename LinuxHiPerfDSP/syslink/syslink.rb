require File.dirname(__FILE__)+'/../boot/c6x_ccs_test_module'
include C6xCCSTestScript
  
def setup
  super
end

def run
  test_done_result = FrameworkConstants::Result[:fail]
  comment = "Test fail"
  dut = @equipment['dut1']
  linux_server = @equipment['server1']


  dut.send_cmd("cd #{DUT_DST_DIR}",dut.prompt,10)
  dut.send_cmd("insmod syslink.ko",dut.prompt,10)
  dut.send_cmd("mkdir /dev/syslinkipc/",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/Osal c 253 12",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/Ipc c 253 11",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/ProcMgr c 253 0 ",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/Notify c 253 1",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/MultiProc c 253 10",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/NameServer c 253 2",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/SharedRegion c 253 3",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/HeapBufMP c 253 4",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/HeapMemMP c 253 5",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/HeapMultiBuf c 253 6",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/ListMP c 253 7",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/GateMP c 253 8",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/MessageQ c 253 9",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/SyslinkMemMgr c 253 13",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/ClientNotifyMgr c 253 14",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/FrameQBufMgr c 253 15",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/FrameQ c 253 16",dut.prompt,10)
  dut.send_cmd("mknod -m 777 /dev/syslinkipc/RingIO c 253 17",dut.prompt,10)
  linux_core_response_regex=''
  bios_core_response_regex=''
  if(@platform == "faraday")
    case @testcase
    when "notify"
      linux_core_response_regex=/(?:.*?(?:Received\s+200\s+events\s+for\s+event\s+ID\s+\d+\s+from\s+processor\s+\d+)){6}/im
      bios_core_response_regex=''
    when "gatemp"
     linux_core_response_regex=/Completed\s+9000\s+iterations\s+successfully/
     bios_core_response_regex=/(.*?(?:Completed\s+GateMP\s+Test\s+on\s+core\s+\d+)){2}/im
    when "heapbufmp"  
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapBufMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){4}/im  
      bios_core_response_regex=/Block\s+allocated\s+successfully/
    when "heapmemmp"
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapMemMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){4}/im  
      bios_core_response_regex=/Block\s+allocated\s+successfully/
    when "listmp"
      bios_core_response_regex = /((.*?ListMP\s+test\s+complete,\s+status\s+=\s+0).*?){2}/im  
      linux_core_response_regex=''
    when "messageq"
      linux_core_response_regex=/(.*?Sending\s+a\s+message\s+#1000\s+to\s+\d){2}/im
      bios_core_response_regex=/The\s+test\s+is\s+complete/im
    when "sharedregion"
      linux_core_response_regex=/(.*?Successfully\s+\w+\s+0x1000\s+bytes\s+\w+\s+heap\s+associated\s+with\s+sharedregion\s+\d+){4}/im
    end
  elsif (@platform == "tomahawk")
    case @testcase
    when "notify"
      linux_core_response_regex=/(?:.*?(?:Received\s+200\s+events\s+for\s+event\s+ID\s+\d+\s+from\s+processor\s+\d+)){12}/im
      bios_core_response_regex=''
    when "gatemp"
     linux_core_response_regex=/Completed\s+9000\s+iterations\s+successfully/
     bios_core_response_regex=/(.*?(?:Completed\s+GateMP\s+Test\s+on\s+core\s+\d+)){5}/im
    when "heapbufmp"  
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapBufMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){4}/im  
      bios_core_response_regex=/Block\s+allocated\s+successfully/
    when "heapmemmp"
      linux_core_response_regex = /(?:(?:.*?Allocating\s+from\s+\w+\s+Heap)(?:.*?HeapMemMP_\w+\.\s+\w+\s+\[0x[0-9a-e].*?\]){4}){4}/im  
      bios_core_response_regex=/Block\s+allocated\s+successfully/
    when "listmp"
      bios_core_response_regex = /((.*?ListMP\s+test\s+complete,\s+status\s+=\s+0).*?){2}/im  
      linux_core_response_regex=''
    when "messageq"
      linux_core_response_regex=/(.*?Sending\s+a\s+message\s+#1000\s+to\s+\d){2}/im
      bios_core_response_regex=/The\s+test\s+is\s+complete/im
    when "sharedregion"
      linux_core_response_regex=/(.*?Successfully\s+\w+\s+0x1000\s+bytes\s+\w+\s+heap\s+associated\s+with\s+sharedregion\s+\d+){4}/im
    end
  end

  tst_thread = Thread.new()  {
    linux_server.wait_for(bios_core_response_regex,450)
  }
  dut.send_cmd("./#{@testcase}app.exe #{@ipc_reset_vector}",linux_core_response_regex,420)
  tst_thread.join


  if(!linux_server.timeout? && !dut.timeout?)
    test_done_result = FrameworkConstants::Result[:pass]
    comment = "Test pass"
  end

  set_result(test_done_result,comment)
end

def clean

end



