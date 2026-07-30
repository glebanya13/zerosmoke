-- The product design uses 6+, 16+ and 18+. Source document names are legacy.
ALTER TABLE "Test" ALTER COLUMN "audience" DROP DEFAULT;

ALTER TYPE "TestAudience" RENAME TO "TestAudience_old";

CREATE TYPE "TestAudience" AS ENUM ('AGE_6', 'AGE_16', 'AGE_18');

ALTER TABLE "Test"
ALTER COLUMN "audience" TYPE "TestAudience"
USING (
  CASE "audience"::text
    WHEN 'AGE_8' THEN 'AGE_6'
    WHEN 'AGE_16' THEN 'AGE_16'
    ELSE 'AGE_18'
  END
)::"TestAudience";

DROP TYPE "TestAudience_old";

ALTER TABLE "Test" ALTER COLUMN "audience" SET DEFAULT 'AGE_6';
