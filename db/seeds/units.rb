Unit.transaction do
  ActiveRecord::Base.connection.truncate(Unit.table_name)
  units = {}

  units['1'] =
    Unit.create symbol: '1',
                description: 'dimensionless, one'
  units['ppm'] =
    Unit.create symbol: 'ppm', base: units['1'], multiplier: '1e-6',
                description: 'parts per million'
  units['‱'] =
    Unit.create symbol: '‱', base: units['1'], multiplier: '1e-4',
                description: 'basis point'
  units['‰'] =
    Unit.create symbol: '‰', base: units['1'], multiplier: '1e-3',
                description: 'promille'
  units['%'] =
    Unit.create symbol: '%', base: units['1'], multiplier: '1e-2',
                description: 'percent'

  units['g'] =
    Unit.create symbol: 'g',
                description: 'gram'
  units['µg'] =
    Unit.create symbol: 'µg', base: units['g'], multiplier: '1e-6',
                description: 'microgram'
  units['mg'] =
    Unit.create symbol: 'mg', base: units['g'], multiplier: '1e-3',
                description: 'milligram'
  units['kg'] =
    Unit.create symbol: 'kg', base: units['g'], multiplier: '1e3',
                description: 'kilogram'

  units['kcal'] =
    Unit.create symbol: 'kcal',
                description: 'kilocalorie'
end
