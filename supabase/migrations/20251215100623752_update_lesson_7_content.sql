/*
  # Update Lesson 7 Content
*/

DO $$
DECLARE
  l_id uuid;
BEGIN
  -- Find or create lesson
  SELECT id INTO l_id FROM lessons WHERE index = 7;
  
  IF l_id IS NULL THEN
    INSERT INTO lessons (index, title, is_published) 
    VALUES (7, 'Lesson 7', true) 
    RETURNING id INTO l_id;
  END IF;

  -- Delete existing lines
  DELETE FROM lines WHERE lesson_id = l_id;

  -- Insert new lines
  INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type)
  SELECT l_id, v.order_num, v.code, v.text_he, v.text_it, v.type
  FROM (VALUES
    (1, '7-00100', 'השיעור הזה יוקדש כולו לשאלת שאלות והתעסקות במילות שאלה...', '', 'INFO'),
    (2, '7-00200', 'מה (איזה)', 'CHE', 'LANG'),
    (3, '7-00300', 'מה (איזה)', 'COSA', 'LANG'),
    (4, '7-00400', 'מאיזה', 'DI CHE', 'LANG'),
    (5, '7-00500', 'לאיזה (לכיוון)', 'A CHE', 'LANG'),
    (6, '7-00600', 'עם איזה', 'CON CHE', 'LANG'),
    (7, '7-00700', 'בשביל איזה', 'PER CHE', 'LANG'),
    (8, '7-00800', 'מילת שאלה נוספת...', '', 'INFO'),
    (9, '7-00900', 'איזה (מבין כמה)', 'QUALE', 'LANG'),
    (10, '7-01000', 'ובריבוי...', '', 'INFO'),
    (11, '7-01100', 'אילו (מבין כמה)', 'QUALI', 'LANG'),
    (12, '7-01200', 'עם איזה', 'CON QUALE', 'LANG'),
    (13, '7-01300', 'לאיזה', 'A QUALE', 'LANG'),
    (14, '7-01400', 'בשביל איזה', 'PER QUALE', 'LANG'),
    (15, '7-01500', 'מאיזה', 'DI QUALE', 'LANG'),
    (16, '7-01600', 'כמה', 'QUANTO', 'LANG'),
    (17, '7-01700', 'כמה (נקבה)', 'QUANTA', 'LANG'),
    (18, '7-01800', 'כמה (רבים)', 'QUANTI', 'LANG'),
    (19, '7-01900', 'כמה (רבות)', 'QUANTE', 'LANG'),
    (20, '7-02000', 'מילת שאלה חשובה...', '', 'INFO'),
    (21, '7-02100', 'מתי', 'QUANDO', 'LANG'),
    (22, '7-02200', 'ממתי', 'DA QUANDO', 'LANG'),
    (23, '7-02300', 'עד מתי', 'FINO A QUANDO', 'LANG'),
    (24, '7-02400', 'עוד מילת שאלה...', '', 'INFO'),
    (25, '7-02500', 'איפה', 'DOVE', 'LANG'),
    (26, '7-02600', 'מאיפה', 'DI DOVE', 'LANG'),
    (27, '7-02700', 'מאיפה (כיוון)', 'DA DOVE', 'LANG'),
    (28, '7-02800', 'שימו לב להבדל : DI DOVE זה מנין אתה (מוצא),DA DOVE זה מאיפה אתה בא (פיזית)', '', 'INFO'),
    (29, '7-02900', 'מילת שאלה נוספת...', '', 'INFO'),
    (30, '7-03000', 'מי', 'CHI', 'LANG'),
    (31, '7-03100', 'עם מי', 'CON CHI', 'LANG'),
    (32, '7-03200', 'בשביל מי', 'PER CHI', 'LANG'),
    (33, '7-03300', 'של מי', 'DI CHI', 'LANG'),
    (34, '7-03400', 'למי', 'A CHI', 'LANG'),
    (35, '7-03500', 'מילת שאלה אחרונה להיום...', '', 'INFO'),
    (36, '7-03600', 'איך', 'COME', 'LANG'),
    (37, '7-03700', 'ועכשיו,נתרגל משפטים עם מילות השאלה...', '', 'INFO'),
    (38, '7-03800', 'מה אתה רוצה ?', 'CHE COSA VUOI ?', 'LANG'),
    (39, '7-03900', 'איזה ספר אתה רוצה ?', 'QUALE LIBRO VUOI ?', 'LANG'),
    (40, '7-04000', 'כמה זה עולה ?', 'QUANTO COSTA ?', 'LANG'),
    (41, '7-04100', 'מתי אתה מגיע ?', 'QUANDO ARRIVI ?', 'LANG'),
    (42, '7-04200', 'איפה אתה גר ?', 'DOVE ABITI ?', 'LANG'),
    (43, '7-04300', 'מי זה ?', 'CHI È ?', 'LANG'),
    (44, '7-04400', 'איך קוראים לך ?', 'COME TI CHIAMI ?', 'LANG'),
    (45, '7-04500', 'נחזור לפועל ללכת (ANDARE) ולשימוש שלו עם מילות שאלה...', '', 'INFO'),
    (46, '7-04600', 'לאן אתה הולך ?', 'DOVE VAI ?', 'LANG'),
    (47, '7-04700', 'עם מי אתה הולך ?', 'CON CHI VAI ?', 'LANG'),
    (48, '7-04800', 'מתי אתה הולך ?', 'QUANDO VAI ?', 'LANG'),
    (49, '7-04900', 'איך אתה הולך ? (ברגל,באוטו...)', 'COME VAI ?', 'LANG'),
    (50, '7-05000', 'וכעת,שאלות עם הפועל לעשות (FARE)...', '', 'INFO'),
    (51, '7-05100', 'מה אתה עושה ?', 'CHE COSA FAI ?', 'LANG'),
    (52, '7-05200', 'איך אתה עושה את זה ?', 'COME LO FAI ?', 'LANG'),
    (53, '7-05300', 'מתי אתה עושה את זה ?', 'QUANDO LO FAI ?', 'LANG'),
    (54, '7-05400', 'עם מי אתה עושה את זה ?', 'CON CHI LO FAI ?', 'LANG'),
    (55, '7-05500', 'למה אתה עושה את זה ?', 'PERCHÉ LO FAI ?', 'LANG')
  ) AS v(order_num, code, text_he, text_it, type);

END $$;
