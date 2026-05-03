module StabilityCode

using LinearAlgebra, ForwardDiff
import ..ModelCode: rhs!

export compute_jacobian, classify_fixed_point

"""
    compute_jacobian(u, p)

Вычисляет матрицу Якоби в точке `u` с помощью автоматического дифференцирования.
"""
function compute_jacobian(u, p)
    # Определяем функцию, от которой будем брать производную
    f(x) = rhs!(similar(x), x, p, 0.0)
    return ForwardDiff.jacobian(f, u)
end

"""
    classify_fixed_point(J)

Классифицирует особую точку по собственным значениям матрицы Якоби.
"""
function classify_fixed_point(J)
    λs = eigvals(J)
    if all(real.(λs) .< 0)
        return "Устойчивый узел"
    elseif all(real.(λs) .> 0)
        return "Неустойчивый узел"
    elseif any(real.(λs) .> 0) && any(real.(λs) .< 0)
        return "Седло"
    elseif any(imag.(λs) .!= 0)
        return "Фокус"
    else
        return "Центр / Вырожденный узел"
    end
end

end # module
