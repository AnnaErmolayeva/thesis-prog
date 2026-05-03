using DrWatson, XLSX, DataFrames, CSV, Interpolations

@quickactivate "ConferenceRanking"

datafile = datadir("raw", "dataset.xlsx")
xf = XLSX.openxlsx(datafile)
sheet = xf["ALL"]

nrows = length(eachrow(sheet))
years = 2011:2020
cpp_cols = 26:35

conferences = String[]
cpp_data = Dict{String,Vector{Float64}}()

for row = 3:nrows
    name = strip(string(sheet[row, 1]))
    if name == "" || occursin("conference", lowercase(name))
        continue
    end
    raw = [sheet[row, col] for col in cpp_cols]
    row_vals = [ismissing(v) ? NaN : float(v) for v in raw]
    push!(conferences, name)
    cpp_data[name] = row_vals
end

# Интерполяция
function interpolate_series(v::Vector{Float64}, years::AbstractVector, method = :linear)
    n = length(v)
    ok = .!isnan.(v)
    if sum(ok) < 2
        return fill(NaN, n)
    end
    x_ok = years[ok]
    y_ok = v[ok]
    if method == :linear
        itp = LinearInterpolation(x_ok, y_ok, extrapolation_bc = NaN)
        return itp.(years)
    elseif method == :cubic
        itp = CubicSplineInterpolation(x_ok, y_ok, extrapolation_bc = NaN)
        return itp.(years)
    else
        error("Unknown method")
    end
end

interp_method = :linear
interpolated = Dict{String,Vector{Float64}}()
for (name, vals) in cpp_data
    interpolated[name] = interpolate_series(vals, years, interp_method)
end

valid_confs = []
for (name, vals) in interpolated
    if sum(.!isnan.(vals)) >= 2
        push!(valid_confs, name)
    end
end

df = DataFrame(Year = collect(years))
for name in valid_confs
    df[!, name] = interpolated[name]
end

# Заполняем краевые NaN первым/последним известным значением
for name in valid_confs
    col = df[!, name]
    first_nonnan = findfirst(.!isnan.(col))
    if !isnothing(first_nonnan) && first_nonnan > 1
        col[1:(first_nonnan-1)] .= col[first_nonnan]
    end
    last_nonnan = findlast(.!isnan.(col))
    if !isnothing(last_nonnan) && last_nonnan < length(col)
        col[(last_nonnan+1):end] .= col[last_nonnan]
    end
end

save_path = datadir("processed", "conference_cpp_interpolated.csv")
mkpath(datadir("processed"))
CSV.write(save_path, df)
println("Данные с интерполяцией сохранены в $save_path")
