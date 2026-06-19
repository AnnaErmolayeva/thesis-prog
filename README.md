# ConferenceRanking

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20025331.svg)](https://doi.org/10.5281/zenodo.20025331)

- Проект выполнен в диссертационного исследования.
- Репозиторий содержит код для моделирования и анализа динамики рейтингов научных конференций.
- Проект выполнен на языке Julia с использованием подхода DrWatson для обеспечения воспроизводимости исследований.

## Описание / Description

Данный проект посвящён построению и калибровке математической модели динамики рейтингов конференций. Модель представляет собой систему обыкновенных дифференциальных уравнений (ОДУ) для нескольких конкурирующих конференций, учитывающую:
- логистический рост рейтинга;
- кумулятивное преимущество (эффект «богатый становится богаче»);
- асимметричную конкуренцию между конференциями.

Калибровка модели выполняется на основе реальных данных о цитированиях (CPP – число цитирований на статью) за период с 2011 по 2020 год. Для оптимизации параметров используется метод LBFGS.

---

English

This project is dedicated to constructing and calibrating a mathematical model of the dynamics of conference rankings. The model is a system of ordinary differential equations (ODEs) for multiple competing conferences, taking into account:
- logistic growth of the ranking;
- cumulative advantage (the "rich get richer" effect);
- asymmetric competition between conferences.

Model calibration is performed using real citation data (CPP – citations per paper) for the period from 2011 to 2020. The LBFGS method is used for parameter optimization.

---

## Математическая модель / Mathematical Model

Система ОДУ для `n` конференций имеет вид:

```
du[i]/dt = r[i] * u[i] * (1 - Σⱼ αᵢⱼ * u[j] / K[i]) + μ[i] * u[i]
```

где:
- `u[i]` – рейтинг i-й конференции;
- `r[i]` – скорость роста;
- `K[i]` – ёмкость (максимально возможный рейтинг);
- `μ[i]` – скорость затухания (может быть отрицательной);
- `αᵢⱼ = exp(-λ * (u[i] - u[j]))` – асимметричный коэффициент конкуренции;
- `λ` – параметр, регулирующий силу конкуренции.

## Структура проекта / Project Structure

```
ConferenceRanking/
├── scripts/                    # Исполняемые скрипты
│   ├── dataset.jl              # Обработка и интерполяция данных
│   ├── calibrate_model.jl      # Калибровка модели по данным
│   ├── run_simulation.jl       # Запуск симуляции с заданными параметрами
│   ├── phase_portrait.jl       # Построение фазового портрета
│   └── generate_all_figures.jl # Генерация всех графиков
├── src/                        # Исходный код модулей
│   ├── model.jl                # Определение системы ОДУ
│   └── stability.jl            # Анализ устойчивости (опционально)
├── test/                       # Тесты
├── papers/                     # Связанные статьи и материалы
├── Project.toml                # Зависимости проекта
└── .gitattributes              # Настройки Git
```

## Требования / Requirements

- Julia 1.12.6 или выше
- Пакеты (устанавливаются автоматически через `Pkg.instantiate()`):
  - DrWatson
  - DifferentialEquations
  - Optimization, OptimizationOptimJL
  - CSV, DataFrames
  - Plots, PyPlot
  - ForwardDiff, Interpolations
  - LinearAlgebra, Statistics, Dates
  - ModelingToolkit, Symbolics
  - XLSX

## Установка и воспроизведение / Installation & Reproduction

Проект построен с использованием DrWatson, что гарантирует воспроизводимость.

1. Склонируйте репозиторий:
   ```bash
   git clone https://github.com/AnnaErmolayeva/thesis-prog.git
   cd thesis-prog/ConferenceRanking
   ```

2. Запустите Julia и активируйте проект:
   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.instantiate()
   ```

3. Подготовьте данные:
   - Поместите исходный файл `dataset.xlsx` в папку `data/raw/`.
   - Запустите скрипт обработки данных:
     ```julia
     include("scripts/dataset.jl")
     ```
   - Обработанные данные сохранятся в `data/processed/conference_cpp_interpolated.csv`.

4. Запустите калибровку модели:
   ```julia
   include("scripts/calibrate_model.jl")
   ```
   Результаты калибровки сохраняются в `data/calib/`.

5. Запустите симуляцию:
   ```julia
   include("scripts/run_simulation.jl")
   ```
   Результаты (решение ОДУ и график) сохраняются в `data/sim/` и `plots/` соответственно.

## Визуализация / Visualization

Проект включает скрипты для построения графиков:
- `run_simulation.jl` – временные ряды рейтингов;
- `phase_portrait.jl` – фазовые портреты для анализа устойчивости;
- `generate_all_figures.jl` – генерация всех рисунков для отчёта.

Все графики сохраняются в папку `plots/`.

## Лицензия / License

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.ru)

## Автор / Author

- Anna M. Ermolayeva
- GitHub: [AnnaErmolayeva](https://github.com/AnnaErmolayeva)

- Руководитель: Dmitry S. Kulyabov ([yamadharma](https://github.com/yamadharma))
