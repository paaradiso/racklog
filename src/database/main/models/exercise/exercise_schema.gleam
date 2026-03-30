import glimr/db/schema

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#migrations

pub const table_name = "exercises"

pub fn definition() {
  schema.table(table_name, [
    schema.id(),
    schema.string("name"),
    schema.unix_timestamps(),
  ])
  |> schema.indexes([schema.unique(["name"])])
}
