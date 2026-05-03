using DrWatson
@quickactivate "ConferenceRanking"

using Plots, DifferentialEquations, Dates
include(srcdir("model.jl"))
using .ModelCode

# Параметры модели (две конференции)
p = [0.5, 0.5, 10.0, 10.0, 0.1, 0.1, 1.0]

# Границы фазовой плоскости
xlim = (0.0, 15.0)
ylim = (0.0, 15.0)

function plot_quiver!(plt, rhs!, params, xlim, ylim; nx = 20, ny = 20)
    xs = range(xlim[1], xlim[2], length = nx)
    ys = range(ylim[1], ylim[2], length = ny)
    X = Float64[];
    Y = Float64[];
    U = Float64[];
    V = Float64[]
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
    quiver!(plt, X, Y, quiver = (U, V), color = :gray, alpha = 0.5, linewidth = 0.8)
end

function plot_phase_portrait(params; xlim = (0, 15), ylim = (0, 15))
    plt = plot(
        xlim = xlim,
        ylim = ylim,
        xlabel = "Рейтинг R₁",
        ylabel = "Рейтинг R₂",
        title = "Фазовый портрет с законом Матфея",
        legend = :topright,
    )
    plot_quiver!(plt, rhs!, params, xlim, ylim, nx = 20, ny = 20)

    r = params[1];
    K = params[3];
    μ = params[5]
    R_sym = K/2 * (1 + μ/r)
    R_bound = K * (1 + μ/r)

    scatter!(plt, [R_bound], [0], color = :green, markersize = 6, label = "Устойчивый узел")
    scatter!(plt, [0], [R_bound], color = :green, markersize = 6, label = "")
    scatter!(plt, [R_sym], [R_sym], color = :red, markersize = 6, label = "Седло")

    init_points = [
        [6.1, 5.9],
        [5.9, 6.1],
        [2.0, 8.0],
        [8.0, 2.0],
        [4.0, 4.0],
        [12.0, 1.0],
        [1.0, 12.0],
    ]
    for u0 in init_points
        prob = ODEProblem(rhs!, u0, (0.0, 30.0), params)
        sol = solve(prob, Tsit5())
        plot!(plt, sol, idxs = (1, 2), lw = 1.5, alpha = 0.7, color = :blue, label = "")
    end
    return plt
end

portrait = plot_phase_portrait(p, xlim = xlim, ylim = ylim)
mkpath(plotsdir())
time_str = Dates.format(now(), "yyyy-mm-dd_HH-MM-SS")
filename = joinpath(plotsdir(), "phase_portrait.png")
savefig(portrait, filename)
println("Фазовый портрет сохранён: $filename")
