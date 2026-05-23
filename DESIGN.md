DESIGN
======

Below is a list of design decisions. The justification is to be consulted
whenever a change is considered, to avoid regressions.

### Data type for DB storage of numeric values (`decimal` vs `float`)

* among database engines supported (by Rails), SQLite offers storage of
  `decimal` data type with the lowest precision, equal to the precision of
  `REAL` type (double precision float value, IEEE 754), but in a floating point
  format,
    * decimal types in other database engines offer greater precision, but store
      data in a fixed point format,
* biology-related values differ by several orders of magnitude; storing them in
  fixed point format would only make sense if required precision would be
  greater than that offered by floating point format,
    * even then, fixed point would mean either bigger memory requirements or
      worse precision for numbers close to scale limit,
        * for a fixed point format to use the same 8 bytes of storage as IEEE
          754, precision would need to be limited to 18 digits (4 bytes/9 digits)
          and scale approximately half of that - 9,
    * double precision floating point guarantees 15 digits of precision, which
      is more than enough for all expected use cases,
        * if a decimal string with at most 15 significant digits is converted to
          the IEEE 754 double-precision format, giving a normal number, and then
          converted back to a decimal string with the same number of digits, the
          final result should match the original string,
        * if an IEEE 754 double-precision number is converted to a decimal
          string with at least 17 significant digits, and then converted back to
          double-precision representation, the final result must match the
          original number,
        * single precision floating point only guarntees 6 digits of precision,
          which is estimated to be too low for some use cases (e.g. storing
          latitude/longitude with a resolution grater than 100m),
* double precision floating point (IEEE 754) is a standard that ensures
  compatibility with majority of database engines,
    * the same data format is used internally by Ruby as a `Float`; it
      guarantees no conversions between storage and computation,
    * as a standard with hardware implementations ensures both: computing
      efficiency and hardware/3rd party library compatibility as opposed to Ruby
      custom `BigDecimal` type,
    * at present, only normalized numbers are used and considered sufficient, in
      order to avoid potential issues with the cross-platform compatibility of
      subnormal (denormal) numbers,
* in the future, the IEEE 754 decimal64 data type may be considered once it is
  supported by database engines.

### Database layer vs application layer data model constraints

* database constraints are the final guard against data integrity corruption,
    * they should safeguard against data referential integrity loss under _all_
      data (not schema) manipulation scenarios, including application level
      logic errors and direct data manipulation (e.g. through `dbconsole`),
* application constraints can be as restrictive as database constraints or more,
  but not less, as it doesn't serve any use case,
    * proper application level constraints should prevent unhandled database
      exception occurences, e.g `ActiveRecord::InvalidForeignKey` for operations
      performed through Models (i.e. not `#delete_all` etc.)
