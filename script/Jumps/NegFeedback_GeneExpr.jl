
using JumpProcesses, Catalyst, JumpProblemLibrary, Plots, Statistics
import JumpProblemLibrary: prob_jump_dnarepressor
fmt = :png


rn = prob_jump_dnarepressor.network
reactions(rn)


methods = (Direct(), FRM(), SortingDirect(), NRM(), DirectCR(), RSSA(), RSSACR())
shortlabels = [string(leg)[15:end-2] for leg in methods]
prob    = prob_jump_dnarepressor.discrete_prob
tf      = prob_jump_dnarepressor.tstop
ploth   = plot(reuse=false)
for (i,method) in enumerate(methods)
    jump_prob = JumpProblem(rn, prob, method, save_positions=(false, false))
    sol = solve(jump_prob, SSAStepper(), saveat=tf/1000.)
    plot!(ploth,sol.t, sol[3,:], label=shortlabels[i], format=fmt)
end
plot(ploth, title="Protein level", xlabel="time", format=fmt)


function run_benchmark!(t, jump_prob, stepper)
    sol = solve(jump_prob, stepper)
    @inbounds for i in 1:length(t)
        t[i] = @elapsed (sol = solve(jump_prob, stepper))
    end
end


nsims = 2000
benchmarks = Vector{Vector{Float64}}()
for method in methods
    jump_prob = JumpProblem(rn, prob, method, save_positions=(false, false))
    stepper = SSAStepper()
    t = Vector{Float64}(undef,nsims)
    run_benchmark!(t, jump_prob, stepper)
    push!(benchmarks, t)
end


medtimes = Vector{Float64}(undef, length(methods))
stdtimes = Vector{Float64}(undef, length(methods))
avgtimes = Vector{Float64}(undef, length(methods))
for i in 1:length(methods)
    medtimes[i] = median(benchmarks[i])
    avgtimes[i] = mean(benchmarks[i])
    stdtimes[i] = std(benchmarks[i])
end
println(medtimes/medtimes[1])


using DataFrames
df = DataFrame(names=shortlabels, medtimes=medtimes, relmedtimes=(medtimes/medtimes[1]),
               avgtimes=avgtimes, std=stdtimes, cv=stdtimes./avgtimes)
sa = [text(string(round(mt,sigdigits=2),"s"),:center,10) for mt in df.medtimes]
bar(df.names,df.relmedtimes,legend=:false, fmt=fmt)
scatter!(df.names, .05 .+ df.relmedtimes, markeralpha=0, series_annotations=sa, fmt=fmt)
ylabel!("median relative to Direct")
title!("Negative Feedback Gene Expression Model")


using SciMLBenchmarks
SciMLBenchmarks.bench_footer(WEAVE_ARGS[:folder],WEAVE_ARGS[:file])

