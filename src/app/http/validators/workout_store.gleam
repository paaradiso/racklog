import app/app.{type App}
import gleam/int
import glimr/forms/validator.{type FormData, type Rule}
import glimr/http/context.{type Context}
import glimr/http/http.{type Response}
import glimr/response/redirect

// docs: https://github.com/glimr-org/glimr?tab=readme-ov-file#form-validation

/// Define the shape of the data returned after validation
///
pub type Data {
  Data(
    user_id: Int,
    exercise_id: Int,
    weight_type_id: Int,
    weight: Int,
    reps: Int,
    notes: String,
  )
}

/// Define your form's validation rules
///
fn rules(_ctx: Context(App)) -> List(Rule(Context(App))) {
  [
    validator.for("user_id", [validator.Required, validator.Numeric]),
    validator.for("exercise_id", [validator.Required, validator.Numeric]),
    validator.for("weight_type_id", [validator.Required, validator.Numeric]),
    validator.for("weight", [validator.Required, validator.Numeric]),
    validator.for("reps", [validator.Required, validator.Numeric]),
    validator.for("notes", []),
  ]
}

/// Set the form data returned after validation. This is also
/// where you can transform validated input data before it
/// reaches your controller.
///
fn data(data: FormData) -> Data {
  let assert Ok(user_id) = data.get("user_id") |> int.parse
  let assert Ok(exercise_id) = data.get("exercise_id") |> int.parse
  let assert Ok(weight_type_id) = data.get("weight_type_id") |> int.parse
  let assert Ok(weight) = data.get("weight") |> int.parse
  let assert Ok(reps) = data.get("reps") |> int.parse

  Data(
    user_id: user_id,
    exercise_id: exercise_id,
    weight_type_id: weight_type_id,
    weight: weight,
    reps: reps,
    notes: data.get("notes"),
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
