import gleam/http.{Get}
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
