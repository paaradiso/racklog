//// This module contains the code to run the sql queries defined in
//// `./src/equipment/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create` query
/// defined in `./src/equipment/sql/create.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateRow {
  CreateRow(id: Int, name: String, created_at: Timestamp, updated_at: Timestamp)
}

/// Runs the `create` query
/// defined in `./src/equipment/sql/create.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(CreateRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(CreateRow(id:, name:, created_at:, updated_at:))
  }

  "INSERT INTO equipment (name)
    VALUES ($1)
RETURNING
    *
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list` query
/// defined in `./src/equipment/sql/list.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListRow {
  ListRow(id: Int, name: String, created_at: Timestamp, updated_at: Timestamp)
}

/// Runs the `list` query
/// defined in `./src/equipment/sql/list.sql`.
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list(
  db: pog.Connection,
) -> Result(pog.Returned(ListRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use name <- decode.field(1, decode.string)
    use created_at <- decode.field(2, pog.timestamp_decoder())
    use updated_at <- decode.field(3, pog.timestamp_decoder())
    decode.success(ListRow(id:, name:, created_at:, updated_at:))
  }

  "SELECT
    *
FROM
    equipment
ORDER BY
    created_at DESC
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}
