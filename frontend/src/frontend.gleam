import components
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import route/exercises
import route/login
import route/weight_types
import rsvp

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

pub type User {
  User(id: Int, email: String)
}

type Route {
  Index
  WeightTypes(weight_types.Model)
  Exercises(exercises.Model)
  Login(login.Model)
  NotFound(uri: Uri)
}

type Model {
  Model(route: Route, user: Option(User))
}

type Msg {
  UserNavigatedTo(Uri)
  GotCurrentUser(Result(User, rsvp.Error))
  WeightTypesMsg(weight_types.Msg)
  ExercisesMsg(exercises.Msg)
  LoginMsg(login.Msg)
}

fn uri_to_route(uri: Uri) -> #(Route, Effect(Msg)) {
  case uri.path_segments(uri.path) {
    [] | [""] -> #(Index, effect.none())
    ["weight_types"] -> {
      let #(model, fx) = weight_types.init()
      #(WeightTypes(model), effect.map(fx, WeightTypesMsg))
    }
    ["exercises"] -> {
      let #(model, fx) = exercises.init()
      #(Exercises(model), effect.map(fx, ExercisesMsg))
    }
    ["login"] -> {
      let #(model, fx) = login.init()
      #(Login(model), effect.map(fx, LoginMsg))
    }
    _ -> #(NotFound(uri:), effect.none())
  }
}

fn href(route: Route) -> Attribute(msg) {
  let url = case route {
    Index -> "/"
    WeightTypes(_) -> "/weight_types"
    Exercises(_) -> "/exercises"
    Login(_) -> "/login"
    NotFound(_) -> "/404"
  }
  attribute.href(url)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let uri = modem.initial_uri() |> result.unwrap(uri.empty)
  let nav_effect = modem.init(UserNavigatedTo)
  let #(route, route_effect) = uri_to_route(uri)
  let user_effect = fetch_current_user()
  #(
    Model(route:, user: None),
    effect.batch([nav_effect, route_effect, user_effect]),
  )
}

fn fetch_current_user() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(decode_user(), GotCurrentUser))
}

fn decode_user() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use email <- decode.field("email", decode.string)
  decode.success(User(id:, email:))
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GotCurrentUser(Ok(user)) -> #(
      Model(..model, user: Some(user)),
      effect.none(),
    )
    GotCurrentUser(Error(_)) -> #(Model(..model, user: None), effect.none())
    UserNavigatedTo(uri) -> {
      let #(route, fx) = uri_to_route(uri)
      #(Model(..model, route:), effect.batch([fx, fetch_current_user()]))
    }
    WeightTypesMsg(route_msg) ->
      update_route(
        model,
        route_msg,
        weight_types.update,
        fn(route) {
          case route {
            WeightTypes(m) -> Some(m)
            _ -> None
          }
        },
        WeightTypes,
        WeightTypesMsg,
      )

    ExercisesMsg(route_msg) ->
      update_route(
        model,
        route_msg,
        exercises.update,
        fn(route) {
          case route {
            Exercises(m) -> Some(m)
            _ -> None
          }
        },
        Exercises,
        ExercisesMsg,
      )

    LoginMsg(route_msg) ->
      update_route(
        model,
        route_msg,
        login.update,
        fn(route) {
          case route {
            Login(m) -> Some(m)
            _ -> None
          }
        },
        Login,
        LoginMsg,
      )
  }
}

fn update_route(
  model: Model,
  route_msg: msg,
  route_update_fn: fn(model, msg) -> #(model, Effect(msg)),
  extract: fn(Route) -> Option(model),
  wrap_route: fn(model) -> Route,
  route_msg_fn: fn(msg) -> Msg,
) -> #(Model, Effect(Msg)) {
  case extract(model.route) {
    None -> #(model, effect.none())
    Some(route_model) -> {
      let #(m, fx) = route_update_fn(route_model, route_msg)
      #(Model(..model, route: wrap_route(m)), effect.map(fx, route_msg_fn))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div([], [
    render_header(model),
    html.main(
      [attribute.class("justify-center items-center w-full flex-1")],
      case model.route {
        Index -> [html.text("index")]
        WeightTypes(m) -> view_route(m, weight_types.view, WeightTypesMsg)
        Exercises(m) -> view_route(m, exercises.view, ExercisesMsg)
        Login(m) -> view_route(m, login.view, LoginMsg)
        NotFound(_) -> [html.text("not found")]
      },
    ),
  ])
}

fn view_route(
  model: model,
  route_view_fn: fn(model) -> List(Element(msg)),
  route_msg_fn: fn(msg) -> Msg,
) -> List(Element(Msg)) {
  route_view_fn(model)
  |> list.map(element.map(_, route_msg_fn))
}

fn render_header(model: Model) -> Element(Msg) {
  html.header(
    [
      attribute.class(
        "bg-card border-border z-10 flex h-16 w-full items-center justify-center border-b shadow-md backdrop-blur-sm mb-4",
      ),
    ],
    [
      html.div(
        [attribute.class("container flex items-center justify-between")],
        [
          html.nav(
            [
              attribute.attribute("aria-label", "Primary"),
              attribute.class("flex items-center gap-4"),
            ],
            [
              html.a(
                [
                  attribute.href("/"),
                  attribute.class("text-foreground text-2xl font-bold mr-4"),
                ],
                [
                  element.text("racklog"),
                ],
              ),

              components.link(href: "/input", attributes: [], children: [
                element.text("Input"),
              ]),
              components.link(href: "/workouts", attributes: [], children: [
                element.text("Workouts"),
              ]),
              components.link(href: "/exercises", attributes: [], children: [
                element.text("Exercises"),
              ]),
            ],
          ),

          html.nav(
            [
              attribute.attribute("aria-label", "Account"),
              attribute.class("items-center gap-4 flex"),
            ],
            [
              case model.user {
                option.Some(user) ->
                  html.span([], [
                    element.text("User #" <> int.to_string(user.id)),
                  ])
                option.None ->
                  element.fragment([
                    components.link(href: "/login", attributes: [], children: [
                      element.text("Log In"),
                    ]),
                  ])
              },
            ],
          ),
        ],
      ),
    ],
  )
}
