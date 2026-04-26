import gleam/http.{Get, Post}
import gleam/http/response
import gleam/json
import gleam/list
import gleeunit/should
import racklog/user
import router
import util
import wisp/simulate

pub fn list_users_200_for_admin_test() {
  use db, ctx <- util.with_db()
  let #(_, session_id) = util.seed_admin(db)

  let response =
    simulate.browser_request(Get, "/api/users")
    |> util.simulate_session_cookie(session_id)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)

  let assert Ok(users) =
    simulate.read_body(response)
    |> json.parse(user.list_decoder())

  list.length(users)
  |> should.equal(1)
}

pub fn list_users_401_without_session_test() {
  use _, ctx <- util.with_db()

  let response =
    simulate.request(http.Get, "/api/users")
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}

pub fn list_users_403_for_non_admin_test() {
  use db, ctx <- util.with_db()
  let #(_, session_id) = util.seed_user(db, "a")

  let response =
    simulate.browser_request(http.Get, "/api/users")
    |> util.simulate_session_cookie(session_id)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(403)
}

pub fn list_users_returns_all_users_test() {
  use db, ctx <- util.with_db()
  let #(_, session_id) = util.seed_admin(db)
  let #(_, _) = util.seed_user(db, "a")
  let #(_, _) = util.seed_user(db, "b")

  let response =
    simulate.browser_request(http.Get, "/api/users")
    |> util.simulate_session_cookie(session_id)
    |> router.handle_request(ctx)

  let assert Ok(users) =
    simulate.read_body(response)
    |> json.parse(user.list_decoder())

  list.length(users)
  |> should.equal(3)
}

pub fn login_valid_user_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "username")
  let payload =
    json.object([
      #("username", json.string("username")),
      #("password", json.string("password")),
    ])

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)

  let cookies = response.get_cookies(response)
  let assert Ok(_) = list.key_find(cookies, "session_id")
  Nil
}

pub fn login_invalid_payload_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "username")
  let payload =
    json.object([
      #("username", json.string("username")),
      #("hi", json.string("hi")),
    ])

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(422)
}

pub fn login_incorrect_username_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "user")
  let payload =
    json.object([
      #("username", json.string("otheruser")),
      #("password", json.string("...")),
    ])

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}

pub fn login_incorrect_password_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "username")
  let payload =
    json.object([
      #("username", json.string("username")),
      #("password", json.string("incorrect_password")),
    ])

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(401)
}

pub fn login_string_body_test() {
  use _, ctx <- util.with_db()

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.string_body("")
    |> router.handle_request(ctx)

  response.status
  |> should.equal(415)
}

pub fn login_malformed_json_body_test() {
  use _, ctx <- util.with_db()

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.string_body("")
    |> simulate.header("content-type", "application/json")
    |> router.handle_request(ctx)

  response.status
  |> should.equal(400)
}

pub fn login_ignores_extra_field_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "username")
  let payload =
    json.object([
      #("username", json.string("username")),
      #("password", json.string("password")),
      #("random", json.string("...")),
    ])

  let response =
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)

  response.status
  |> should.equal(200)
}

pub fn login_twice_gives_different_sessions_test() {
  use db, ctx <- util.with_db()
  let _ = util.seed_user(db, "username")
  let payload =
    json.object([
      #("username", json.string("username")),
      #("password", json.string("password")),
    ])

  let login = fn() {
    simulate.browser_request(Post, "/api/login")
    |> simulate.json_body(payload)
    |> router.handle_request(ctx)
  }

  let assert Ok(first_session_id) =
    login()
    |> response.get_cookies
    |> list.key_find("session_id")
  let assert Ok(second_session_id) =
    login()
    |> response.get_cookies
    |> list.key_find("session_id")

  first_session_id
  |> should.not_equal(second_session_id)
}
