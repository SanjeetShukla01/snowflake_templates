--Define:
CREATE MASKING POLICY credit_card_masking_policy
AS (val STRING) RETURNS STRING ->
CASE
  WHEN CURRENT_ROLE() = 'ADMIN' THEN val -- Bypass masking for admins
  ELSE 'XXXX-XXXX-XXXX-' || RIGHT(val, 4) -- Partial masking for non-admin users
END;

--Apply:
ALTER TABLE my_table MODIFY COLUMN credit_card_number SET MASKING POLICY credit_card_masking_policy;
