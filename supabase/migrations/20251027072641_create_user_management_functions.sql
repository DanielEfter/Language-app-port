/*
  # Create User Management Functions

  1. New Functions
    - `create_user` - Creates a new user (bypasses RLS)
    - `update_user_role` - Updates user role
    - `delete_user_by_id` - Deletes a user
    - `toggle_user_status` - Toggles user active status

  2. Security
    - Functions run with SECURITY DEFINER (as postgres)
    - This bypasses RLS restrictions
*/

-- Function to create a new user
CREATE OR REPLACE FUNCTION create_user(
  p_username text,
  p_password_hash text,
  p_role text DEFAULT 'STUDENT'
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  INSERT INTO users (username, password_hash, role, is_active)
  VALUES (p_username, p_password_hash, p_role, true)
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to update user role
CREATE OR REPLACE FUNCTION update_user_role(
  p_user_id uuid,
  p_new_role text
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  UPDATE users
  SET role = p_new_role
  WHERE id = p_user_id
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to toggle user status
CREATE OR REPLACE FUNCTION toggle_user_status(
  p_user_id uuid
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user users;
BEGIN
  UPDATE users
  SET is_active = NOT is_active
  WHERE id = p_user_id
  RETURNING * INTO v_user;
  
  RETURN row_to_json(v_user);
END;
$$;

-- Function to delete user
CREATE OR REPLACE FUNCTION delete_user_by_id(
  p_user_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM users WHERE id = p_user_id;
  RETURN true;
END;
$$;

-- Function to update user password
CREATE OR REPLACE FUNCTION update_user_password(
  p_user_id uuid,
  p_password_hash text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE users
  SET password_hash = p_password_hash
  WHERE id = p_user_id;
  RETURN true;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_user TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_user_role TO anon, authenticated;
GRANT EXECUTE ON FUNCTION toggle_user_status TO anon, authenticated;
GRANT EXECUTE ON FUNCTION delete_user_by_id TO anon, authenticated;
GRANT EXECUTE ON FUNCTION update_user_password TO anon, authenticated;
