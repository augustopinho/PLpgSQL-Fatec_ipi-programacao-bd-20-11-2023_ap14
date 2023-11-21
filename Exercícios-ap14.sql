CREATE TABLE IF NOT EXISTS persons_table (
    person_id SERIAL PRIMARY KEY,
    person_name VARCHAR(200) NOT NULL,
    person_age INT NOT NULL,
    person_balance NUMERIC(10, 2) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS audit_table (
    audit_id SERIAL PRIMARY KEY,
    person_id INT NOT NULL,
    person_age INT NOT NULL,
    old_balance NUMERIC(10, 2),
    new_balance NUMERIC(10, 2)
);

CREATE OR REPLACE FUNCTION validate_balance() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.person_balance >= 0 THEN
        RETURN NEW;
    ELSE
        RAISE NOTICE 'Invalid balance value: R$%', NEW.person_balance;
        RETURN NULL;
    END IF;
END;
$$;

CREATE OR REPLACE TRIGGER balance_validator
BEFORE INSERT OR UPDATE ON persons_table
FOR EACH ROW
EXECUTE PROCEDURE validate_balance();

CREATE OR REPLACE FUNCTION log_person_insert() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit_table (person_id, person_age, old_balance, new_balance)
    VALUES (NEW.person_id, NEW.person_age, NULL, NEW.person_balance);
    RETURN NULL;
END;
$$;

CREATE OR REPLACE TRIGGER insert_log_trigger
AFTER INSERT ON persons_table
FOR EACH ROW
EXECUTE PROCEDURE log_person_insert();

CREATE OR REPLACE FUNCTION log_person_update() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO audit_table (person_id, person_age, old_balance, new_balance)
    VALUES (NEW.person_id, NEW.person_age, OLD.person_balance, NEW.person_balance);
    RETURN NEW;
END;
$$;

-- Gatilho para log de atualização de pessoa
CREATE OR REPLACE TRIGGER update_log_trigger
AFTER UPDATE ON persons_table
FOR EACH ROW
EXECUTE PROCEDURE log_person_update();

ALTER TABLE persons_table ADD COLUMN is_active BOOLEAN DEFAULT TRUE;

CREATE OR REPLACE FUNCTION delete_person() RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE persons_table SET is_active = FALSE WHERE person_id = OLD.person_id;
    RETURN NULL;
END;
$$;

CREATE TRIGGER delete_person_trigger
BEFORE DELETE ON persons_table
FOR EACH ROW
EXECUTE PROCEDURE delete_person();