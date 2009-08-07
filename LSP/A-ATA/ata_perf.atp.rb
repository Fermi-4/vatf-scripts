require '../../TestPlans/LSP/Common/fs_perf.atp.rb'

#---
#:section: General
# Test Area:: ATA
# Test Type:: Performance
# Test Owners:: Asha (TII), Yan Liu (TIGT)
#---

#---
#:section: Overview
# These test cases measure the read and write performance of the ATA (Hard Disk) driver.
# The performance is measured using different filesystem types and buffer sizes. Typically, 
# the data measured on these test cases is used to populate the device driver datasheet document.
#---

#---
#:section: References
# None.
#---

#---
#:section: Required Hardware
# No special hardware is required for this test. This test is only applicable to EVMs with
# built-in hard disks.
#---

#---
#:section: Setup
# There is no external test equipment. The typical automation setup of VATF PC, PortMaster and APC
# can be used.
#
# link:../ATP_LSP_Ata.jpg
#---

#---
#:section: Test Focus
# The focus is to measure ATA driver's file write and file read speed in Mbytes/sec.
#---

#---
#:section: Tests not included/ Future Enhancements
# * CF -- Compact Flash 
# * SATA -- Serial ATA
#---

#---
#:section: Test Parameters & Constraints
# See get_params() method at Ata_perfTestPlan class
#---




class Ata_perfTestPlan < Fs_perfTestPlan
    
  # BEG_USR_CFG get_params
  def get_params()
    this_params = 
    {
      'filesystem'   => ['ext2', 'ext3'],
      'dev_node'     => ['/dev/hda1'],
      'mount_point'  => ['/mnt/ata'],
    }
    super().merge(this_params)
  end
  # END_USR_CFG get_params
  
end
