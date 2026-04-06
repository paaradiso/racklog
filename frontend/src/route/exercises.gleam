import gleam/dynamic/decode
import gleam/list
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import rsvp

pub type Model {
  Model(names: List(String))
}

pub const base_model = Model(names: [])

pub type Msg {
  FetchedExercises(Result(List(String), rsvp.Error))
}

pub fn init() -> #(Model, Effect(Msg)) {
  let effect =
    rsvp.get(
      "/api/exercises",
      rsvp.expect_json(names_decoder(), FetchedExercises),
    )
  #(Model(names: []), effect)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    FetchedExercises(Ok(names)) -> #(Model(names: names), effect.none())
    FetchedExercises(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> List(Element(Msg)) {
  case model.names {
    [] -> [html.text("Loading…")]
    names -> [
      html.ul([], list.map(names, fn(name) { html.li([], [html.text(name)]) })),
    ]
  }
}

fn name_decoder() -> decode.Decoder(String) {
  use name <- decode.field("name", decode.string)
  decode.success(name)
}

fn names_decoder() -> decode.Decoder(List(String)) {
  decode.list(name_decoder())
}
