import components
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/uri.{type Uri}
import lucide_lustre
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import racklog/user.{type UserDto, AdminRole, UserRole}
import route/admin
import route/equipment
import route/exercises
import route/index
import route/login
import route/settings
import rsvp

pub fn main() -> Nil {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}

type User {
  LoggedIn(UserDto)
  LoggedOut
  Loading
}

type Path {
  IndexPath
  EquipmentPath
  ExercisesPath
  LoginPath
  AdminPath
  SettingsPath
}

type Route {
  Index(index.Model)
  Equipment(equipment.Model)
  Exercises(exercises.Model)
  Login(login.Model)
  Admin(admin.Model)
  Settings(settings.Model)
  NotFound(uri: Uri)
}

type Model {
  Model(route: Route, user: User)
}

type Msg {
  UserNavigatedTo(Uri)
  NavigateTo(String)
  GotCurrentUser(Result(UserDto, rsvp.Error))
  SubmittedLogout
  GotLogoutResponse(Result(response.Response(String), rsvp.Error))

  IndexMsg(index.Msg)
  EquipmentMsg(equipment.Msg)
  ExercisesMsg(exercises.Msg)
  LoginMsg(login.Msg)
  AdminMsg(admin.Msg)
  SettingsMsg(settings.Msg)
}

fn require_authentication(
  user: User,
  uri: Uri,
  next: fn(UserDto) -> #(Route, Effect(Msg)),
) -> #(Route, Effect(Msg)) {
  case user {
    LoggedIn(u) -> next(u)
    Loading -> #(NotFound(uri:), effect.none())
    LoggedOut -> #(
      NotFound(uri:),
      modem.replace(path_to_url(LoginPath), None, None),
    )
  }
}

fn require_admin(
  user: User,
  uri: Uri,
  next: fn(UserDto) -> #(Route, Effect(Msg)),
) -> #(Route, Effect(Msg)) {
  use u <- require_authentication(user, uri)
  case u.role {
    user.AdminRole -> next(u)
    user.UserRole -> #(
      NotFound(uri:),
      modem.replace(path_to_url(IndexPath), None, None),
    )
  }
}

fn uri_to_route(uri: Uri, user: User) -> #(Route, Effect(Msg)) {
  case uri.path_segments(uri.path) {
    [] | [""] -> {
      use _ <- require_authentication(user, uri)
      let #(model, fx) = index.init()
      #(Index(model), effect.map(fx, IndexMsg))
    }
    ["equipment"] -> {
      let #(model, fx) = equipment.init()
      #(Equipment(model), effect.map(fx, EquipmentMsg))
    }
    ["exercises"] -> {
      let #(model, fx) = exercises.init()
      #(Exercises(model), effect.map(fx, ExercisesMsg))
    }
    ["login"] -> {
      let #(model, fx) = login.init()
      #(Login(model), effect.map(fx, LoginMsg))
    }
    ["admin"] | ["admin", ""] -> {
      use _ <- require_admin(user, uri)
      #(Admin(admin.init().0), modem.replace("/admin/general", None, None))
    }
    ["admin", tab] -> {
      use _ <- require_admin(user, uri)
      case admin.tab_name_to_tab(tab) {
        Some(tab) -> {
          let #(model, fx) = admin.init_with_tab(tab)
          #(Admin(model), effect.map(fx, AdminMsg))
        }
        None -> #(
          Admin(admin.init().0),
          modem.replace("/admin/general", None, None),
        )
      }
    }
    ["settings"] -> {
      use user <- require_authentication(user, uri)
      let #(model, fx) = settings.init(user)
      #(Settings(model), effect.map(fx, SettingsMsg))
    }
    _ -> #(NotFound(uri:), effect.none())
  }
}

fn path_to_url(path: Path) -> String {
  case path {
    IndexPath -> "/"
    EquipmentPath -> "/equipment"
    ExercisesPath -> "/exercises"
    LoginPath -> "/login"
    AdminPath -> "/admin"
    SettingsPath -> "/settings"
  }
}

fn href(path: Path) -> Attribute(msg) {
  path_to_url(path)
  |> attribute.href
}

fn init(_) -> #(Model, Effect(Msg)) {
  let uri = modem.initial_uri() |> result.unwrap(uri.empty)
  let nav_effect = modem.init(UserNavigatedTo)
  let #(route, route_effect) = uri_to_route(uri, Loading)
  let user_effect = fetch_current_user()
  #(
    Model(route:, user: Loading),
    effect.batch([nav_effect, route_effect, user_effect]),
  )
}

fn fetch_current_user() -> Effect(Msg) {
  rsvp.get("/api/me", rsvp.expect_json(user.decoder(), GotCurrentUser))
}

