# -*- coding: ISO-8859-1 -*-
require 'rubyclr'

include System::Windows::Forms
include LspTestScript

def setup
  self.as(LspTestScript).setup
end

def run
    device = @test_params.params_chan.usb_device[0] # One device per test cases
    operation = @test_params.params_chan.usb_device[0] == 'mouse' ? @test_params.params_chan.mouse_op[0] :  @test_params.params_chan.key_op[0]
	@equipment['dut1'].send_cmd('lsmod',/evdev/mi,2)
	@equipment['dut1'].send_cmd('insmod evdev.ko',@equipment['dut1'].prompt) if @equipment['dut1'].timeout?
    #@equipment['dut1'].send_cmd('evtestkill.sh') # Netoyage force. Arret the Process avant de commencer
      begin 
        a = MessageBox.Show("Plug in your USB #{device} into the target")# La boite a message
    	a = nil
    	rescue Exception
      end
    sleep 2
    @equipment['dut1'].send_cmd('evtest /dev/input/event0') # Commande a donner au DUT
    
    sleep 2
      begin
       b = MessageBox.Show("Press the #{device} #{operation} key or Button and Press OK to continue")
       b = nil
       rescue Exception
      end
    regex = get_reg_expr(device,operation)
	puts "Regex to use #{regex}"
    @equipment['dut1'].send_cmd('',regex, 10) # N'ennvoyer aucune commande, attendez que l'operateur bouge l'element
    if @equipment['dut1'].timeout?  # S'il n'y a aucun movement echec
    	set_result(FrameworkConstants::Result[:fail], "Fail: No match found for #{device} #{operation}" )

    else  
        set_result(FrameworkConstants::Result[:pass], "Passed")
    end
end

def clean
  @equipment['dut1'].send_cmd("\cC")
  self.as(LspTestScript).clean
end

private 
def get_reg_expr(device, operation)
    case device
    when 'mouse':
        case operation
        when 'mouse movement': /X/
        when 'right click': 		/273\s*\(RightBtn\),\s*value\s*1/mi
        when 'left click':		/272 \(LeftBtn\), value 1/
        when 'midle button click':	/274 \(MiddleBtn\), value 1/
        when 'wheel Forward Movement':	/8\s*\(Wheel\),\s*value\s*1/mi
        when 'wheel Backward Movement': /8\s*\(Wheel\),\s*value\s*-1/mi
		end

    when 'keyboard':
        case operation
        when 'a' : /\(Key\), code 30 \(A\)/
        when 'b' :  /\(Key\), code 48 \(B\)/
        when 'c' :  /\(Key\), code 46 \(C\)/
        when 'd' :  /\(Key\), code 32 \(D\)/
        when 'e' :  /\(Key\), code 18 \(E\)/
        when 'f' :  /\(Key\), code 33 \(F\)/
        when 'g' :  /\(Key\), code 34  \(G\)/
        when 'h' :  /\(Key\), code 35 \(H\)/   
        when 'i' : /\(Key\), code 23 \(I\)/
        when 'j' : /\(Key\), code 36 \(J\)/ 
        when 'k' : /\(Key\), code 37 \(K\)/
        when 'l' : /\(Key\), code 38 \(L\)/   
        when 'Semicolon' : /\(Key\), code 39 \(Semicolon\)/  
        when 'SingleQuote' : /\(Key\), code 40 \(Apostrophe\)/
        when 'Enter' : /\(Key\), code 28 \(Enter\)/ 
        when 'm' : /\(Key\), code 50 \(M\)/
        when 'n' : /\(Key\), code 49 \(N\)/ 
        when 'v' : /\(Key\), code 47 \(V\)/
        when 'x' : /\(Key\), code 45 \(X\)/  
        when 'o' : /\(Key\), code 24 \(O\)/    
        when 'p' : /\(Key\), code 25 \(P\)/    
        when 'q' : /\(Key\), code 16 \(Q\)/    
        when 'u' : /\(Key\), code 22 \(U\)/
        when 'r' : /\(Key\), code 19 \(R\)/    
        when 's' : /\(Key\), code 31 \(S\)/
        when 't' : /\(Key\), code 20 \(T\)/
        when 'z' : /\(Key\), code 44 \(Z\)/
        when 'Esc' : /\(Key\), code 1 \(Esc\)/            
        when 'F1' : /\(Key\), code 59 \(F1\)/
        when 'F2' : /\(Key\), code 60 \(F2\)/    
        when 'F3' : /\(Key\), code 61 \(F3\)/    
        when 'F4' : /\(Key\), code 62 \(F4\)/    
        when 'F5' : /\(Key\), code 63 \(F5\)/            
        when 'F6' : /\(Key\), code 64 \(F6\)/     
        when 'F7' : /\(Key\), code 65 \(F7\)/
        when 'F8' : /\(Key\), code 66 \(F8\)/ 
        when 'F9' : /\(Key\), code 67 \(F9\)/
        when 'F10' : /\(Key\), code 68 \(F10\)/
        when 'F11' : /\(Key\), code 87 \(F11\)/
        when 'F12' : /\(Key\), code 88 \(F12\)/  
        when '1' : /\(Key\), code 2 \(1\)/    
        when '2' : /\(Key\), code 3 \(2\)/    
        when '3' : /\(Key\), code 4 \(4\)/    
        when '4' : /\(Key\), code 5 \(4\)/    
        when '5' : /\(Key\), code 6 \(5\)/    
        when '6' : /\(Key\), code 7 \(6\)/    
        when '7' : /\(Key\), code 8 \(7\)/    
        when '8' : /\(Key\), code 9 \(8\)/    
        when '9' : /\(Key\), code 10 \(9\)/    
		when '0' : /\(Key\), code 11 \(0\)/ 
        when 'Minus' : /\(Key\), code 12 \(Minus\)/
        when 'Equal' : /\(Key\), code 13 \(Equal\)/
        when 'Backspace' : /\(Key\), code 14 \(Backspace\)/
		when '`' : /\(Key\), code 41 \(Grave\)/
        when 'Insert' : /\(Key\), code 110 \(Insert\)/
        when 'Home' : /\(Home\), code 102 \(Home\)/        
                               
        end
    else // 	#hub
    end
end