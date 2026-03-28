/*
  # Update Lesson 8 Content
*/

DO $$
DECLARE
  l_id uuid;
BEGIN
  -- Find or create lesson
  SELECT id INTO l_id FROM lessons WHERE index = 8;
  
  IF l_id IS NULL THEN
    INSERT INTO lessons (index, title, is_published) 
    VALUES (8, 'Lesson 8', true) 
    RETURNING id INTO l_id;
  END IF;

  -- Delete existing lines
  DELETE FROM lines WHERE lesson_id = l_id;

  -- Insert new lines
  INSERT INTO lines (lesson_id, order_num, code, text_he, text_it, type)
  SELECT l_id, v.order_num, v.code, v.text_he, v.text_it, v.type
  FROM (VALUES
    (1, '8-00100', 'בשיעור הזה נתעסק בפעלים,בעיקר בפעלי תנועה ובפעלים רפלקסיביים...', '', 'INFO'),
    (2, '8-00200', 'ללכת (מקום למקום)', 'ANDARE', 'LANG'),
    (3, '8-00201', 'כבר למדנו את הפועל הזה,נחזור על ההטיות :', '', 'INFO'),
    (4, '8-00300', 'הטיות הפועל ANDARE', 'VADO, VAI, VA, ANDIAMO, ANDATE, VANNO', 'LANG'),
    (5, '8-00400', 'פועל דומה במשמעות אבל שונה בשימוש...', '', 'INFO'),
    (6, '8-00401', 'ללכת (באופן כללי,לטייל)', 'CAMMINARE', 'LANG'),
    (7, '8-00402', 'הטיות הפועל CAMMINARE (פועל רגיל - ARE) :', '', 'INFO'),
    (8, '8-00500', 'הטיות הפועל CAMMINARE', 'CAMMINO, CAMMINI, CAMMINA, CAMMINIAMO, CAMMINATE, CAMMINANO', 'LANG'),
    (9, '8-00600', 'אני הולך ברגל', 'VADO A PIEDI', 'LANG'),
    (10, '8-00601', 'שימו לב : A PIEDI ולא IN PIEDI או CON PIEDI', '', 'INFO'),
    (11, '8-00700', 'אני הולך לטייל', 'VADO A CAMMINARE', 'LANG'),
    (12, '8-00701', 'פועל נוסף...', '', 'INFO'),
    (13, '8-00800', 'לרוץ', 'CORRERE', 'LANG'),
    (14, '8-00801', 'הטיות הפועל CORRERE (פועל רגיל - ERE) :', '', 'INFO'),
    (15, '8-00900', 'הטיות הפועל CORRERE', 'CORRO, CORRI, CORRE, CORRIAMO, CORRETE, CORRONO', 'LANG'),
    (16, '8-01000', 'למה אתה רץ ?', 'PERCHÉ CORRI ?', 'LANG'),
    (17, '8-01001', 'תשובה...', '', 'INFO'),
    (18, '8-01100', 'אני רץ כי אני ממהר', 'CORRO PERCHÉ HO FRETTA', 'LANG'),
    (19, '8-01101', 'ממהר = AVERE FRETTA (יש לי חיפזון)', '', 'INFO'),
    (20, '8-01200', 'פועל נוסף...', '', 'INFO'),
    (21, '8-01201', 'לנהוג', 'GUIDARE', 'LANG'),
    (22, '8-01202', 'הטיות הפועל GUIDARE (פועל רגיל - ARE) :', '', 'INFO'),
    (23, '8-01300', 'הטיות הפועל GUIDARE', 'GUIDO, GUIDI, GUIDA, GUIDIAMO, GUIDATE, GUIDANO', 'LANG'),
    (24, '8-01400', 'אתה נוהג טוב', 'GUIDI BENE', 'LANG'),
    (25, '8-01401', 'עכשיו נתעסק בפעלים רפלקסיביים (מתייחסים לעצמי)...', '', 'INFO'),
    (26, '8-01500', 'לקום (את עצמי)', 'ALZARSI', 'LANG'),
    (27, '8-01501', 'הטיות הפועל ALZARSI :', '', 'INFO'),
    (28, '8-01600', 'הטיות הפועל ALZARSI', 'MI ALZO, TI ALZI, SI ALZA, CI ALZIAMO, VI ALZATE, SI ALZANO', 'LANG'),
    (29, '8-01700', 'מתי אתה קם בבוקר ?', 'A CHE ORA TI ALZI LA MATTINA ?', 'LANG'),
    (30, '8-01701', 'תשובה...', '', 'INFO'),
    (31, '8-01800', 'אני קם ב-7', 'MI ALZO ALLE SETTE', 'LANG'),
    (32, '8-01900', 'פועל נוסף...', '', 'INFO'),
    (33, '8-01901', 'להתרחץ (את עצמי)', 'LAVARSI', 'LANG'),
    (34, '8-01902', 'הטיות הפועל LAVARSI :', '', 'INFO'),
    (35, '8-02000', 'הטיות הפועל LAVARSI', 'MI LAVO, TI LAVI, SI LAVA, CI LAVIAMO, VI LAVATE, SI LAVANO', 'LANG'),
    (36, '8-02100', 'אני מתרחץ כל יום', 'MI LAVO TUTTI I GIORNI', 'LANG'),
    (37, '8-02200', 'פועל נוסף...', '', 'INFO'),
    (38, '8-02201', 'להתלבש (את עצמי)', 'VESTIRSI', 'LANG'),
    (39, '8-02202', 'הטיות הפועל VESTIRSI :', '', 'INFO'),
    (40, '8-02300', 'הטיות הפועל VESTIRSI', 'MI VESTO, TI VESTI, SI VESTE, CI VESTIAMO, VI VESTITE, SI VESTONO', 'LANG'),
    (41, '8-02400', 'איך אתה מתלבש ?', 'COME TI VESTI ?', 'LANG'),
    (42, '8-02401', 'תשובה...', '', 'INFO'),
    (43, '8-02500', 'אני מתלבש יפה', 'MI VESTO BENE', 'LANG'),
    (44, '8-02600', 'פועל נוסף...', '', 'INFO'),
    (45, '8-02601', 'להרגיש (את עצמי)', 'SENTIRSI', 'LANG'),
    (46, '8-02602', 'הטיות הפועל SENTIRSI :', '', 'INFO'),
    (47, '8-02700', 'הטיות הפועל SENTIRSI', 'MI SENTO, TI SENTI, SI SENTE, CI SENTIAMO, VI SENTITE, SI SENTONO', 'LANG'),
    (48, '8-02800', 'איך אתה מרגיש ?', 'COME TI SENTI ?', 'LANG'),
    (49, '8-02801', 'תשובה...', '', 'INFO'),
    (50, '8-02900', 'אני מרגיש טוב', 'MI SENTO BENE', 'LANG'),
    (51, '8-02901', 'או...', '', 'INFO'),
    (52, '8-03000', 'אני מרגיש רע', 'MI SENTO MALE', 'LANG'),
    (53, '8-03100', 'פועל נוסף...', '', 'INFO'),
    (54, '8-03101', 'להיקרא (בשם)', 'CHIAMARSI', 'LANG'),
    (55, '8-03102', 'הטיות הפועל CHIAMARSI :', '', 'INFO'),
    (56, '8-03200', 'הטיות הפועל CHIAMARSI', 'MI CHIAMO, TI CHIAMI, SI CHIAMA, CI CHIAMIAMO, VI CHIAMATE, SI CHIAMANO', 'LANG'),
    (57, '8-03300', 'איך קוראים לך ?', 'COME TI CHIAMI ?', 'LANG'),
    (58, '8-03301', 'תשובה...', '', 'INFO'),
    (59, '8-03400', 'קוראים לי... (השם שלך)', 'MI CHIAMO...', 'LANG'),
    (60, '8-03500', 'לסיום,כמה מילים על זמנים...', '', 'INFO'),
    (61, '8-03501', 'בוקר', 'MATTINA', 'LANG'),
    (62, '8-03502', 'צהריים', 'MEZZOGIORNO', 'LANG'),
    (63, '8-03503', 'אחר הצהריים', 'POMERIGGIO', 'LANG'),
    (64, '8-03504', 'ערב', 'SERA', 'LANG'),
    (65, '8-03505', 'לילה', 'NOTTE', 'LANG'),
    (66, '8-03600', 'בבוקר', 'LA MATTINA', 'LANG'),
    (67, '8-03700', 'בצהריים', 'A MEZZOGIORNO', 'LANG'),
    (68, '8-03800', 'אחר הצהריים', 'IL POMERIGGIO', 'LANG'),
    (69, '8-03900', 'בערב', 'LA SERA', 'LANG'),
    (70, '8-04000', 'בלילה', 'DI NOTTE', 'LANG')
  ) AS v(order_num, code, text_he, text_it, type);

END $$;
