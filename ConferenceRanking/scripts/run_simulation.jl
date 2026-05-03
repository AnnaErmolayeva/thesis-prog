using DrWatson
@quickactivate "ConferenceRanking"

using DifferentialEquations, Plots
using Dates
include(srcdir("model.jl"))
include(srcdir("stability.jl"))
using .ModelCode, .StabilityCode

# Параметры симуляции
n = 2
u0 = [6.0, 6.0]
tspan = (0.0, 50.0)

# Параметры модели: [r1, r2, K1, K2, μ1, μ2, λ]
p = [0.5, 0.5, 10.0, 10.0, 0.1, 0.1, 1.0]

# Решение
prob = ODEProblem(rhs!, u0, tspan, p)
sol = solve(prob, Tsit5(), saveat = 1.0)

# Метаданные
sim_params = Dict(
    "n" => n,
    "u0" => u0,
    "r" => p[1:n],
    "K" => p[(n+1):2n],
    "μ" => p[(2n+1):3n],
    "λ" => p[end],
    "solver" => "Tsit5",
    "timestamp" => Dates.now(),
)

# Уникальное имя файла с временем
time_str = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
sim_path = datadir("sim_$(n)confs.jld2")
wsave(sim_path, Dict("params" => sim_params, "solution" => sol))
println("Симуляция сохранена в: $sim_path")

# График
plt = plot(
    sol,
    xlabel = "Время",
    ylabel = "Рейтинг R(t)",
    label = ["Конференция 1" "Конференция 2"],
    title = "Динамика рейтинга",
)
plot_path = plotsdir("timeseries_$(n)confs.png")
savefig(plt, plot_path)
println("График сохранен в: $plot_path")
