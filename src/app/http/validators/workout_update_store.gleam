import app/app.{type App}
import gleam/int
import gleam/option.{type Option, None, Some}
import glimr/forms/validator.{type FormData, type Rule}
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/redirect

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#form-validation

/// Define the shape of the data returned after validation
///
pub type Data {
  Data(
    exercise_id: Option(Int),
    weight_type_id: Option(Int),
    weight: Option(Int),
    reps: Option(Int),
    notes: Option(String),
  )
}

/// Define your form's validation rules
///
fn rules(_ctx: Context(App)) -> List(Rule(Context(App))) {
  [
    validator.for("exercise_id", [validator.Numeric]),
    validator.for("weight_type_id", [validator.Numeric]),
    validator.for("weight", [validator.Numeric]),
    validator.for("reps", [validator.Numeric]),
    validator.for("notes", []),
  ]
}

/// Set the form data returned after validation. This is also
/// where you can transform validated input data before it
/// reaches your controller.
///
fn data(data: FormData) -> Data {
  Data(
    exercise_id: data.get("exercise_id") |> int.parse |> option.from_result,
    weight_type_id: data.get("weight_type_id")
      |> int.parse
      |> option.from_result,
    weight: data.get("weight") |> int.parse |> option.from_result,
    reps: data.get("reps") |> int.parse |> option.from_result,
    notes: case data.get("notes") {
      "" -> None
      val -> Some(val)
    },
  )
}

/// Run your validation rules. This is your entry point, you
/// dont't usually have to adjust anything in this function, but
/// you can if you want to add any custom logic before/after
/// validation.
///
pub fn validate(ctx: Context(App), next: fn(Data) -> Response) {
  use validated <- validator.run(ctx, rules, data, redirect.back(ctx))

  next(validated)
}
