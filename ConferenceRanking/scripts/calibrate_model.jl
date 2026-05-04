using DrWatson
@quickactivate "ConferenceRanking"

using DifferentialEquations
using Optimization, OptimizationOptimJL
using CSV, DataFrames
using LinearAlgebra, Dates
using Statistics
using Plots

include(srcdir("model.jl"))
using .ModelCode

# Загрузка и подготовка данных
data_path = datadir("processed", "conference_cpp_interpolated.csv")
df = CSV.read(data_path, DataFrame)

# Выбираем конференции для калибровки (первые 5 по среднему CPP)
confs = names(df)[2:end]          # пропускаем столбец Year
avg_cpp = [mean(df[!, c]) for c in confs]
sorted_confs = confs[sortperm(avg_cpp, rev = true)]
selected = sorted_confs[1:min(5, length(sorted_confs))]

println("Калибровка для конференций: ", selected)

t_obs = Float64.(df[:, 1])
R_obs = Matrix(df[:, selected])'   # n_conf × n_time
n = length(selected)

# Нормализация
global_max = maximum(R_obs)
R_obs_norm = R_obs / global_max
u0 = R_obs_norm[:, 1]

# Функция потерь
function loss(p, _)
    r = p[1:n]
    K = p[(n+1):2n]
    μ = p[(2n+1):3n]
    λ = p[end]

    prob = ODEProblem(rhs!, u0, (t_obs[1], t_obs[end]), [r; K; μ; λ])
    sol = solve(prob, Tsit5(), saveat = t_obs)
    R_pred = reduce(hcat, sol.u)
    return sum((R_pred .- R_obs_norm) .^ 2)
end

# Начальные параметры
r0 = fill(0.5, n)
K0 = fill(1.0, n)
μ0 = fill(0.1, n)
λ0 = 1.0

p_init = [r0; K0; μ0; λ0]

# Границы
lb = [fill(0.01, n); fill(0.1, n); fill(-0.5, n); 0.0]
ub = [fill(2.0, n); fill(2.0, n); fill(0.5, n); 5.0]

# Оптимизация
adtype = Optimization.AutoFiniteDiff()
optf = OptimizationFunction(loss, adtype)
optprob = OptimizationProblem(optf, p_init; lb = lb, ub = ub)

# Используем LBFGS с конечными разностями (градиенты вычисляются численно)
res = solve(optprob, LBFGS(), maxiters = 1000)

# Альтернативно (без градиентов, но медленнее):
# res = solve(optprob, NelderMead(), maxiters=5000)

p_opt = res.u
final_loss = res.objective

println("Оптимизация завершена. Финальная потеря: $final_loss")
println("Оптимальные параметры:")
for i = 1:n
    println("  $(selected[i]): r=$(p_opt[i]), K=$(p_opt[n+i]), μ=$(p_opt[2n+i])")
end
println("  λ = $(p_opt[end])")

# Сохранение результатов
calib_result = Dict(
    "selected_conferences" => selected,
    "n_conferences" => n,
    "optimal_params" => p_opt,
    "initial_params" => p_init,
    "final_loss" => final_loss,
    "normalization_factor" => global_max,
    "time_span" => (t_obs[1], t_obs[end]),
    "timestamp" => Dates.now(),
    "data_file" => data_path,
)

save_dir = datadir("calib")
mkpath(save_dir)
time_str = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
save_path = joinpath(save_dir, "calibration.jld2")
wsave(save_path, calib_result)

println("Результат калибровки сохранён в: $save_path")

# Визуализация подгонки
if length(selected) <= 6
    prob_final = ODEProblem(rhs!, u0, (t_obs[1], t_obs[end]), p_opt)
    sol_final = solve(prob_final, Tsit5(), saveat = t_obs)
    R_final = reduce(hcat, sol_final.u) .* global_max

    p = plot(layout = (1, n), legend = :topleft, size = (300*n, 300))
    for i = 1:n
        plot!(
            p[i],
            t_obs,
            R_obs[i, :],
            label = "Data: $(selected[i])",
            lw = 2,
            color = :blue,
        )
        plot!(
            p[i],
            t_obs,
            R_final[i, :],
            label = "Model fit",
            lw = 2,
            linestyle = :dash,
            color = :red,
        )
        title!(p[i], selected[i])
    end
    plot_path = joinpath(plotsdir(), "calibration_fit.png")
    savefig(p, plot_path)
    println("График подгонки сохранён в: $plot_path")
else
    println("Пропуск графиков: слишком много конференций (>=6).")
end
