
# Single pendulums shall be solved numerically.
#
using OrdinaryDiffEq, Elliptic, Printf, DiffEqPhysics, Statistics

sol2q(sol) = [sol.u[i][j] for i in 1:length(sol.u), j in 1:length(sol.u[1])÷2]
sol2p(sol) = [sol.u[i][j] for i in 1:length(sol.u), j in length(sol.u[1])÷2+1:length(sol.u[1])]
sol2tqp(sol) = (sol.t, sol2q(sol), sol2p(sol))

# The exact solutions of single pendulums can be expressed by the Jacobian elliptic functions.
#
sn(u, k) = Jacobi.sn(u, k^2) # the Jacobian sn function

# Use PyPlot.
#
using PyPlot

colorlist = [
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf",
]
cc(k) = colorlist[mod1(k, length(colorlist))]

# plot the sulution of a Hamiltonian problem
#
function plotsol(sol::ODESolution)
    local t, q, p
    t, q, p = sol2tqp(sol)
    local d = size(q)[2]
    for j in 1:d
        j_str = d > 1 ? "[$j]" : ""
        plot(t, q[:,j], color=cc(2j-1), label="q$(j_str)", lw=1)
        plot(t, p[:,j], color=cc(2j),   label="p$(j_str)", lw=1, ls="--")
    end
    grid(ls=":")
    xlabel("t")
    legend()
end

# plot the solution of a Hamiltonian problem on the 2D phase space
#
function plotsol2(sol::ODESolution)
    local t, q, p
    t, q, p = sol2tqp(sol)
    local d = size(q)[2]
    for j in 1:d
        j_str = d > 1 ? "[$j]" : ""
        plot(q[:,j], p[:,j], color=cc(j), label="(q$(j_str),p$(j_str))", lw=1)
    end
    grid(ls=":")
    xlabel("q")
    ylabel("p")
    legend()
end

# plot the energy of a Hamiltonian problem
#
function plotenergy(H, sol::ODESolution)
    local t, q, p
    t, q, p = sol2tqp(sol)
    local energy = [H(q[i,:], p[i,:], nothing) for i in 1:size(q)[1]]
    plot(t, energy, label="energy", color="red", lw=1)
    grid(ls=":")
    xlabel("t")
    legend()
    local stdenergy_str = @sprintf("%.3e", std(energy))
    title("                    std(energy) = $stdenergy_str", fontsize=10)
end

# plot the numerical and exact solutions of a single pendulum
#
# Warning: Assume q(0) = 0, p(0) = 2k.   (for the sake of laziness)
#
function plotcomparison(k, sol::ODESolution)
    local t, q, p
    t, q, p = sol2tqp(sol)
    local y = sin.(q/2)
    local y_exact = k*sn.(t, k) # the exact solution

    plot(t, y,       label="numerical", lw=1)
    plot(t, y_exact, label="exact",     lw=1, ls="--")
    grid(ls=":")
    xlabel("t")
    ylabel("y = sin(q(t)/2)")
    legend()
    local error_str = @sprintf("%.3e", maximum(abs.(y - y_exact)))
    title("maximum(abs(numerical - exact)) = $error_str", fontsize=10)
end

# plot solution and energy
#
function plotsolenergy(H, integrator, Δt, sol::ODESolution)
    local integrator_str = replace("$integrator", r"^[^.]*\." => "")

    figure(figsize=(10,8))

    subplot2grid((21,20), ( 1, 0), rowspan=10, colspan=10)
    plotsol(sol)

    subplot2grid((21,20), ( 1,10), rowspan=10, colspan=10)
    plotsol2(sol)

    subplot2grid((21,20), (11, 0), rowspan=10, colspan=10)
    plotenergy(H, sol)

    suptitle("=====    $integrator_str,   Δt = $Δt    =====")
end

# Solve a single pendulum
#
function singlependulum(k, integrator, Δt; t0 = 0.0, t1 = 100.0)
    local H(p,q,params) = p[1]^2/2 - cos(q[1]) + 1
    local q0 = [0.0]
    local p0 = [2k]
    local prob = HamiltonianProblem(H, p0, q0, (t0, t1))

    local integrator_str = replace("$integrator", r"^[^.]*\." => "")
    @printf("%-25s", "$integrator_str:")
    sol = solve(prob, integrator, dt=Δt)
    @time local sol = solve(prob, integrator, dt=Δt)

    sleep(0.1)
    figure(figsize=(10,8))

    subplot2grid((21,20), ( 1, 0), rowspan=10, colspan=10)
    plotsol(sol)

    subplot2grid((21,20), ( 1,10), rowspan=10, colspan=10)
    plotsol2(sol)

    subplot2grid((21,20), (11, 0), rowspan=10, colspan=10)
    plotenergy(H, sol)

    subplot2grid((21,20), (11,10), rowspan=10, colspan=10)
    plotcomparison(k, sol)

    suptitle("=====    $integrator_str,   Δt = $Δt    =====")
end


# Single pendulum

k = rand()
integrator = VelocityVerlet()
Δt = 0.1
singlependulum(k, integrator, Δt, t0=-20.0, t1=20.0)


# Two single pendulums

H(q,p,param) = sum(p.^2/2 .- cos.(q) .+ 1)
q0 = pi*rand(2)
p0 = zeros(2)
t0, t1 = -20.0, 20.0
prob = HamiltonianProblem(H, q0, p0, (t0, t1))

integrator = McAte4()
Δt = 0.1
sol = solve(prob, integrator, dt=Δt)
@time sol = solve(prob, integrator, dt=Δt)

sleep(0.1)
plotsolenergy(H, integrator, Δt, sol)


SymplecticIntegrators = [
    SymplecticEuler(),
    VelocityVerlet(),
    VerletLeapfrog(),
    PseudoVerletLeapfrog(),
    McAte2(),
    Ruth3(),
    McAte3(),
    CandyRoz4(),
    McAte4(),
    CalvoSanz4(),
    McAte42(),
    McAte5(),
    Yoshida6(),
    KahanLi6(),
    McAte8(),
    KahanLi8(),
    SofSpa10(),
]

k = 0.999
Δt = 0.1
for integrator in SymplecticIntegrators
    singlependulum(k, integrator, Δt)
end


k = 0.999
Δt = 0.01
for integrator in SymplecticIntegrators[1:4]
    singlependulum(k, integrator, Δt)
end


k = 0.999
Δt = 0.001
singlependulum(k, SymplecticEuler(), Δt)


k = 0.999
Δt = 0.0001
singlependulum(k, SymplecticEuler(), Δt)


using SciMLBenchmarks
SciMLBenchmarks.bench_footer(WEAVE_ARGS[:folder],WEAVE_ARGS[:file])

