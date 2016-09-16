CREATE TABLE liability_waivers (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    full_name TEXT NOT NULL,
    check1 BOOLEAN NOT NULL,
    check2 BOOLEAN NOT NULL,
    check3 BOOLEAN NOT NULL,
    check4 BOOLEAN NOT NULL,
    addr TEXT,
    city TEXT,
    state TEXT,
    zip TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    emergency_contact_name TEXT NOT NULL,
    emergency_contact_phone TEXT NOT NULL,
    heard_from TEXT,
    signature TEXT NOT NULL
);
CREATE INDEX ON liability_waivers (lower(full_name));
CREATE INDEX ON liability_waivers (created_date);
CREATE INDEX ON liability_waivers (lower(email));


CREATE TABLE guest_signin (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    full_name TEXT NOT NULL,
    zip TEXT,
    member_hosting TEXT,
    email TEXT NOT NULL,
    join_mailing_list BOOLEAN NOT NULL,
    is_mailing_list_exported BOOLEAN NOT NULL DEFAULT FALSE
);
CREATE INDEX ON guest_signin (lower(full_name));
CREATE INDEX ON guest_signin (created_date);
CREATE INDEX ON guest_signin (lower(email));
CREATE INDEX ON guest_signin (is_mailing_list_exported);
