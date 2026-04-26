import gleam/http
import gleam/http/response
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should
import middleware
import router
import util
import web
import wisp
import wisp/simulate

pub fn load_session_clears_invalid_session_test() {
  use _, ctx <- util.with_db()
  let first_request =
    simulate.browser_request(http.Get, "/api/users")
    |> util.simulate_session_cookie("invalid_session_id")

  let first_response = router.handle_request(first_request, ctx)
  first_response.status |> should.equal(401)

  // cookie is cleared by setting its value to "" and max-age to 0, so it still exists immediately after the response
  response.get_cookies(first_response)
  |> list.key_find("session_id")
  |> should.be_ok

  let second_response =
    simulate.browser_request(http.Get, "/api/users")
    |> simulate.session(first_request, first_response)
    |> router.handle_request(ctx)
  second_response.status |> should.equal(401)

  // this time the max-age deletes the cookie
  response.get_cookies(second_response)
  |> list.key_find("session_id")
  |> should.be_error
}

pub fn require_session_with_session_test() {
  use _, ctx <- util.with_db()
  let ctx = web.Context(..ctx, session_id: Some("id"))

  let response =
    middleware.require_session(ctx, fn(id) {
      id |> should.equal("id")
      wisp.response(200)
    })
  response.status
  |> should.equal(200)
}

pub fn require_session_without_session_test() {
  use _, ctx <- util.with_db()
  let ctx = web.Context(..ctx, session_id: None)

  let response = middleware.require_session(ctx, fn(_) { wisp.response(200) })
  response.status
  |> should.equal(401)
}

pub fn require_authentication_with_user_test() {
  use _, ctx <- util.with_db()
  let user = util.create_admin_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response =
    middleware.require_authentication(ctx, fn(_) { wisp.response(200) })
  response.status |> should.equal(200)
}

pub fn require_authentication_without_user_test() {
  use _, ctx <- util.with_db()
  let response =
    middleware.require_authentication(ctx, fn(_) { wisp.response(200) })
  response.status |> should.equal(401)
}

pub fn require_admin_with_admin_test() {
  use _, ctx <- util.with_db()
  let user = util.create_admin_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response = middleware.require_admin(ctx, fn() { wisp.response(200) })
  response.status |> should.equal(200)
}

pub fn require_admin_with_non_admin_test() {
  use _, ctx <- util.with_db()
  let user = util.create_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response = middleware.require_admin(ctx, fn() { wisp.response(200) })
  response.status |> should.equal(403)
}

pub fn require_admin_without_user_test() {
  use _, ctx <- util.with_db()
  let response = middleware.require_admin(ctx, fn() { wisp.response(200) })
  response.status |> should.equal(401)
}

pub fn require_authorisation_same_user_test() {
  use _, ctx <- util.with_db()
  let user = util.create_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response =
    middleware.require_authorisation(ctx, user.id, fn(_) { wisp.response(200) })
  response.status |> should.equal(200)
}

pub fn require_authorisation_different_user_non_admin_test() {
  use _, ctx <- util.with_db()
  let user = util.create_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response =
    middleware.require_authorisation(ctx, user.id + 1, fn(_) {
      wisp.response(200)
    })
  response.status |> should.equal(403)
}

pub fn require_authorisation_different_user_admin_test() {
  use _, ctx <- util.with_db()
  let user = util.create_admin_user_dto()
  let ctx = web.Context(..ctx, user: Some(user))
  let response =
    middleware.require_authorisation(ctx, user.id + 1, fn(_) {
      wisp.response(200)
    })
  response.status |> should.equal(200)
}

pub fn require_authorisation_unauthenticated_test() {
  use _, ctx <- util.with_db()
  let response =
    middleware.require_authorisation(ctx, 1, fn(_) { wisp.response(200) })
  response.status |> should.equal(401)
}
