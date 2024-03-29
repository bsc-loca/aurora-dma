# Copyright 2022 Barcelona Supercomputing Center-Centro Nacional de Supercomputación

# Licensed under the Solderpad Hardware License v 2.1 (the "License");
# you may not use this file except in compliance with the License, or, at your option, the Apache License version 2.0.
# You may obtain a copy of the License at
#
#     http://www.solderpad.org/licenses/SHL-2.1
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Author: Alexander Kropotov, BSC-CNS
# Date: 09.05.2023
# Description:

# Parameters to apply:
# $1 FPGA_BOARD:      u55c / u280
# $2 QSFP_PORT:       qsfp0 / qsfp1
# $3 DMA_MEM:         hbm / sram
# $4 SAXI_FREQ in Hz: 100000000
# $5 SAXI_PROTOCOL:   AXI4LITE-64 / AXI4-512 /...

namespace eval _tcl {
proc get_script_folder {} {
    set script_path [file normalize [info script]]
    set script_folder [file dirname $script_path]
    return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

puts "The environment tcl will be sourced from ${script_folder}"
source $script_folder/environment.tcl

# Redefine the FPGA part in case the script is called with arguments
# It defaults to u280
if { $::argc > 0 } {

        set g_board_part [lindex $argv 0]
        set g_fpga_part "xc${g_board_part}-fsvh2892-2L-e"
        if { $::argc > 1 } {
          set g_eth_port [lindex $argv 1]
        }
        if { $::argc > 2 } {
          set g_dma_mem  [lindex $argv 2]
        }
        if { $::argc > 3 } {
          set g_saxi_freq  [lindex $argv 3]
        }
        if { $::argc > 3 } {
          set g_saxi_prot  [lindex $argv 4]
        }
}

set root_dir $g_root_dir

################################################################
# START
################################################################

set g_project_name $g_project_name
set projec_dir $root_dir/project

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
    create_project $g_project_name $projec_dir -force -part $g_fpga_part
}
# Set project properties
# CHANGE DESIGN NAME HERE
variable design_name
set design_name $g_project_name
set ip_dir_list [list \
     $root_dir/ip]

set_property  ip_repo_paths  $ip_dir_list [current_project]

if { $g_useBlockDesign eq "y" } {
  # create_bd_design -dir $root_dir/bd ${design_name}
  # update_ip_catalog -rebuild

  # creating isolated Aurora subsystem BD
  source $root_dir/tcl/aur_syst_bd.tcl
  cr_bd_aurora_dma ""
  # creating the IP of isolated Aurora subsystem
  source $root_dir/tcl/aur_syst_ip.tcl
  # also just extracting hw parameters from TCL and creating C-header
  source $root_dir/tcl/aur_syst_xparams.tcl

} else {

  source $root_dir/ip/aurora6466b.tcl
  source $root_dir/ip/axi_dma.tcl
  source $root_dir/ip/axi_subset_converter.tcl

  set g_top_name ${g_project_name}_top
  set top_module "$root_dir/src/${g_top_name}.vhd"
  set src_files [glob ${root_dir}/src/*]
  set ip_files [glob -nocomplain ${root_dir}/ip/*/*.xci]
  add_files ${src_files}
  add_files -quiet ${ip_files}

  set_property target_language VHDL [current_project]
  source $root_dir/tcl/project_options.tcl
  source $root_dir/tcl/gen_ip.tcl
}

# Add Constraint files to project
# TODO: Add Out Of Context constraints in case it is necessary in the future
#add_files -fileset [get_filesets constrs_1] "$root_dir/xdc/${g_project_name}_pinout.xdc"
#add_files -fileset [get_filesets constrs_1] "$root_dir/xdc/${g_project_name}_timing.xdc"
#add_files -fileset [get_filesets constrs_1] "$root_dir/xdc/${g_project_name}_ila.xdc"
#add_files -fileset [get_filesets constrs_1] "$root_dir/xdc/${g_project_name}_alveo280.xdc"

puts "Project generation ended successfully"
#source $root_dir/tcl/gen_runs.tcl
#source $root_dir/tcl/gen_bitstream.tcl