fn update(model model: Model, msg msg: Msg) -> #(Model, Effect(Msg)) {
  case msg, model.route {
    GotCurrentUser(Ok(user)), _ -> {
      let #(route, fx) = case model.route {
        NotFound(uri:) -> uri_to_route(uri, LoggedIn(user))
        Login(_) -> #(
          model.route,
          modem.push(path_to_url(IndexPath), None, None),
        )
        _ -> #(model.route, effect.none())
      }
      #(Model(route:, user: LoggedIn(user)), fx)
    }
    GotCurrentUser(Error(_)), _ ->
      case model.route {
        Login(_) -> #(Model(..model, user: LoggedOut), effect.none())
        _ -> #(
          Model(..model, user: LoggedOut),
          modem.replace("/login", None, None),
        )
      }
    UserNavigatedTo(uri), _ -> {
      let #(route, fx) = uri_to_route(uri, model.user)
      let redirect_effect = case route, model.user {
        Login(_), LoggedIn(_) -> modem.replace("/", None, None)
        _, _ -> effect.none()
      }
      #(
        Model(..model, route:),
        effect.batch([fx, fetch_current_user(), redirect_effect]),
      )
    }
    NavigateTo(path), _ -> {
      #(model, modem.push(path, None, None))
    }
    SubmittedLogout, _ -> {
      let logout_effect =
        rsvp.post(
          "/api/logout",
          json.null(),
          rsvp.expect_any_response(GotLogoutResponse),
        )
      #(model, logout_effect)
    }
    GotLogoutResponse(Ok(response)), _ -> {
      case response.status {
        200 | 401 -> {
          #(Model(..model, user: LoggedOut), modem.push("/login", None, None))
        }
        _ -> {
          #(model, effect.none())
        }
      }
    }
    GotLogoutResponse(Error(_)), _ -> {
      #(model, effect.none())
    }
    IndexMsg(route_msg), Index(route_model) -> {
      let #(m, fx) = index.update(route_model, route_msg)
      #(Model(..model, route: Index(m)), effect.map(fx, IndexMsg))
    }
    EquipmentMsg(route_msg), Equipment(route_model) -> {
      let #(m, fx) = equipment.update(route_model, route_msg)
      #(Model(..model, route: Equipment(m)), effect.map(fx, EquipmentMsg))
    }
    ExercisesMsg(route_msg), Exercises(route_model) -> {
      let #(m, fx) = exercises.update(route_model, route_msg)
      #(Model(..model, route: Exercises(m)), effect.map(fx, ExercisesMsg))
    }
    LoginMsg(route_msg), Login(route_model) -> {
      let #(m, fx) = login.update(route_model, route_msg)
      #(Model(..model, route: Login(m)), effect.map(fx, LoginMsg))
    }
    AdminMsg(route_msg), Admin(route_model) -> {
      let #(m, fx) = admin.update(route_model, route_msg)
      #(Model(..model, route: Admin(m)), effect.map(fx, AdminMsg))
    }
    SettingsMsg(route_msg), Settings(route_model) -> {
      let #(m, fx) = settings.update(route_model, route_msg)
      #(Model(..model, route: Settings(m)), effect.map(fx, SettingsMsg))
    }
    _, _ -> #(model, effect.none())
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.user {
    Loading -> view_loading()
    LoggedOut -> view_logged_out(model)
    LoggedIn(user) -> view_app(user, model)
  }
}

fn view_loading() -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "flex justify-center items-center w-full h-screen text-muted-foreground",
      ),
    ],
    [html.text("Loading…")],
  )
}

fn view_logged_out(model: Model) -> Element(Msg) {
  html.div([attribute.class("flex overflow-hidden flex-col w-full h-screen")], [
    html.div(
      [attribute.class("flex overflow-hidden z-40 flex-1 w-full min-h-0")],
      case model.route {
        Login(m) -> view_route(m, login.view, LoginMsg)
        _ -> []
      },
    ),
  ])
}

fn view_app(user: UserDto, model: Model) -> Element(Msg) {
  html.div([attribute.class("flex overflow-hidden flex-col w-full h-screen")], [
    view_header(user),
    html.div(
      [attribute.class("flex overflow-hidden flex-1 w-full min-h-0")],
      case model.route {
        Index(m) -> view_route(m, index.view, IndexMsg)
        Equipment(m) -> view_route(m, equipment.view, EquipmentMsg)
        Exercises(m) -> view_route(m, exercises.view, ExercisesMsg)
        Admin(m) -> view_route(m, admin.view, AdminMsg)
        Settings(m) -> view_route(m, settings.view, SettingsMsg)
        Login(_) -> []
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

fn view_header(user: UserDto) -> Element(Msg) {
  html.header(
    [
      attribute.class(
        "flex relative z-50 justify-center items-center w-full h-16 border-b shadow-md shrink-0 bg-card border-border",
      ),
    ],
    [
      html.div(
        [attribute.class("container flex justify-between items-center")],
        [
          html.nav(
            [
              attribute.attribute("aria-label", "Primary"),
              attribute.class("flex gap-4 items-center"),
            ],
            [
              html.a(
                [
                  href(IndexPath),
                  attribute.class("mr-4 text-2xl font-bold text-foreground"),
                ],
                [
                  element.text("racklog"),
                ],
              ),

              components.link(attributes: [href(EquipmentPath)], children: [
                element.text("Equipment"),
              ]),
              components.link(attributes: [href(ExercisesPath)], children: [
                element.text("Exercises"),
              ]),
            ],
          ),

          html.nav(
            [
              attribute.attribute("aria-label", "Account"),
              attribute.class("flex gap-4 items-center"),
            ],
            [
              case user.role {
                AdminRole ->
                  html.a(
                    [
                      href(AdminPath),

                      attribute.title("Admin"),
                    ],
                    [
                      lucide_lustre.settings([attribute.class("size-5")]),
                    ],
                  )
                UserRole -> element.none()
              },
              components.dropdown(
                trigger: [
                  lucide_lustre.circle_user_round([attribute.class("size-5")]),
                  element.text(user.username),
                ],
                items: [
                  components.dropdown_item(
                    attributes: [
                      event.on_click(NavigateTo(path_to_url(SettingsPath))),
                    ],
                    children: [
                      lucide_lustre.settings([attribute.class("size-4")]),
                      element.text("Settings"),
                    ],
                  ),
                  components.dropdown_item(
                    attributes: [event.on_click(SubmittedLogout)],
                    children: [
                      lucide_lustre.log_out([attribute.class("size-4")]),
                      element.text("Log out"),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  )
}
