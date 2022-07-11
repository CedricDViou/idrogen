target = "altera"
action = "synthesis"

fetchto = "../../../ip_cores"

syn_family  = "Arria 10"
syn_device = "10ax027h4"
syn_grade = "i3sg"
syn_package = "f34"

syn_top = "idrogen_v3_wr_ref_design_top"
syn_project = "idrogen_v3_wr_ref_design"

syn_tool = "quartus"

syn_properties = [
    {"name": "VHDL_INPUT_VERSION", "value": "VHDL_2008"},
    {"name": "PHYSICAL_SYNTHESIS_EFFORT", "value": "NORMAL"}
]

quartus_preflow = "preflow.tcl"

files = [
  "preflow.tcl",
  ]

modules = {
  "local" : [ 
    "../../top/idrogen_v3_wr_ref_design", 
  ]
}

