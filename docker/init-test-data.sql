/* Test users for local Docker development.
   Passwords match usernames (e.g. admin/admin, lehrer/lehrer, student/student).
   activation_code = NULL means the account is already activated. */

INSERT INTO users (
    first_name, last_name, email, salutation, role,
    last_login, first_login, password, activation_code, language
) VALUES
    -- Admin: external user, role admin (2)
    ('Admin', 'Admin', 'admin@test.local', 0, 2,
     NOW(), NOW(), CRYPT('admin', gen_salt('bf')), NULL, 'de-DE'),

    -- Lehrer: external user, role creator (1)
    ('Max', 'Mustermann', 'lehrer@test.local', 1, 1,
     NOW(), NOW(), CRYPT('lehrer', gen_salt('bf')), NULL, 'de-DE'),

    -- Student: external user, role user (0), French name with accents (tests ISO-8859 CSV export)
    ('René', 'Lefèvre', 'student@test.local', 1, 0,
     NOW(), NOW(), CRYPT('student', gen_salt('bf')), NULL, 'de-DE');
