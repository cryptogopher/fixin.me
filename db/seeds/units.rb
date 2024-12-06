Unit.transaction do
  Unit.defaults.delete_all

  unit_1 =
    Unit.create symbol: "1",
                description: "dimensionless, one"
  unit_ppm =
    Unit.create symbol: "ppm", base: unit_1, multiplier: 1e-6,
                description: "parts per million"
  unit_‱ =
    Unit.create symbol: "‱", base: unit_1, multiplier: 1e-4,
                description: "basis point"
  unit_‰ =
    Unit.create symbol: "‰", base: unit_1, multiplier: 1e-3,
                description: "promille"
  unit_% =
    Unit.create symbol: "%", base: unit_1, multiplier: 1e-2,
                description: "percent"

  unit_g =
    Unit.create symbol: "g",
                description: "gram"
  unit_ug =
    Unit.create symbol: "ug", base: unit_g, multiplier: 1e-6,
                description: "microgram"
  unit_mg =
    Unit.create symbol: "mg", base: unit_g, multiplier: 1e-3,
                description: "milligram"
  unit_kg =
    Unit.create symbol: "kg", base: unit_g, multiplier: 1e3,
                description: "kilogram"

  unit_kcal =
    Unit.create symbol: "kcal",
                description: "kilocalorie"
end
