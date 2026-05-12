#
#Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
#Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
#
set_param tcl.collectionResultDisplayLimit 0
set_param project.singleFileAddWarning.threshold 0
set_param runs.launchOptions { -jobs 8  }
set_param general.usePosixSpawnForFork 1
set_param chipscope.maxJobs 4
set_param synth.enableIncremental 0
set_param xicom.use_bs_reader 1
set_param chipscope.flow 0
set part xc7s25csga225-1
set board_part_repo_paths {C:/Users/arekr/AppData/Roaming/Xilinx/Vivado/2025.2/xhub/board_store/xilinx_board_store}
set board_part digilentinc.com:cmod-s7-25:part0:1.0
set board_connections {}
set tool_flow Vivado
set ip_vlnv xilinx.com:ip:ila:6.2
set ip_module_name u_ila_0
set params {{{PARAM_VALUE.ALL_PROBE_SAME_MU} {true} {PARAM_VALUE.ALL_PROBE_SAME_MU_CNT} {4} {PARAM_VALUE.C_ADV_TRIGGER} {true} {PARAM_VALUE.C_DATA_DEPTH} {2048} {PARAM_VALUE.C_EN_STRG_QUAL} {true} {PARAM_VALUE.C_INPUT_PIPE_STAGES} {0} {PARAM_VALUE.C_NUM_OF_PROBES} {5} {PARAM_VALUE.C_PROBE0_TYPE} {0} {PARAM_VALUE.C_PROBE0_WIDTH} {8} {PARAM_VALUE.C_PROBE1_TYPE} {0} {PARAM_VALUE.C_PROBE1_WIDTH} {8} {PARAM_VALUE.C_PROBE2_TYPE} {0} {PARAM_VALUE.C_PROBE2_WIDTH} {1} {PARAM_VALUE.C_PROBE3_TYPE} {0} {PARAM_VALUE.C_PROBE3_WIDTH} {1} {PARAM_VALUE.C_PROBE4_TYPE} {0} {PARAM_VALUE.C_PROBE4_WIDTH} {1} {PARAM_VALUE.C_TRIGIN_EN} {0} {PARAM_VALUE.C_TRIGOUT_EN} {0}}}
set intf_params {}
set connectivity {}
set output_xci c:/Users/arekr/OneDrive/Pulpit/Github/FPGA_Communication_System/FPGA_Comm/FPGA_Comm.runs/impl_1/.Xil/Vivado-19788-SolidnyLaptop/u_ila_0_CV.0/out/result.xci
set output_dcp c:/Users/arekr/OneDrive/Pulpit/Github/FPGA_Communication_System/FPGA_Comm/FPGA_Comm.runs/impl_1/.Xil/Vivado-19788-SolidnyLaptop/u_ila_0_CV.0/out/result.dcp
set output_dir c:/Users/arekr/OneDrive/Pulpit/Github/FPGA_Communication_System/FPGA_Comm/FPGA_Comm.runs/impl_1/.Xil/Vivado-19788-SolidnyLaptop/u_ila_0_CV.0/out
set ip_repo_paths {}
set ip_output_repo C:/Users/arekr/OneDrive/Pulpit/Github/FPGA_Communication_System/FPGA_Comm/FPGA_Comm.cache/ip
set ip_cache_permissions {read write}

set oopbus_ip_repo_paths [get_param chipscope.oopbus_ip_repo_paths]

set synth_opts {}
set xdc_files {}
