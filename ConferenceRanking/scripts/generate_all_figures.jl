using DrWatson
@quickactivate "ConferenceRanking"

using Plots, DifferentialEquations
using LinearAlgebra
include(srcdir("model.jl"))
include(srcdir("stability.jl"))
using .ModelCode, .StabilityCode

gr()

# Параметры моделей

# Без закона Матфея (λ=0, μ=0) – классическая конкуренция
params_no_matthew = [0.5, 0.5, 10.0, 10.0, 0.0, 0.0, 0.0]   # [r1,r2,K1,K2,μ1,μ2,λ]

# С законом Матфея (λ>0, μ>0)
params_matthew = [0.5, 0.5, 10.0, 10.0, 0.1, 0.1, 1.0]

# Начальные условия для разных сценариев
u0_win1 = [7.0, 5.0]   # побеждает конференция 1
u0_win2 = [5.0, 7.0]   # побеждает конференция 2
u0_unstable = [6.0, 6.0]   # симметричное – неустойчивое равновесие (седло)

# Время моделирования
tspan = (0.0, 50.0)
t_eval = range(0, 50, length = 200)

# Функция для решения и построения временного ряда
function plot_timeseries(params, u0, title, output_name)
    prob = ODEProblem(rhs!, u0, tspan, params)
    sol = solve(prob, Tsit5(), saveat = t_eval)
    plt = plot(
        sol,
        idxs = (1, 2),
        xlabel = "Время t",
        ylabel = "Рейтинг R",
        label = ["Конференция 1" "Конференция 2"],
        linewidth = 2,
        linestyle = [:solid :dash],
        title = title,
        legend = :topright,
    )
    savefig(plotsdir(output_name))
    return plt
end

# Динамика без закона Матфея (λ=0)
plot_timeseries(
    params_no_matthew,
    u0_win1,
    "Динамика без закона Матфея (сохранение отношения)",
    "timeseries_no_matthew.png",
)

# Динамика с законом Матфея – победа конференции 1
plot_timeseries(
    params_matthew,
    u0_win1,
    "Закон Матфея – победа конференции 1",
    "timeseries_matthew_win1.png",
)

# Динамика с законом Матфея – победа конференции 2
plot_timeseries(
    params_matthew,
    u0_win2,
    "Закон Матфея – победа конференции 2",
    "timeseries_matthew_win2.png",
)

# Динамика с законом Матфея – неустойчивое равновесие (седло)
plot_timeseries(
    params_matthew,
    u0_unstable,
    "Неустойчивое равновесие (седло) при законе Матфея",
    "timeseries_matthew_unstable.png",
)

# Фазовый портрет для случая без закона Матфея
function phase_portrait_no_matthew(params; xlim = (0, 15), ylim = (0, 15))
    plt = plot(
        xlim = xlim,
        ylim = ylim,
        xlabel = "R₁",
        ylabel = "R₂",
        title = "Фазовый портрет без закона Матфея (λ=0)",
        legend = :topright,
    )
    # Поле направлений
    nx, ny = 20, 20
    xs = range(xlim[1], xlim[2], length = nx)
    ys = range(ylim[1], ylim[2], length = ny)
    X, Y, U, V = [], [], [], []
    for x in xs, y in ys
        du = [0.0, 0.0]
        rhs!(du, [x, y], params, 0.0)
        norm = sqrt(du[1]^2 + du[2]^2)
        if norm > 1e-8
            du ./= norm
        else
            du .= 0.0
        end
        push!(X, x);
        push!(Y, y);
        push!(U, du[1]);
        push!(V, du[2])
    end
    quiver!(plt, X, Y, quiver = (U, V), color = :gray, alpha = 0.5)
    # Линия равновесий: R1+R2 = K (r+μ)/r = 10 (т.к. μ=0)
    line_x = range(0, 15, length = 100)
    line_y = 10 .- line_x
    plot!(plt, line_x, line_y, color = :red, linewidth = 2, label = "Линия равновесий")
    return plt
end

portrait_no = phase_portrait_no_matthew(params_no_matthew)
savefig(plotsdir("phase_portrait_no_matthew.png"))

# Фазовый портрет для случая с законом Матфея (λ>0)
function phase_portrait_matthew(params; xlim = (0, 15), ylim = (0, 15))
    plt = plot(
        xlim = xlim,
        ylim = ylim,
        xlabel = "R₁",
        ylabel = "R₂",
        title = "Фазовый портрет с законом Матфея (λ=1, μ=0.1)",
        legend = :topright,
    )
    # Поле направлений
    nx, ny = 20, 20
    xs = range(xlim[1], xlim[2], length = nx)
    ys = range(ylim[1], ylim[2], length = ny)
    X, Y, U, V = [], [], [], []
    for x in xs, y in ys
        du = [0.0, 0.0]
        rhs!(du, [x, y], params, 0.0)
        norm = sqrt(du[1]^2 + du[2]^2)
        if norm > 1e-8
            du ./= norm
        else
            du .= 0.0
        end
        push!(X, x);
        push!(Y, y);
        push!(U, du[1]);
        push!(V, du[2])
    end
    quiver!(plt, X, Y, quiver = (U, V), color = :gray, alpha = 0.5)

    # Стационарные точки
    r = params[1];
    K = params[3];
    μ = params[5];
    λ = params[end]
    R_sym = K/2 * (1 + μ/r)
    R_bound = K * (1 + μ/r)
    scatter!(plt, [R_bound], [0], color = :green, markersize = 6, label = "Устойчивый узел")
    scatter!(plt, [0], [R_bound], color = :green, markersize = 6, label = "")
    scatter!(plt, [R_sym], [R_sym], color = :red, markersize = 6, label = "Седло")

    # Несколько траекторий для наглядности
    init_points = [[6.1, 5.9], [5.9, 6.1], [2, 8], [8, 2], [4, 4], [12, 1]]
    for u0 in init_points
        prob = ODEProblem(rhs!, u0, (0, 30), params)
        sol = solve(prob, Tsit5())
        plot!(plt, sol, idxs = (1, 2), lw = 1.5, alpha = 0.7, color = :blue, label = "")
    end
    return plt
end

portrait_mat = phase_portrait_matthew(params_matthew)
savefig(plotsdir("phase_portrait_matthew.png"))

println("Все графики сохранены в папку plots/")
