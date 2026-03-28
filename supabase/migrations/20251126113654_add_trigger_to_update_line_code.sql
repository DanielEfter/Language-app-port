/*
  # Add trigger to automatically update line code

  1. Changes
    - Create a trigger function that updates the `code` field whenever `order_num` changes
    - Create a trigger that calls this function on INSERT or UPDATE
  
  2. Purpose
    - Ensures that the `code` field is always in sync with the `order_num`
    - Prevents duplicate codes from being created when order numbers change
  
  3. Important Notes
    - This trigger runs before INSERT or UPDATE operations
    - The code format is: {lesson_index}-{order_num_padded_5_digits}
*/

-- Create function to update line code
CREATE OR REPLACE FUNCTION update_line_code()
RETURNS TRIGGER AS $$
BEGIN
  -- Get the lesson index and update the code
  NEW.code := (
    SELECT index || '-' || LPAD(NEW.order_num::text, 5, '0')
    FROM lessons
    WHERE id = NEW.lesson_id
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update code
DROP TRIGGER IF EXISTS trigger_update_line_code ON lines;
CREATE TRIGGER trigger_update_line_code
  BEFORE INSERT OR UPDATE OF order_num, lesson_id
  ON lines
  FOR EACH ROW
  EXECUTE FUNCTION update_line_code();