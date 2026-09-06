-- Replace broad audiences with the three age categories used by the content files.
ALTER TABLE "Test" ALTER COLUMN "audience" DROP DEFAULT;

ALTER TYPE "TestAudience" RENAME TO "TestAudience_old";

CREATE TYPE "TestAudience" AS ENUM ('AGE_8', 'AGE_16', 'AGE_18');

ALTER TABLE "Test"
ALTER COLUMN "audience" TYPE "TestAudience"
USING (
  CASE "audience"::text
    WHEN 'CHILD' THEN 'AGE_8'
    WHEN 'ADULT' THEN 'AGE_18'
    ELSE 'AGE_16'
  END
)::"TestAudience";

DROP TYPE "TestAudience_old";

ALTER TABLE "Test" ALTER COLUMN "audience" SET DEFAULT 'AGE_8';
