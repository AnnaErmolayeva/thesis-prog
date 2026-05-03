module ModelCode

export rhs!

"""
    rhs!(du, u, p, t)

Вычисляет правую часть системы ОДУ для n конкурирующих конференций.
Параметры `p` упакованы в вектор: [r1..rn, K1..Kn, μ1..μn, λ].
"""
function rhs!(du, u, p, t)
    n = length(u)                     # количество конференций
    # Извлекаем параметры из плоского вектора p
    r = @view p[1:n]
    K = @view p[(n+1):2n]
    μ = @view p[(2n+1):3n]
    λ = p[end]

    for i = 1:n
        sum_term = 0.0
        for j = 1:n
            # Асимметричный коэффициент конкуренции, основанный на разнице рейтингов
            α_ij = exp(-λ * (u[i] - u[j]))
            sum_term += α_ij * u[j]
        end
        # Логистический рост с кумулятивным преимуществом
        du[i] = r[i] * u[i] * (1 - sum_term / K[i]) + μ[i] * u[i]
    end
end

end # module
