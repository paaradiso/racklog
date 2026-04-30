import fx
import glaze/oat/toast
import gleam/list
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import racklog/workout.{type WorkoutDto}
import rsvp

pub type Model {
  Model(workouts: Option(List(WorkoutDto)))
}

pub type Msg {
  GotWorkouts(Result(List(WorkoutDto), rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let fetch_workouts_effect =
    rsvp.get(
      "/api/workouts",
      rsvp.expect_json(workout.list_decoder(), GotWorkouts),
    )
  #(Model(workouts: None), effect.batch([fetch_workouts_effect]))
}

pub fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GotWorkouts(Ok(workouts)) -> {
      #(Model(workouts: Some(workouts)), effect.none())
    }
    GotWorkouts(Error(rsvp.HttpError(response))) -> {
      #(
        model,
        fx.toast(
          title: "Error",
          description: response.body,
          variant: toast.Danger,
        ),
      )
    }
    GotWorkouts(Error(_)) -> {
      #(
        model,
        fx.toast(
          title: "Error",
          description: "Failed to fetch workouts.",
          variant: toast.Danger,
        ),
      )
    }
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  [
    html.div([attribute.class("flex flex-col gap-2")], case model.workouts {
      None -> [element.text("Loading...")]
      Some(workouts) -> {
        list.map(workouts, fn(workout) {
          html.span([], [element.text(workout.name |> option.unwrap("null"))])
        })
      }
    }),
  ]
}
