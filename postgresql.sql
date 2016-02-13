CREATE TABLE liability_waivers (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    full_name TEXT NOT NULL,
    check1 BOOLEAN NOT NULL,
    check2 BOOLEAN NOT NULL,
    check3 BOOLEAN NOT NULL,
    check4 BOOLEAN NOT NULL,
    addr TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT NOT NULL,
    zip TEXT NOT NULL,
    email TEXT NOT NULL,
    emergency_contact_name TEXT NOT NULL,
    emergency_contact_phone TEXT NOT NULL,
    signature TEXT NOT NULL
);
CREATE INDEX ON liability_waivers (lower(full_name));
CREATE INDEX ON liability_waivers (created_date);


CREATE TABLE guest_signin (
    id SERIAL PRIMARY KEY NOT NULL,
    created_date TIMESTAMP NOT NULL DEFAULT NOW(),
    full_name TEXT NOT NULL,
    member_hosting TEXT,
    heard_from TEXT,
    join_mailing_list BOOLEAN NOT NULL
);
CREATE INDEX ON guest_signin (lower(full_name));
CREATE INDEX ON guest_signin (created_date);
