def __helper():
  dirs = []
  if syn_device[:9] == "10AX027H4":      dirs.extend(["arria10"])
  return dirs

files = [
  "pll_pkg.vhd",
  ]
  
modules = {"local": __helper() }

