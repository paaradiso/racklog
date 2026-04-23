import auth/sql
import gleam/time/timestamp
import racklog/user

pub fn shared_role_to_sql_role(role: user.AppUserRole) -> sql.AppUserRole {
  case role {
    user.AdminRole -> sql.Admin
    user.UserRole -> sql.User
  }
}

pub fn sql_role_to_shared_role(role: sql.AppUserRole) -> user.AppUserRole {
  case role {
    sql.Admin -> user.AdminRole
    sql.User -> user.UserRole
  }
}

pub fn sql_preferred_unit_to_shared_preferred_unit(
  preferred_unit: sql.PreferredUnit,
) -> user.PreferredUnit {
  case preferred_unit {
    sql.Kg -> user.Kg
    sql.Lb -> user.Lb
  }
}

pub fn row_to_dto(
  id: Int,
  username: String,
  email: String,
  role: sql.AppUserRole,
  preferred_unit: sql.PreferredUnit,
  created_at: timestamp.Timestamp,
  updated_at: timestamp.Timestamp,
) -> user.UserDto {
  user.UserDto(
    id:,
    username:,
    email:,
    role: sql_role_to_shared_role(role),
    preferred_unit: sql_preferred_unit_to_shared_preferred_unit(preferred_unit),
    created_at:,
    updated_at:,
  )
}
