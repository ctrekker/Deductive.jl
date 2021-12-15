using PackageCompiler
PackageCompiler.create_sysimage(["Deductive"]; sysimage_path="sys_deductive.so", precompile_execution_file="precompile_execution.jl")
