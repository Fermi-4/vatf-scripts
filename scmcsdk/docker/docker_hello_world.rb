require File.dirname(__FILE__)+'/../../LSP/default_test_module'
include LspTestScript

def setup
    self.as(LspTestScript).setup
end

def run
    begin
        docker_hello_world()
        set_result(FrameworkConstants::Result[:pass], "Test Passed. Received message \"Hello from Docker!\"")
    rescue Exception => e
        set_result(FrameworkConstants::Result[:fail], "Test Failed. #{e}")
    end
end

def clean
    self.as(LspTestScript).clean
    @equipment['dut1'].send_cmd("rm /etc/systemd/system/docker.service.d/proxy.conf",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("mv ~/docker.service.orig /lib/systemd/system/docker.service",@equipment['dut1'].prompt)
end

def docker_hello_world()
    # Configure DNS so we can grab the docker image from Docker Hub
    @equipment['dut1'].send_cmd("echo 'nameserver 192.0.2.2' > /etc/resolv.conf",@equipment['dut1'].prompt)
    # Configure proxy settings for TI network
    @equipment['dut1'].send_cmd("mkdir -pv /etc/systemd/system/docker.service.d",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("echo [Service] > /etc/systemd/system/docker.service.d/proxy.conf",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("echo Environment=\\\"HTTP_PROXY=http://webproxy.ext.ti.com:80\\\""\
        " \\\"HTTPS_PROXY=http://webproxy.ext.ti.com:80\\\""\
        " \\\"NO_PROXY=design.ti.com,itg.ti.com,dhcp.ti.com,software-dl.ti.com\\\""\
        " >> /etc/systemd/system/docker.service.d/proxy.conf",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat /etc/systemd/system/docker.service.d/proxy.conf",@equipment['dut1'].prompt)
    # Docker images must be stored locally, so we need to change the defualt Docker image directory
    # when rootfs is mounted over NFS
    @equipment['dut1'].send_cmd("cp /lib/systemd/system/docker.service ~/docker.service.orig",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("sed -i '/\\/usr\\/bin\\/dockerd -H fd:\\/\\// s/$/ -g \\/run\\/media\\/mmcblk1p2\\/docker/' /lib/systemd/system/docker.service",@equipment['dut1'].prompt)
    @equipment['dut1'].send_cmd("cat /lib/systemd/system/docker.service",@equipment['dut1'].prompt)
    # Restart the Docker service to apply settings from above
    @equipment['dut1'].send_cmd("systemctl daemon-reload",@equipment['dut1'].prompt, 60)
    @equipment['dut1'].send_cmd("systemctl restart docker.service",@equipment['dut1'].prompt, 60)
    @equipment['dut1'].send_cmd("docker run hello-world",@equipment['dut1'].prompt, 120)
    docker_response = @equipment['dut1'].response
    if !(docker_response =~ /Hello\sfrom\sDocker!/)
        raise "Docker hello-world test failed."
    end
end
