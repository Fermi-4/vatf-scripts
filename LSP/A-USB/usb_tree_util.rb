require 'tree'
#root_of_roots = Tree::TreeNode.new("root","Root Content")
# Function: hash_recursive 
# Input: parent is parent node for the tree, can be nil, myHash is hash describing the tree, could be from bench file entry, and root_of_roots is the root for the tree to be generated
# Output: returns the corresponding ruby Tree object
# Function creates a Tree object given the root/parent in input as well as the hash to be used for the tree content
def hash_recursive(parent, myHash,root_of_roots)
  myHash.each {|key, value|
               root_node_name = 'root_'+"#{key}"+'_node'
               root_node_name = root_of_roots << Tree::TreeNode.new("#{key}","#{value}")
               if (value.is_a?(Hash))
                 hash_recursive(key, value, root_node_name)
               end
              }
root_of_roots
end
# Function: find_device_nodes
# input: device_chain which is dev_node of the form hub_hub_msc, etc and the tree on which this is to be found - ehci or xhci, etc.
# output: array of switch_port pairs
# Function traverses the tree and starting at leaf, finds the first combination which matches the node being looked for.
def find_device_nodes(device_chain,tree)
  device_info=[]
  node_array = device_chain.split('_')
  num_device_to_find = node_array.size
  tree.root.each_leaf{|node|
      puts "Entered leaf loop #{node}\n"
      device_node=[]
      device_info=[]
      num_device_found = 0
      if(node.to_s.match(node_array[num_device_to_find-1]))  #found last item of chain as a leaf of tree
        switch_match = node.parent.to_s.match(/Node Name:\s*sw-ob\d/i)
        if (switch_match != nil)
           port = node.parent.content.match(/port_\d/i)
           if port != nil
              port = port.to_s.split('port_')[1]
              sw_object = switch_match.to_s.match(/sw-ob\d/i)
      #       puts "switch port pair is #{switch_match} and #{port}\n"
              node_info = [node_array[num_device_to_find-1], sw_object, port]
              device_info << node_info
              num_device_found = num_device_found + 1 # we might have found one device
              return device_info if (num_device_found == num_device_to_find)
           end
         end
         # good so far
         if (node.parent.to_s.match('sw-ob')) # if parent node is a switch object, check the grandparent node
            return device_info if (num_device_found == num_device_to_find)
            node = node.parent.parent
         else
           node = node.parent
         end
         i = 1
         while (num_device_found < num_device_to_find) 
              # Now handle subsequent non-leaf nodes
           if node.to_s.match("Node Name: "+node_array[num_device_to_find-i-1])
              device_node << node
              switch_match = nil
              port = nil
              node_info = nil
              switch_match = node.parent.to_s.match(/Parent:\s*sw-ob\d/i)
              if (switch_match != nil)
                 puts "NOT NIL\n"
                 port = node.parent.to_s.match(/Node Name:\s*port_\d/i)
                 if port != nil
                   port = port.to_s.split('port_')[1]
                   sw_object = switch_match.to_s.match(/sw-ob\d/i)
                   node_info = [node_array[num_device_to_find-i-1], sw_object, port]
                 end
               end
               num_device_found = num_device_found + 1
               device_info << node_info
               return device_info if (num_device_found == num_device_to_find)
          else
             break
          end
          i = i+1 if i<num_device_to_find
          if (node.parent.to_s.match('Parent: sw-ob') ) # if parent node is a switch object, check the grandparent node
                node = node.parent.parent
                if (node.to_s.match('Node Name: sw-ob'))
                   node = node.parent
                end
          else 
               node = node.parent
          end
        end # end of while
    end # if found leaf node to be last element in list
    }
   #puts "Device_Info is #{device_info}\n"
   device_info
end

def connect_to_extra_equipment
# Creates an array of usb switches used by usb devices and connects to those 
# switches
   usb_switch_array=Array.new
# port name would be a test case parameter for example usbhost-ehci, port number would be 0 or 1, by default port number will be 0
  port_name = @test_params.params_control.port_name[0]
  port_num = @test_params.params_control.port_num[0].to_i
  usb_switch_array = find_switch_array(port_name, port_num)
  # puts "Switch collection is #{usb_switch_array}\n"
    #for each element in switch_collection, create a corresponding switch equipment and check its connectivity
   usb_switch_array.each do |sw|

        usb_switch = @equipment[sw]
        if usb_switch.respond_to?(:serial_port) && usb_switch.serial_port != nil
          usb_switch.connect({'type'=>'serial'})
        elsif usb_switch.respond_to?(:serial_server_port) && usb_switch.serial_server_port != nil
          usb_switch.connect({'type'=>'serial'})

        else
          raise "You need direct or indirect (using Telnet/Serial Switch) serial port connectivity to the USB switch #{usb_switch}, Please check your bench file"
        end
   end
end

