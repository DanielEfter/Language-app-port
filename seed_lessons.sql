-- Seed Lessons Data (Required for FKs)
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('9b2b6a79-e1c4-4bdf-9a35-32996a2c6136', 1, 'Lesson 1', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('6bd8ef08-6771-466b-8abf-eba439a1665b', 2, 'Lesson 2', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('44faec16-0a8a-4452-ac23-dca79cba04f7', 3, 'Lesson 3', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('8ae7189d-70fb-4db3-bf53-9848e3e73ad2', 4, 'Lesson 4', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('56e9a5fe-3c79-4c46-8894-92988329ed76', 5, 'Lesson 5', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('97409ed0-8b55-424d-b361-0c20a7fbdfaf', 6, 'Lesson 6', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('ffb3252b-a516-4828-8385-58cb2c23eb2c', 7, 'Lesson 7', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO public.lessons (id, index, title, is_published) VALUES ('97a3284f-1ed2-4263-8a15-22cb4ea4b696', 8, 'Lesson 8', true) ON CONFLICT (id) DO NOTHING;
