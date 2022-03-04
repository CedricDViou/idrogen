target = "altera"
action = "synthesis"

fetchto = "../../../ip_cores"
syn_tool = "quartus"

syn_family  = "Arria 10"
syn_device = "10AX027H4"
syn_grade = "I3SG"
syn_package = "F34"
syn_top = "idrogen_v3_ref_design_top"
syn_project = "idrogen_v3_ref_design"

quartus_preflow = "preflow.tcl"

modules = {
  "local" : [ 
    "../../top/idrogen_v3_ref_design", 
  ]
}