# Function: find_switch_array
# Input: port_name and port_number on target - example port_name usb_ehci_host and port_number 0
# Output: array of switches which are defined in the tree hash in bench file
# Function traverses every child of usb tree structure to provide a setup of unique switches which would be required for the test
def find_switch_array(port_name, port_num)
  usb_tree = @equipment['dut1'].params[port_name][port_num]
  root_of_roots = Tree::TreeNode.new("root","Root Content")
  tree = hash_recursive(nil,usb_tree,root_of_roots)
  tree.print_tree
  sw_match = []
  tree.root.each{|child|
  if (child.to_s.match(/sw-ob\d/i) != nil)
  sw_match << child.to_s.match(/sw-ob\d/i).to_s
  end
  }
  sw_match = sw_match.uniq
end



# Function: determine_switch_port
# input: node - of the form "hub_hub_msc", port_name of the form usbhost_ehci and port_num, say, 0 or 1
# output: array of switch names and corresponding port numbers
# Function uses bench entry for tree structure, figures out 
# based on host, generates tree, and based on node parameter in input
# will locate the node in the tree
def determine_switch_port(node, port_name, port_num)
  usb_tree = @equipment['dut1'].params[port_name][port_num]
  #puts "USB_TREE is #{usb_tree}\n"
  root_of_roots = Tree::TreeNode.new("root","Root Content")
  tree = hash_recursive(nil,usb_tree,root_of_roots)
  tree.print_tree

  device_node_array=[]
  device_node_array = find_device_nodes(node,tree)
  if (device_node_array == nil)
     raise "Device node not found in tree. Please check bench entry for correct tree hash entry or test case parameter to ensure correct node is looked for"
  end
  device_node_array
end

# Function: connect_device(dev_array)
# input -  an array of arrays - array of switch_port sequence which need to be connected
# output - none
# connect_device enables the port on the usb switch for each switch_port pair in the input

def connect_device(dev_array)
  dev_array.each do |device|
   if (device != nil)
     #puts "DEVICE details is #{device}\n"
     sw_object = device[1].to_s
     port = device[2]
     #puts "Switch and port are #{sw_object} and #{port}\n"
     #puts "switch object is #{@equipment[sw_object.to_s]}\n"
     @equipment[sw_object.to_s].select_input(port)
   end
  end
end

# Function: disconnect_device(dev_array)
# input -  an array of arrays - array of switch_port sequence for all devices which need to be connected
# output - none
# disconnect_device enables the port on the usb switch for each device in the input
def disconnect_device(dev_array)
  dev_array.each do |device|
   if (device != nil)
     #puts "DEVICE details is #{device}\n"
     sw_object = device[1].to_s
     port = device[2]
     #puts "Switch and port are #{sw_object} and #{port}\n"
     #puts "switch object is #{@equipment[sw_object.to_s]}\n"
     @equipment[sw_object.to_s].disconnect()
   end
  end
end


# Function: disconnect_leaf_device(dev_array)
# input -  an array of arrays - array of switch_port sequence for all devices which need to be connected
# output - none
# disconnect_leaf_device disables the port on the usb switch for leaf device in the input
def disconnect_leaf_device(dev_array)
   device = dev_array[0]
   if (device != nil)
     #puts "DEVICE details is #{device}\n"
     sw_object = device[1].to_s
     port = device[2]
     #puts "Switch and port are #{sw_object} and #{port}\n"
     #puts "switch object is #{@equipment[sw_object.to_s]}\n"
     @equipment[sw_object.to_s].disconnect()
   end
end

# Function: verify_device_detected
# input: log from equipment console
# output: 1 if device is detected, 0 if not
# verify_device_detected uses enum_strings and enum_count for each enum_string 
# in test case parameter to determine if that string is found in the equipment log
def verify_device_detected(enum_data)
  test_status = 0
  for i in 0..@test_params.params_control.enum_strings.size-1
    #puts "ENUM_STRING is #{@test_params.params_control.enum_strings[i]}\n"
    match_string = "usb\s.*\S.*#{@test_params.params_control.enum_strings[i]}"
    # puts "CountNew is #{enum_data.match(/#{match_string}/i)}\n"
    if (enum_data.match(/#{match_string}/i) != nil)
     # puts "MATCH STRING is #{match_string}\n"
     if (enum_data.match(/#{match_string}/i).size == @test_params.params_control.enum_count[i].to_i )
       test_status = 1
     else
        #puts "Result of scan is #{enum_data.match(/#{match_string}/i).size} and count required is #{@test_params.params_control.enum_count[i]} \n" 
        test_status = 0
        return test_status
     end
    else
     # puts "Count is #{enum_data.scan(@test_params.params_control.enum_strings[i])}\n"
     # puts "CountNew is #{enum_data.scan(@test_params.params_control.enum_strings[i]).size}\n"
     if (enum_data.scan(@test_params.params_control.enum_strings[i]).size == @test_params.params_control.enum_count[i].to_i)
       test_status = 1
     else
        # puts "Result of scan is #{enum_data.scan(@test_params.params_control.enum_strings[i]).size} and count required is #{@test_params.params_control.enum_count[i]} \n" 
        test_status = 0
        return test_status
    end
    end
  end
  #puts "value is #{test_status}\n"
  test_status
end

