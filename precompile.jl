using PackageCompiler

import Pkg
Pkg.activate(".")

PackageCompiler.create_sysimage([:Deductive]; sysimage_path="sys_deductive.so", precompile_execution_file="precompile_execution.jl")
