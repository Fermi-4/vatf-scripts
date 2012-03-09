module GraphicsStressModule

def get_graphics_intents(key)

intents =  Hash.new()
 
intents['intents']=["shell am start -W  -n com.powervr.OGLESVase/.OGLESVase","shell am start -W  -n com.powervr.OGLES2ChameleonMan/.OGLES2ChameleonMan","shell am start -W  -n  com.powervr.OGLES2Coverflow/.OGLES2Coverflow","hshell am start -W  -n  com.powervr.OGLES2Shaders/.OGLES2Shaders"]
intents[key]
end
end 

