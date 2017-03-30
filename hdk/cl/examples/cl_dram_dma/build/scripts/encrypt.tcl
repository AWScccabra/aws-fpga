# Amazon FPGA Hardware Development Kit
#
# Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Amazon Software License (the "License"). You may not use
# this file except in compliance with the License. A copy of the License is
# located at
#
#    http://aws.amazon.com/asl/
#
# or in the "license" file accompanying this file. This file is distributed on
# an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
# implied. See the License for the specific language governing permissions and
# limitations under the License.

# TODO:
# Add check if CL_DIR and HDK_SHELL_DIR directories exist
# Add check if /build and /build/src_port_encryption directories exist
# Add check if the vivado_keyfile exist

set HDK_SHELL_DIR $::env(HDK_SHELL_DIR)
set CL_DIR $::env(CL_DIR)

set TARGET_DIR $CL_DIR/build/src_post_encryption
set UNUSED_TEMPLATES_DIR $HDK_SHELL_DIR/design/interfaces


# Remove any previously encrypted files, that may no longer be used
exec rm -f $TARGET_DIR/*

#---- Developr would replace this section with design files ----

## Change file names and paths below to reflect your CL area.  DO NOT include AWS RTL files.
file copy -force $CL_DIR/../common/design/cl_common_defines.vh     $TARGET_DIR
file copy -force $CL_DIR/design/cl_dram_dma_defines.vh             $TARGET_DIR
file copy -force $CL_DIR/design/cl_id_defines.vh                   $TARGET_DIR
file copy -force $CL_DIR/design/cl_dram_dma_pkg.sv                 $TARGET_DIR
file copy -force $CL_DIR/design/cl_dram_dma.sv                     $TARGET_DIR
file copy -force $CL_DIR/design/cl_tst.sv                          $TARGET_DIR
file copy -force $CL_DIR/design/cl_int_tst.sv                      $TARGET_DIR
file copy -force $CL_DIR/design/mem_scrb.sv                        $TARGET_DIR
file copy -force $CL_DIR/design/cl_tst_scrb.sv                     $TARGET_DIR
file copy -force $CL_DIR/design/axil_slave.sv                      $TARGET_DIR
file copy -force $CL_DIR/design/cl_int_slv.sv                      $TARGET_DIR
file copy -force $CL_DIR/design/cl_mstr_axi_tst.sv                 $TARGET_DIR
file copy -force $CL_DIR/design/cl_pcim_mstr.sv                    $TARGET_DIR
file copy -force $CL_DIR/design/cl_vio.sv                          $TARGET_DIR
file copy -force $CL_DIR/design/cl_dma_pcis_slv.sv                 $TARGET_DIR
file copy -force $CL_DIR/design/cl_ila.sv                          $TARGET_DIR
file copy -force $CL_DIR/design/cl_ocl_slv.sv                      $TARGET_DIR 
file copy -force $CL_DIR/design/cl_sda_slv.sv                      $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_aurora_template.inc  $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_hmc_template.inc     $TARGET_DIR
file copy -force $UNUSED_TEMPLATES_DIR/unused_sh_bar1_template.inc $TARGET_DIR

#---- End of section replaced by Developr ---



# Make sure files have write permissions for the encryption

exec chmod +w {*}[glob $TARGET_DIR/*]


encrypt -k $HDK_SHELL_DIR/build/scripts/vivado_keyfile.txt -lang verilog [ glob $TARGET_DIR/*.* ]

