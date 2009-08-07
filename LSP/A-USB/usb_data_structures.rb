
module USBDataStructures

	def USBDataStructures::get_descriptors_table
		result = {
			1 => 'DeviceDescriptor',
			2 => 'ConfigDescriptor',
			3 => 'StringDescriptor',
			4 => 'InterfaceDescriptor',
			5 => 'EndPointDescriptor',
			6 => 'DevQaulifierDescriptor',
			7 => 'OtherSpeedConfigDescriptor',
		}
		result.default = 'USBClassSpecificDescriptor'
		result
	end
	
	class USBHostController
		attr_accessor :ports, :host_id
		
		def initialize(host_id)
			@ports = Array.new
			@host_id = host_id
		end
		
		def add_port(port_number, port_dev)
			@ports[port_number] = port_dev
		end
		
		def remove_port(port_number)
		   @ports.delete_at(port_number)
		end
		
		def add_ports(new_ports)
			@ports.concat(new_ports)
		end
	end
	
	class USBHub
		attr_accessor :ports
		
		def initialize
			@ports = Array.new
		end
		
		def add_port(port_number, port_dev)
			@ports[port_number] = port_dev
		end
		
		def remove_port(port_number)
		   @ports.delete_at(port_number)
		end
		
		def add_ports(new_ports)
			@ports.concat(new_ports)
		end
	end

	class Descriptor
		attr_accessor :length
		attr_reader   :type
		
		def set_descriptor_field(field,value)
			self.class.class_eval do
              attr_accessor field.strip.to_sym
            end
			instance_variable_set("@#{field.strip}",value)
		end
	end

	class DeviceDescriptor < Descriptor
		#attr_accessor :bcd_usb, :device_class, :device_subclass, :device_protocol, :max_pkt_size_ep0, :vendor_id, :product_id, :bcd_device, \
		#			  :product, :manufacturer, :serial_number, :num_config
		attr_accessor :configurations
		def initialize
			@type = 1
			@configurations = Array.new
		end
	end

	class DevQaulifierDescriptor < DeviceDescriptor
		def initialize
			@type = 6
		end
	end

	class InterfaceDescriptor < Descriptor
		#attr_accessor :interface_number, :alternate_setting, :num_end_points, :interface_class, :interface_subclass, :interface_protocol, :interface, :endpoints, :class_specific_descriptors
		attr_accessor :endpoints, :class_specific_descriptors
		def initialize
			@type = 4
			@endpoints = Array.new
			@class_specific_descriptors = Array.new
		end
	end
	
	class USBClassSpecificDescriptor < Descriptor
		def initialize(desc_type)
			@type = desc_type
		end
	end

	class EndPointDescriptor < Descriptor
		#attr_accessor :end_point_address, :attributes, :max_pkt_size, :interval
		def initialize
			@type = 5
		end
	end

	class StringDescriptor < Descriptor
		#attr_accessor :string_or_langids
		def initialize
			@type = 3
		end
	end

	class ConfigDescriptor < Descriptor
		#attr_accessor :total_length, :num_interfaces, :config_value, :configuration, :attributes, :max_power, :interfaces
		attr_accessor :interfaces
		def initialize
			@type = 2
			@interfaces = Array.new
		end
	end
	
	class OtherSpeedConfigDescriptor < ConfigDescriptor
	   # attr_reader :interfaces
		def initialize
			@type = 7
		end
	end
end
